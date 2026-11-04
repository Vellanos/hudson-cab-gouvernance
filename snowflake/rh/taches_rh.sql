USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- Jour 3, étape 6 : seules ces trois tâches sont créées.
-- Les droits CREATE TASK sur MARTS et EXECUTE TASK sur le compte existent
-- dans 00_installation.sql ; INSERT/SELECT sur QUALITE_RESULTATS dans 01_gouvernance.sql.
-- Exécuter hors transaction manuelle et sans chargement concurrent des sources.
-- Références officielles :
-- https://docs.snowflake.com/en/sql-reference/sql/create-task
-- https://docs.snowflake.com/en/sql-reference/sql/alter-task
-- https://docs.snowflake.com/en/sql-reference/sql/execute-task
-- https://docs.snowflake.com/en/sql-reference/functions/task_history
-- https://docs.snowflake.com/en/sql-reference/functions/system_task_dependents_enable
-- https://docs.snowflake.com/en/sql-reference/transactions

-- ===================================================================== A. Création / actualisation
-- La suspension empêche les prochains départs, sans annuler un lancement en cours.
-- Si le garde-fou échoue, attendre la fin du lancement puis reprendre A depuis le début.
-- Ne pas poursuivre les CREATE après cette erreur.
ALTER TASK IF EXISTS NYC_TAXI.MARTS.T_PURGE SUSPEND;

EXECUTE IMMEDIATE $$
DECLARE
    nb_en_cours INTEGER;
    graphe_actif EXCEPTION (-20002, 'Attendre la fin du graphe RH avant de reprendre la partie A');
BEGIN
    SELECT COUNT(*) INTO :nb_en_cours
    FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TASK_HISTORY())
    WHERE database_name = 'NYC_TAXI' AND schema_name = 'MARTS'
      AND name IN ('T_PURGE', 'T_QUALITE', 'T_TABLES')
      AND state IN ('EXECUTING', 'SCHEDULED')
      AND scheduled_time <= CURRENT_TIMESTAMP();
    IF (nb_en_cours > 0) THEN
        RAISE graphe_actif;
    END IF;
END;
$$;

ALTER TASK IF EXISTS NYC_TAXI.MARTS.T_QUALITE SUSPEND;
ALTER TASK IF EXISTS NYC_TAXI.MARTS.T_TABLES SUSPEND;

-- CREATE OR REPLACE TASK laisse chaque tâche suspendue, y compris au rejeu.
-- Recréer dans l'ordre des dépendances, puis activer seulement via B.
CREATE OR REPLACE TASK NYC_TAXI.MARTS.T_PURGE
    WAREHOUSE = NYC_TAXI_WH
    SCHEDULE = 'USING CRON 0 7 * * * Europe/Paris'
    AUTOCOMMIT = TRUE
AS
EXECUTE IMMEDIATE $$
DECLARE
    date_limite DATE DEFAULT DATEADD(year, -5, CURRENT_DATE());
BEGIN
    BEGIN TRANSACTION;
    DELETE FROM NYC_TAXI.RAW.DRIVER_SHIFTS
    WHERE driver_id IN (
        SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS
        WHERE end_date IS NOT NULL
          AND end_date <= :date_limite
    );
    DELETE FROM NYC_TAXI.RAW.DRIVERS
    WHERE end_date IS NOT NULL
      AND end_date <= :date_limite;
    COMMIT;
EXCEPTION
    WHEN OTHER THEN
        ROLLBACK;
        RAISE;
END;
$$;

CREATE OR REPLACE TASK NYC_TAXI.MARTS.T_QUALITE
    WAREHOUSE = NYC_TAXI_WH
    AUTOCOMMIT = TRUE
    AFTER NYC_TAXI.MARTS.T_PURGE
AS
EXECUTE IMMEDIATE $$
DECLARE
    nb_licences NUMBER;
    nb_telephones NUMBER;
    nb_services NUMBER;
    seuil_telephone NUMBER(18,2);
    seuil_service NUMBER(18,2) DEFAULT 50;
    mesure TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()::TIMESTAMP_NTZ;
    qualite_bloquante EXCEPTION (-20001, 'service_rattache : seuil depasse, reconstruction des MARTS bloquee');
BEGIN
    -- Requêtes des trois fichiers controles/, avec INTO pour recueillir la mesure.
    SELECT COUNT(*) - COUNT(DISTINCT tlc_license_number) INTO :nb_licences
    FROM NYC_TAXI.RAW.DRIVERS;

    SELECT COUNT(*) INTO :nb_telephones
    FROM NYC_TAXI.RAW.DRIVERS
    WHERE end_date IS NULL
      AND (phone IS NULL OR REGEXP_LIKE(phone, '^[[:space:]]*$'));

    SELECT 0.05 * COUNT(*) INTO :seuil_telephone
    FROM NYC_TAXI.RAW.DRIVERS
    WHERE end_date IS NULL;

    SELECT COUNT(*) INTO :nb_services
    FROM NYC_TAXI.RAW.DRIVER_SHIFTS s
    WHERE NOT EXISTS (
        SELECT 1
        FROM NYC_TAXI.RAW.DRIVERS d
        WHERE d.driver_id = s.driver_id
    );

    -- Une transaction explicite valide ensemble les trois mesures AVANT RAISE.
    -- L'exception métier suivante ne peut pas annuler ce COMMIT.
    BEGIN TRANSACTION;
    INSERT INTO NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS
        (regle, mesure_le, nb_anomalies, seuil, statut)
    SELECT 'licence_unique', :mesure, :nb_licences, 0,
           IFF(:nb_licences <= 0, 'OK', 'ALERTE')
    UNION ALL
    SELECT 'telephone_renseigne', :mesure, :nb_telephones, :seuil_telephone,
           IFF(:nb_telephones <= :seuil_telephone, 'OK', 'ALERTE')
    UNION ALL
    SELECT 'service_rattache', :mesure, :nb_services, :seuil_service,
           IFF(:nb_services <= :seuil_service, 'OK', 'ALERTE');
    COMMIT;

    -- Les deux avertissements n'arrêtent jamais la chaîne.
    IF (nb_services > seuil_service) THEN
        RAISE qualite_bloquante;
    END IF;
EXCEPTION
    -- Une erreur SQL est propagée après annulation de la transaction éventuelle.
    -- L'exception métier déclarée ci-dessus n'est pas interceptée ici.
    WHEN STATEMENT_ERROR THEN
        ROLLBACK;
        RAISE;
END;
$$;

CREATE OR REPLACE TASK NYC_TAXI.MARTS.T_TABLES
    WAREHOUSE = NYC_TAXI_WH
    AUTOCOMMIT = TRUE
    AFTER NYC_TAXI.MARTS.T_QUALITE
AS
EXECUTE IMMEDIATE $$
BEGIN
    -- Trois INSERT OVERWRITE repris sans changement des fichiers marts/.
INSERT OVERWRITE INTO NYC_TAXI.MARTS.DIM_DEPOT (depot, quartier, ouvert_en, nb_places) VALUES
    ('Bronx',    'Hunts Point',       2009, 140),
    ('Brooklyn', 'East New York',     2011, 120),
    ('Queens',   'Long Island City',  2008, 180);

INSERT OVERWRITE INTO NYC_TAXI.MARTS.DIM_DRIVER
SELECT
    driver_id,
    first_name,
    last_name,
    email,
    phone,
    birth_date,
    tlc_license_number,
    depot,
    hire_date,
    end_date,
    end_date IS NULL                                                          AS is_active,
    ROUND(DATEDIFF(day, hire_date, COALESCE(end_date, CURRENT_DATE())) / 365.25, 1) AS tenure_years
FROM NYC_TAXI.STAGING.STG_RH__DRIVERS;

INSERT OVERWRITE INTO NYC_TAXI.MARTS.MART_DRIVER_MONTHLY
SELECT
    DATE_TRUNC('month', s.shift_date)::date     AS activity_month,
    s.driver_id,
    d.first_name || ' ' || d.last_name          AS driver_name,
    s.depot,
    COUNT(*)                                    AS nb_shifts,
    ROUND(SUM(s.hours_worked), 1)               AS hours_worked,
    SUM(s.trips_count)                          AS trips_count,
    ROUND(SUM(s.revenue_usd), 2)                AS revenue_usd
FROM NYC_TAXI.STAGING.STG_RH__DRIVER_SHIFTS s
LEFT JOIN NYC_TAXI.MARTS.DIM_DRIVER d ON d.driver_id = s.driver_id
GROUP BY 1, 2, 3, 4;

END;
$$;

-- ===================================================================== B. Activation / lancement MANUELS
-- Sélectionner les commandes commentées de B dans Snowsight après revue de A.
-- L'activation remet aussi en service la planification quotidienne à 7 h.
-- SET rh_test_debut = CURRENT_TIMESTAMP();
-- SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('NYC_TAXI.MARTS.T_PURGE');
-- EXECUTE TASK NYC_TAXI.MARTS.T_PURGE;
-- Attendre la fin du graphe avant C (EXECUTE TASK est asynchrone).

-- ===================================================================== C. Vérifications
-- Après A : trois tâches SUSPENDED et prédécesseurs attendus.
SHOW TASKS LIKE 'T_PURGE' IN SCHEMA NYC_TAXI.MARTS;
SHOW TASKS LIKE 'T_QUALITE' IN SCHEMA NYC_TAXI.MARTS;
SHOW TASKS LIKE 'T_TABLES' IN SCHEMA NYC_TAXI.MARTS;
SHOW GRANTS TO ROLE TRANSFORMER;

-- Après B : pour un même GRAPH_RUN_GROUP_ID et ATTEMPT_NUMBER, attendre
-- trois SUCCEEDED si service_rattache <= 50 ; ALERTE non bloquante admise.
SELECT name, state, graph_run_group_id, attempt_number,
       scheduled_time, completed_time, error_message
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TASK_HISTORY(RESULT_LIMIT => 10000))
WHERE database_name = 'NYC_TAXI' AND schema_name = 'MARTS'
  AND name IN ('T_PURGE', 'T_QUALITE', 'T_TABLES')
  AND state <> 'SCHEDULED'
ORDER BY scheduled_time DESC, name
LIMIT 30;

-- Les trois dernières mesures portent le même mesure_le : les rapprocher
-- du lancement observé. Aucun résultat Snowflake n'est présumé dans ce fichier.
SELECT regle, mesure_le, nb_anomalies, seuil, statut
FROM NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS
WHERE regle IN ('licence_unique', 'telephone_renseigne', 'service_rattache')
ORDER BY mesure_le DESC, regle
LIMIT 3;

-- Après B uniquement, pour isoler les nouvelles mesures depuis le repère de B :
-- SELECT regle, mesure_le, nb_anomalies, seuil, statut
-- FROM NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS
-- WHERE mesure_le >= $rh_test_debut::TIMESTAMP_NTZ
-- ORDER BY mesure_le, regle;

SELECT
    (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DEPOT) AS nb_depots,
    (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER) AS nb_chauffeurs,
    (SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY) AS nb_activites;

-- ------------------------------------------------ Démonstration du blocage, MANUELLE
-- Ne pas exécuter en bloc : attendre chaque lancement avant de modifier les tâches.
-- 1. Suspendre la racine et attendre la fin du graphe (garde-fou de A).
-- ALTER TASK NYC_TAXI.MARTS.T_PURGE SUSPEND;
-- 2. Dans la définition T_QUALITE de A, changer UNIQUEMENT
--    "seuil_service NUMBER(18,2) DEFAULT 50" en "... DEFAULT 20".
--    Réexécuter A entière avec ce seul changement temporaire : les trois
--    tâches et leurs dépendances sont ainsi rétablies, toutes suspendues.
--    Ne lancer aucune commande B avant la fin de A ; aucun changement RAW.
-- 3. Activer et lancer une seule fois :
-- SET rh_test_debut = CURRENT_TIMESTAMP();
-- SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('NYC_TAXI.MARTS.T_PURGE');
-- EXECUTE TASK NYC_TAXI.MARTS.T_PURGE;
-- 4. Attendre, relever avec C le GRAPH_RUN_GROUP_ID du T_PURGE de ce lancement,
--    puis coller cet identifiant dans la variable ci-dessous.
-- SET rh_graphe_test = '<GRAPH_RUN_GROUP_ID relevé>';
-- SELECT name, state, graph_run_group_id, attempt_number, error_message
-- FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TASK_HISTORY(RESULT_LIMIT => 10000))
-- WHERE database_name = 'NYC_TAXI' AND schema_name = 'MARTS'
--   AND name IN ('T_PURGE', 'T_QUALITE', 'T_TABLES')
--   AND state <> 'SCHEDULED'
--   AND graph_run_group_id = $rh_graphe_test
-- ORDER BY scheduled_time, name;
-- Attendu si les 25 anomalies sont toujours présentes : T_PURGE SUCCEEDED,
-- T_QUALITE FAILED ; aucune exécution de T_TABLES pour CE graphe.
-- Le contrôle des nouvelles mesures ci-dessus doit montrer service_rattache
-- ALERTE, seuil 20, malgré l'échec ; ne pas confondre avec un ancien lancement.
--
-- 5. RESTAURATION OBLIGATOIRE avant toute autre activation :
-- ALTER TASK NYC_TAXI.MARTS.T_PURGE SUSPEND;
--    Attendre la fin du graphe, remettre DEFAULT 50 dans la définition de A,
--    puis réexécuter A entière. Les trois tâches restent alors suspendues.
--    Vérifier ci-dessous que la définition contient bien DEFAULT 50.
-- SELECT GET_DDL('TASK', 'NYC_TAXI.MARTS.T_QUALITE');
--    Reprendre B pour tester à nouveau le seuil contractuel, ou laisser suspendu.
--    Ne pas enregistrer / versionner la modification temporaire à 20.

-- ===================================================================== D. Fin des tests, suspension MANUELLE
-- Suspendre la racine évite les départs quotidiens et leur consommation.
-- Un lancement déjà en cours termine normalement : attendre sa fin.
-- ALTER TASK NYC_TAXI.MARTS.T_PURGE SUSPEND;
