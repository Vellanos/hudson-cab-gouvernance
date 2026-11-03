USE SECONDARY ROLES NONE;
USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;

-- Jour 2, étape 6 uniquement. Partie A à exécuter puis rejouer dans Snowsight.
-- Préparé et vérifié localement ; aucune exécution Snowflake par cette intervention.
-- Prérequis : 01/02 exécutés, masquage 03 en place et tables MARTS existantes.
-- GOUVERNANCE reste propriétaire des règles, sans SELECT sur les données RH.
-- Références officielles :
-- https://docs.snowflake.com/en/sql-reference/sql/create-row-access-policy
-- https://docs.snowflake.com/en/sql-reference/sql/alter-row-access-policy
-- https://docs.snowflake.com/en/sql-reference/sql/alter-table
-- https://docs.snowflake.com/en/sql-reference/functions/policy_references

-- ===================================================================== A. Correspondances, politique et attachements
CREATE TABLE IF NOT EXISTS NYC_TAXI.GOUVERNANCE.ACCES_DEPOT (
    role_name VARCHAR,
    depot     VARCHAR
);

-- Remplacer uniquement les correspondances par les cinq lignes du contrat.
-- INSERT OVERWRITE préserve la table et ses droits, sans accumuler de doublons.
-- * couvre tous les dépôts, y compris une valeur absente ou un futur dépôt.
INSERT OVERWRITE INTO NYC_TAXI.GOUVERNANCE.ACCES_DEPOT (role_name, depot) VALUES
    ('TRANSFORMER', '*'),
    ('RH_PAIE', '*'),
    ('ANALYSTE', '*'),
    ('RESP_DEPOT_QUEENS', 'Queens'),
    ('RESP_DEPOT_BRONX', 'Bronx');

-- La politique lit ACCES_DEPOT avec les droits de son propriétaire GOUVERNANCE.
-- Aucun SELECT sur cette table n'est nécessaire ni accordé aux rôles métier.
CREATE ROW ACCESS POLICY IF NOT EXISTS NYC_TAXI.GOUVERNANCE.RAP_DEPOT
  AS (depot_ligne VARCHAR) RETURNS BOOLEAN -> FALSE;

ALTER ROW ACCESS POLICY NYC_TAXI.GOUVERNANCE.RAP_DEPOT SET BODY ->
  EXISTS (
    SELECT 1
    FROM NYC_TAXI.GOUVERNANCE.ACCES_DEPOT a
    WHERE a.role_name = CURRENT_ROLE()
      AND a.depot IN (depot_ligne, '*')
  );

-- TRANSFORMER conserve toutes les lignes pour reconstruire les noms originaux.
-- Un rôle absent de la table est refusé, sans exception d'administration
-- ni héritage implicite : ACCOUNTADMIN, SYSADMIN et GOUVERNANCE sont absents.
--
-- Attachements contrôlés : ne rien retirer, ni remplacer une autre politique.
-- Si la politique attendue est déjà liée à la seule colonne DEPOT, ne rien ajouter.
-- Sinon, lever une erreur explicite. Les erreurs SQL ne sont pas interceptées.

EXECUTE IMMEDIATE $$
DECLARE
  nb_politiques INTEGER;
  nb_attendues INTEGER;
  conflit EXCEPTION (-20001, 'Conflit de politique ou de colonne sur DIM_DRIVER : verifier POLICY_REFERENCES avant intervention.');
BEGIN
  SELECT COUNT(*),
         COUNT(CASE WHEN policy_db = 'NYC_TAXI'
                     AND policy_schema = 'GOUVERNANCE'
                     AND policy_name = 'RAP_DEPOT'
                     AND REGEXP_REPLACE(UPPER(ref_arg_column_names), '[^A-Z0-9_]', '') = 'DEPOT'
                    THEN 1 END)
    INTO :nb_politiques, :nb_attendues
  FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
    REF_ENTITY_NAME => 'NYC_TAXI.MARTS.DIM_DRIVER', REF_ENTITY_DOMAIN => 'TABLE'))
  WHERE policy_kind = 'ROW_ACCESS_POLICY';

  IF (nb_politiques = 0) THEN
    ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER
      ADD ROW ACCESS POLICY NYC_TAXI.GOUVERNANCE.RAP_DEPOT ON (depot);
  ELSEIF (nb_politiques <> 1 OR nb_attendues <> 1) THEN
    RAISE conflit;
  END IF;
END;
$$;

EXECUTE IMMEDIATE $$
DECLARE
  nb_politiques INTEGER;
  nb_attendues INTEGER;
  conflit EXCEPTION (-20001, 'Conflit de politique ou de colonne sur MART_DRIVER_MONTHLY : verifier POLICY_REFERENCES avant intervention.');
BEGIN
  SELECT COUNT(*),
         COUNT(CASE WHEN policy_db = 'NYC_TAXI'
                     AND policy_schema = 'GOUVERNANCE'
                     AND policy_name = 'RAP_DEPOT'
                     AND REGEXP_REPLACE(UPPER(ref_arg_column_names), '[^A-Z0-9_]', '') = 'DEPOT'
                    THEN 1 END)
    INTO :nb_politiques, :nb_attendues
  FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
    REF_ENTITY_NAME => 'NYC_TAXI.MARTS.MART_DRIVER_MONTHLY', REF_ENTITY_DOMAIN => 'TABLE'))
  WHERE policy_kind = 'ROW_ACCESS_POLICY';

  IF (nb_politiques = 0) THEN
    ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY
      ADD ROW ACCESS POLICY NYC_TAXI.GOUVERNANCE.RAP_DEPOT ON (depot);
  ELSEIF (nb_politiques <> 1 OR nb_attendues <> 1) THEN
    RAISE conflit;
  END IF;
END;
$$;

-- DIM_DEPOT n'est pas filtrée ; RAW, STAGING et le masquage restent inchangés.
-- Chaque table utilise son propre depot, sans jointure avec le dépôt du chauffeur.

-- Vérifier : exactement les cinq correspondances ci-dessus, sans doublon.
SELECT role_name, depot
FROM NYC_TAXI.GOUVERNANCE.ACCES_DEPOT
ORDER BY role_name;
SELECT COUNT(*) AS nb_correspondances,
       COUNT(DISTINCT role_name) AS nb_roles
FROM NYC_TAXI.GOUVERNANCE.ACCES_DEPOT;
-- Attendu : 5 et 5.

SHOW ROW ACCESS POLICIES IN SCHEMA NYC_TAXI.GOUVERNANCE;
DESCRIBE ROW ACCESS POLICY NYC_TAXI.GOUVERNANCE.RAP_DEPOT;

-- Vérifier RAP_DEPOT, sa colonne d'argument DEPOT et son statut ACTIVE sur chaque table.
SELECT policy_name, policy_kind, ref_entity_name, ref_arg_column_names, policy_status
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
  REF_ENTITY_NAME => 'NYC_TAXI.MARTS.DIM_DRIVER', REF_ENTITY_DOMAIN => 'TABLE'))
WHERE policy_kind = 'ROW_ACCESS_POLICY';

SELECT policy_name, policy_kind, ref_entity_name, ref_arg_column_names, policy_status
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
  REF_ENTITY_NAME => 'NYC_TAXI.MARTS.MART_DRIVER_MONTHLY', REF_ENTITY_DOMAIN => 'TABLE'))
WHERE policy_kind = 'ROW_ACCESS_POLICY';

-- ===================================================================== B. Tests manuels séparés, à exécuter plus tard
-- Tout ce qui suit est commenté : copier un bloc à la fois dans Snowsight.
-- Les contrôles complets de valeurs et de reconstruction relèvent des étapes 7/8.
-- Aucun résultat n'est déclaré obtenu ; ne pas publier les valeurs personnelles lues.
--
-- RH_PAIE : 400 chauffeurs avant purge et tous les dépôts.
-- USE SECONDARY ROLES NONE;
-- USE ROLE RH_PAIE;
-- USE WAREHOUSE NYC_TAXI_WH;
-- SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;
-- SELECT depot, COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY GROUP BY depot;
--
-- ANALYSTE : 400 chauffeurs, avec le masquage existant.
-- USE SECONDARY ROLES NONE;
-- USE ROLE ANALYSTE;
-- USE WAREHOUSE NYC_TAXI_WH;
-- SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;
-- SELECT driver_id, first_name, email, phone, birth_date
-- FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE driver_id = 'D0003';
--
-- RESP_DEPOT_QUEENS : Queens seulement dans CHACUNE des deux tables.
-- Effectifs à constater dans Snowflake ; aucun nombre par dépôt n'est présumé.
-- USE SECONDARY ROLES NONE;
-- USE ROLE RESP_DEPOT_QUEENS;
-- USE WAREHOUSE NYC_TAXI_WH;
-- SELECT depot, COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER GROUP BY depot;
-- SELECT depot, COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY GROUP BY depot;
--
-- RESP_DEPOT_BRONX : Bronx seulement dans CHACUNE des deux tables.
-- USE SECONDARY ROLES NONE;
-- USE ROLE RESP_DEPOT_BRONX;
-- USE WAREHOUSE NYC_TAXI_WH;
-- SELECT depot, COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER GROUP BY depot;
-- SELECT depot, COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY GROUP BY depot;
--
-- TRANSFORMER : toutes les lignes et valeurs originales, pas des masques matérialisés.
-- Comparer les noms/coordonnées autorisés dans Snowsight, sans les recopier dans Git.
-- USE SECONDARY ROLES NONE;
-- USE ROLE TRANSFORMER;
-- USE WAREHOUSE NYC_TAXI_WH;
-- SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;
-- SELECT depot, COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY GROUP BY depot;
-- SELECT driver_id, first_name, last_name, email
-- FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE driver_id = 'D0003';
-- SELECT driver_id, driver_name
-- FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY WHERE driver_id = 'D0003';
--
-- ACCOUNTADMIN : zéro ligne dans les deux tables, ou accès refusé selon ses droits.
-- USE SECONDARY ROLES NONE;
-- USE ROLE ACCOUNTADMIN;
-- USE WAREHOUSE NYC_TAXI_WH;
-- SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;
-- SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY;
--
-- GOUVERNANCE : lecture RH refusée, car aucun SELECT n'est accordé.
-- USE SECONDARY ROLES NONE;
-- USE ROLE GOUVERNANCE;
-- USE WAREHOUSE NYC_TAXI_WH;
-- SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;
-- SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY;
--
-- DIM_DEPOT : refaire ce bloc avec CHACUN des quatre rôles métier, attendu 3 lignes.
-- USE SECONDARY ROLES NONE;
-- USE ROLE RH_PAIE;
-- USE WAREHOUSE NYC_TAXI_WH;
-- SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DEPOT;
--
-- Limites conservées : C20 partiel pour les colonnes non catégorisées ;
-- ambiguïté ACCOUNTADMIN/RAW inchangée. Ce filtre ne concerne que les deux tables MARTS.
