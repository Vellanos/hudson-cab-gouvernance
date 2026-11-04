USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- Jour 3, étape 1 : préparer et appliquer R1 uniquement dans les deux tables RAW.
-- A s'exécute seule. B reste commentée : l'examiner avant de la lancer séparément.
-- Utiliser la même session Snowsight, sans transaction déjà ouverte et sans
-- chargement ou modification concurrente des sources pendant les contrôles et la purge.
-- Vérification locale uniquement ; aucune requête exécutée sur Snowflake ici.
-- Références :
-- https://docs.snowflake.com/en/sql-reference/sql/delete
-- https://docs.snowflake.com/en/sql-reference/transactions
-- https://docs.snowflake.com/en/developer-guide/snowflake-scripting/query-id
-- https://docs.snowflake.com/en/developer-guide/snowflake-scripting/exceptions

-- ===================================================================== A. Vérifications AVANT purge
-- B réutilise exactement cette date limite, calculée depuis CURRENT_DATE().
-- Un end_date égal à la limite est inclus ; NULL est toujours exclu.
SET rh_purge_date_limite = DATEADD(year, -5, CURRENT_DATE());
SET rh_purge_avant = CURRENT_TIMESTAMP();

SELECT CURRENT_DATE() AS date_du_controle,
       $rh_purge_date_limite AS date_limite_incluse,
       $rh_purge_avant AS repere_avant_purge;

SELECT
    (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS) AS chauffeurs_avant,
    (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS) AS services_avant,
    (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS
     WHERE end_date IS NOT NULL
       AND end_date <= $rh_purge_date_limite) AS chauffeurs_eligibles,
    (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS
     WHERE driver_id IN (
         SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS
         WHERE end_date IS NOT NULL
           AND end_date <= $rh_purge_date_limite
     )) AS services_associes_eligibles;

-- Examiner ces résultats et les conserver dans Snowsight avant de passer à B.
-- Le repère horodaté et les query_id retournés par B permettront de retrouver
-- l'état antérieur lors du futur test Time Travel, sous réserve de la rétention existante.
-- Conserver les identifiants du PREMIER passage avant de tester la réexécution.
-- Aucun test Time Travel ni changement de rétention n'est réalisé dans ce fichier.
-- Si la date ou les données ont changé entre A et B, relancer A et réexaminer ses résultats.

-- ===================================================================== B. Purge effective, À EXÉCUTER SÉPARÉMENT
-- Après examen de A, sélectionner uniquement le contenu entre les marqueurs
-- /* et */ dans la MÊME feuille, ou retirer ces deux marqueurs avant exécution.
-- Conserver la session où les variables de A ont été définies.

/*
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

EXECUTE IMMEDIATE $$
DECLARE
    date_limite DATE DEFAULT $rh_purge_date_limite;
    id_delete_services VARCHAR;
    id_delete_chauffeurs VARCHAR;
    nb_services_supprimes NUMBER;
    nb_chauffeurs_supprimes NUMBER;
BEGIN
    BEGIN TRANSACTION;

    -- Les parents existent encore : supprimer d'abord leurs services.
    -- Les services déjà orphelins ne satisfont pas cette sous-requête et restent présents.
    DELETE FROM NYC_TAXI.RAW.DRIVER_SHIFTS
    WHERE driver_id IN (
        SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS
        WHERE end_date IS NOT NULL
          AND end_date <= :date_limite
    );
    id_delete_services := SQLID;
    nb_services_supprimes := SQLROWCOUNT;

    DELETE FROM NYC_TAXI.RAW.DRIVERS
    WHERE end_date IS NOT NULL
      AND end_date <= :date_limite;
    id_delete_chauffeurs := SQLID;
    nb_chauffeurs_supprimes := SQLROWCOUNT;

    COMMIT;

    -- SQLID est capturé juste après chaque DELETE, avant COMMIT et les autres requêtes.
    -- Ce résultat ne crée aucun objet : conserver ces métadonnées dans Snowsight.
    RETURN OBJECT_CONSTRUCT(
        'date_limite_incluse', date_limite,
        'delete_services_query_id', id_delete_services,
        'delete_chauffeurs_query_id', id_delete_chauffeurs,
        'services_supprimes', nb_services_supprimes,
        'chauffeurs_supprimes', nb_chauffeurs_supprimes
    );
EXCEPTION
    WHEN OTHER THEN
        ROLLBACK;
        RAISE;
END;
$$;

-- Contrôles APRÈS succès du bloc : comparer aux volumes et suppressions de A/B.
SELECT
    (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS) AS chauffeurs_apres,
    (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS) AS services_apres,
    (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS
     WHERE end_date IS NOT NULL
       AND end_date <= $rh_purge_date_limite) AS chauffeurs_eligibles_restants;
-- Attendu pour chauffeurs_eligibles_restants : 0.
-- À données et date limite inchangées, rejouer B doit retourner 0 et 0 suppressions.
*/

-- Ne pas reconstruire MARTS dans ce fichier : leurs copies doivent être retirées
-- par la reconstruction manuelle prévue après la purge RAW.
-- Les services orphelins relèvent du futur contrôle service_rattache, pas d'une suppression ici.
