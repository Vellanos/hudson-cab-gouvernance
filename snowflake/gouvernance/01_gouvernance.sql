-- Jour 1, étape 10 — initialiser les objets et les droits de gouvernance.
-- Prérequis : snowflake/00_installation.sql exécuté ; lancer ce fichier en entier.
-- Rejouable : IF NOT EXISTS conserve les objets ; COPY CURRENT GRANTS conserve les droits.
-- Un objet préexistant avec une définition différente n'est pas corrigé automatiquement.
-- Préparé et vérifié statiquement ; exécution et seconde exécution à faire dans Snowsight.
-- Références : GUIDE_BRIEF_GOUVERNANCE.md, CONTRAT_GOUVERNANCE.md, exemples/00 et 01.
-- Syntaxe : https://docs.snowflake.com/en/sql-reference/sql/create-tag
--          https://docs.snowflake.com/en/sql-reference/sql/grant-ownership
--          https://docs.snowflake.com/en/sql-reference/sql/grant-privilege

USE SECONDARY ROLES NONE;

-- 1. ACCOUNTADMIN : le rôle des règles, sans héritage du rôle des données.
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE NYC_TAXI_WH;
SET moi = CURRENT_USER();

CREATE ROLE IF NOT EXISTS GOUVERNANCE
  COMMENT = 'Propriétaire des règles de gouvernance ; ne lit pas les données RH';
GRANT ROLE GOUVERNANCE TO USER IDENTIFIER($moi);

GRANT USAGE ON DATABASE NYC_TAXI TO ROLE GOUVERNANCE;
GRANT USAGE ON WAREHOUSE NYC_TAXI_WH TO ROLE GOUVERNANCE;
GRANT USAGE ON SCHEMA NYC_TAXI.RAW TO ROLE GOUVERNANCE;
GRANT USAGE ON SCHEMA NYC_TAXI.MARTS TO ROLE GOUVERNANCE;
-- Aucun SELECT ni transfert de propriété sur les tables RAW ou MARTS.

CREATE SCHEMA IF NOT EXISTS NYC_TAXI.GOUVERNANCE
  COMMENT = 'Tags et objets de gouvernance';
GRANT OWNERSHIP ON SCHEMA NYC_TAXI.GOUVERNANCE
  TO ROLE GOUVERNANCE COPY CURRENT GRANTS;

GRANT APPLY MASKING POLICY ON ACCOUNT TO ROLE GOUVERNANCE;
GRANT APPLY ROW ACCESS POLICY ON ACCOUNT TO ROLE GOUVERNANCE;

-- 2. GOUVERNANCE : propriétaire des objets créés dans son schéma.
USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;

CREATE TAG IF NOT EXISTS NYC_TAXI.GOUVERNANCE.SENSIBILITE
  ALLOWED_VALUES 'public', 'interne', 'confidentiel'
  COMMENT = 'Niveau de sensibilité de la table';

CREATE TAG IF NOT EXISTS NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE
  ALLOWED_VALUES 'nom', 'email', 'telephone', 'date_naissance',
                 'identifiant_officiel', 'identifiant_interne'
  COMMENT = 'Nature de la donnée personnelle de la colonne';

-- Le contrat prévoit un texte libre : aucune liste ALLOWED_VALUES pour ce tag.
CREATE TAG IF NOT EXISTS NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION
  COMMENT = 'Durée de conservation de la table, en texte libre';

CREATE TABLE IF NOT EXISTS NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS (
    regle          VARCHAR,
    mesure_le      TIMESTAMP_NTZ,
    nb_anomalies   NUMBER(38,0),
    seuil          NUMBER(18,2),
    statut         VARCHAR COMMENT 'Valeurs prévues au contrat : OK ou ALERTE'
);

-- 3. GOUVERNANCE accorde à TRANSFORMER uniquement les droits de l'étape 10.
GRANT USAGE ON SCHEMA NYC_TAXI.GOUVERNANCE TO ROLE TRANSFORMER;
GRANT APPLY ON TAG NYC_TAXI.GOUVERNANCE.SENSIBILITE TO ROLE TRANSFORMER;
GRANT APPLY ON TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE TO ROLE TRANSFORMER;
GRANT APPLY ON TAG NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION TO ROLE TRANSFORMER;
GRANT INSERT, SELECT ON TABLE NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS TO ROLE TRANSFORMER;
GRANT CREATE VIEW ON SCHEMA NYC_TAXI.GOUVERNANCE TO ROLE TRANSFORMER;

-- 4. Vérifications manuelles, à lire après chacune des deux exécutions.
-- Attendu : trois tags, leurs valeurs autorisées exactes et GOUVERNANCE propriétaire.
SHOW TAGS IN SCHEMA NYC_TAXI.GOUVERNANCE;
SHOW TABLES LIKE 'QUALITE_RESULTATS' IN SCHEMA NYC_TAXI.GOUVERNANCE;
-- Attendu : les cinq colonnes ci-dessus, dont SEUIL avec deux décimales.
DESCRIBE TABLE NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS;

-- ACCOUNTADMIN permet de consulter la carte complète des droits.
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE NYC_TAXI_WH;
SHOW GRANTS ON SCHEMA NYC_TAXI.GOUVERNANCE;
SHOW GRANTS ON TABLE NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS;
SHOW GRANTS OF ROLE GOUVERNANCE;
-- Attendu : USAGE, propriété du schéma, les deux APPLY au niveau du compte ;
-- aucun SELECT sur RAW/MARTS et aucun héritage de TRANSFORMER.
SHOW GRANTS TO ROLE GOUVERNANCE;
-- Attendu, en plus des droits de l'installation : USAGE et CREATE VIEW sur
-- GOUVERNANCE, APPLY sur ses trois tags, INSERT et SELECT sur QUALITE_RESULTATS.
SHOW GRANTS TO ROLE TRANSFORMER;
