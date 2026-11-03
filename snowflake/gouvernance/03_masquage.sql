USE SECONDARY ROLES NONE;
USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;

-- Jour 2, étape 5 uniquement. Exécuter la partie A, puis la rejouer dans Snowsight.
-- Prérequis : 01_gouvernance.sql et catalogue exécutés ; tags et droits existants.
-- GOUVERNANCE possède les règles et dispose de APPLY MASKING POLICY sur le compte ;
-- aucun SELECT sur RAW/MARTS n'est ajouté.
-- SQL préparé et vérifié statiquement, non exécuté dans Snowflake par cette intervention.
-- Les masques modifient les résultats de lecture, pas les données stockées.
--
-- Références officielles :
-- https://docs.snowflake.com/en/sql-reference/sql/create-masking-policy
-- https://docs.snowflake.com/en/sql-reference/sql/alter-masking-policy
-- https://docs.snowflake.com/en/sql-reference/sql/alter-tag
-- https://docs.snowflake.com/en/sql-reference/functions/system_get_tag_on_current_column
-- https://docs.snowflake.com/en/sql-reference/functions/policy_references

-- ===================================================================== A. Créer, actualiser, attacher et vérifier
-- Initialisation restrictive : aucune valeur non NULL en clair avant SET BODY.
CREATE MASKING POLICY IF NOT EXISTS NYC_TAXI.GOUVERNANCE.MASK_TEXTE
  AS (val STRING) RETURNS STRING ->
    CASE WHEN val IS NULL THEN NULL::STRING ELSE '*****' END;

ALTER MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE SET BODY ->
  CASE
    WHEN val IS NULL THEN NULL::STRING
    WHEN CURRENT_ROLE() IN ('TRANSFORMER', 'RH_PAIE') THEN val
    -- L'exception concerne seulement les rôles métier autorisés.
    -- Elle couvre aussi shift_id, tagué identifiant_interne dans RAW,
    -- sans accorder d'accès à cette table ni exposer cet identifiant aux autres rôles.
    WHEN CURRENT_ROLE() IN ('RH_PAIE', 'RESP_DEPOT_QUEENS', 'RESP_DEPOT_BRONX', 'ANALYSTE')
         AND SYSTEM$GET_TAG_ON_CURRENT_COLUMN('NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE')
             = 'identifiant_interne'
      THEN val
    WHEN CURRENT_ROLE() IN ('RESP_DEPOT_QUEENS', 'RESP_DEPOT_BRONX')
         AND SYSTEM$GET_TAG_ON_CURRENT_COLUMN('NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE')
             IN ('nom', 'telephone')
      THEN val
    -- Cela masque aussi driver_name, catégorisé nom, pour ANALYSTE.
    -- Aucune exception pour ACCOUNTADMIN, SYSADMIN, GOUVERNANCE ou un rôle inconnu.
    ELSE '*****'
  END;

CREATE MASKING POLICY IF NOT EXISTS NYC_TAXI.GOUVERNANCE.MASK_DATE
  AS (val DATE) RETURNS DATE -> NULL::DATE;

ALTER MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DATE SET BODY ->
  CASE
    WHEN val IS NULL THEN NULL::DATE
    WHEN CURRENT_ROLE() IN ('TRANSFORMER', 'RH_PAIE') THEN val
    WHEN CURRENT_ROLE() = 'ANALYSTE'
         AND SYSTEM$GET_TAG_ON_CURRENT_COLUMN('NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE')
             = 'date_naissance'
      THEN DATE_FROM_PARTS(YEAR(val), 1, 1)
    ELSE NULL::DATE
  END;

-- Une politique par type sur le même tag. FORCE évite un détachement préalable
-- et remplace l'affectation de même type lors de la réexécution.
-- Aucun EXCEPTION WHEN STATEMENT_ERROR : toute erreur réelle reste une erreur.
ALTER TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE SET
  MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE FORCE;
ALTER TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE SET
  MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DATE FORCE;

-- L'attachement au tag s'applique aux colonnes déjà taguées dans RAW et MARTS,
-- dont driver_name. Ne pas retaguer les colonnes et ne pas modifier les pipelines.
-- Limite C20 inchangée : les colonnes sans catégorie adaptée restent non couvertes.
-- Pas de filtrage Queens/Bronx ici : sans l'étape 6, les lignes ne sont pas restreintes.
-- L'ambiguïté de visibilité des lignes RAW pour l'administrateur n'est pas tranchée ici ;
-- s'il peut lire les colonnes taguées, leurs valeurs sont masquées selon les règles ci-dessus.

-- 1. Existence et signatures : MASK_TEXTE STRING -> STRING et MASK_DATE DATE -> DATE.
SHOW MASKING POLICIES IN SCHEMA NYC_TAXI.GOUVERNANCE;
DESCRIBE MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE;
DESCRIBE MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DATE;

-- 2. Attachement au tag : les deux politiques doivent être référencées.
SELECT policy_name, policy_kind, ref_entity_name, ref_entity_domain
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
  REF_ENTITY_NAME => 'NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE',
  REF_ENTITY_DOMAIN => 'TAG'))
ORDER BY policy_name;

-- 3. Références effectives : vérifier le tag, le nom de politique et POLICY_STATUS=ACTIVE.
-- Attendu dans DIM_DRIVER : 7 colonnes protégées, dont birth_date par MASK_DATE.
SELECT policy_name, ref_column_name, tag_name, policy_status
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
  REF_ENTITY_NAME => 'NYC_TAXI.MARTS.DIM_DRIVER', REF_ENTITY_DOMAIN => 'TABLE'))
ORDER BY ref_column_name;

-- Attendu dans le mart mensuel : driver_id et driver_name par MASK_TEXTE.
SELECT policy_name, ref_column_name, tag_name, policy_status
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
  REF_ENTITY_NAME => 'NYC_TAXI.MARTS.MART_DRIVER_MONTHLY', REF_ENTITY_DOMAIN => 'TABLE'))
ORDER BY ref_column_name;

-- ===================================================================== B. Tests manuels séparés, à exécuter plus tard
-- Les requêtes ci-dessous sont COMMENTÉES pour que Run All ne déroule pas les tests.
-- Copier un seul bloc à la fois dans une feuille Snowsight, après succès de A.
-- Aucun résultat n'est déclaré obtenu ; ne pas recopier les valeurs lues dans Git.
-- À ce stade, les responsables peuvent encore voir plusieurs dépôts : le filtrage
-- n'existera qu'après 04_acces_depot.sql. Le cahier de tests complet n'est pas validé.
--
-- Test 1 : TRANSFORMER doit lire les valeurs originales.
-- Comparer RAW et DIM_DRIVER dans Snowsight, en tenant compte du nettoyage de l'e-mail.
-- USE SECONDARY ROLES NONE;
-- USE ROLE TRANSFORMER;
-- USE WAREHOUSE NYC_TAXI_WH;
-- SELECT driver_id, first_name, email, birth_date
-- FROM NYC_TAXI.RAW.DRIVERS WHERE driver_id = 'D0003';
-- SELECT driver_id, first_name, email, birth_date
-- FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE driver_id = 'D0003';
--
-- Test 2 : RH_PAIE voit les valeurs originales dans MARTS, sans accès RAW ajouté.
-- USE SECONDARY ROLES NONE;
-- USE ROLE RH_PAIE;
-- USE WAREHOUSE NYC_TAXI_WH;
-- SELECT driver_id, first_name, last_name, email, phone, birth_date, tlc_license_number
-- FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE driver_id = 'D0003';
--
-- Test 3 : RESP_DEPOT_QUEENS voit noms/téléphone, e-mail/licence = *****,
-- birth_date = NULL ; NULL source reste NULL. Aucune assertion de dépôt à ce stade.
-- Le même bloc est à refaire avec RESP_DEPOT_BRONX.
-- USE SECONDARY ROLES NONE;
-- USE ROLE RESP_DEPOT_QUEENS;
-- USE WAREHOUSE NYC_TAXI_WH;
-- SELECT driver_id, first_name, last_name, phone, email, tlc_license_number, birth_date
-- FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE driver_id = 'D0003';
--
-- Test 4 : ANALYSTE voit driver_id, les autres textes tagués = *****,
-- birth_date au 1er janvier de l'année source ; NULL source reste NULL.
-- Vérifier aussi driver_name dans le mart, même si les noms sources sont masqués.
-- USE SECONDARY ROLES NONE;
-- USE ROLE ANALYSTE;
-- USE WAREHOUSE NYC_TAXI_WH;
-- SELECT driver_id, first_name, last_name, phone, email, tlc_license_number, birth_date
-- FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE driver_id = 'D0003';
-- SELECT driver_id, driver_name
-- FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY WHERE driver_id = 'D0003';
--
-- Test 5 : ACCOUNTADMIN n'a pas d'exception : textes tagués = ***** et date = NULL,
-- y compris driver_id et shift_id. Ne pas filtrer par leur valeur originale : masqués,
-- ils ne correspondraient plus à cette valeur dans la condition WHERE.
-- Ce contrôle ne porte pas sur les colonnes personnelles sans catégorie adaptée.
-- USE SECONDARY ROLES NONE;
-- USE ROLE ACCOUNTADMIN;
-- USE WAREHOUSE NYC_TAXI_WH;
-- SELECT driver_id, first_name, email, phone, birth_date, tlc_license_number
-- FROM NYC_TAXI.MARTS.DIM_DRIVER LIMIT 3;
-- SELECT driver_id, driver_name FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY LIMIT 3;
-- SELECT driver_id, first_name, email, birth_date FROM NYC_TAXI.RAW.DRIVERS LIMIT 3;
-- SELECT shift_id, driver_id FROM NYC_TAXI.RAW.DRIVER_SHIFTS LIMIT 3;
-- Un refus d'accès dépend des droits réels ; aucun droit supplémentaire n'est ajouté.
-- L'absence complète de lignes RH prévue par la matrice sera évaluée avec le futur
-- filtrage MARTS ; l'ambiguïté RAW reste documentée dans ACCES.md et le README.
