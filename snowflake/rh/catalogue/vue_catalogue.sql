USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- Jour 3, étape 5 uniquement : métadonnées des trois tables MARTS, jamais leurs valeurs.
-- Prérequis : catalogue exécuté et droits du jour 1 / script 02 en place.
-- TRANSFORMER possède CREATE VIEW sur GOUVERNANCE et les tables MARTS.
-- Rejouable sans COPY GRANTS : à la première création comme au remplacement,
-- les SELECT sur les futures vues de GOUVERNANCE sont appliqués aux quatre métiers.
-- COPY GRANTS préserverait les grants d'une vue remplacée mais n'hériterait pas
-- des grants futurs ; il n'est donc pas retenu ici.
-- Aucun GRANT sur RAW/STAGING ni aucun SELECT RH pour GOUVERNANCE n'est ajouté.
-- Script préparé et contrôlé localement, sans exécution Snowflake.
-- Références officielles :
-- https://docs.snowflake.com/en/sql-reference/sql/create-view
-- https://docs.snowflake.com/en/sql-reference/info-schema/columns
-- https://docs.snowflake.com/en/sql-reference/functions/tag_references_all_columns

CREATE OR REPLACE VIEW NYC_TAXI.GOUVERNANCE.V_CATALOGUE AS
WITH tags AS (
    SELECT object_schema, object_name, column_name,
           tag_database, tag_schema, tag_name, tag_value
    FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS(
        'NYC_TAXI.MARTS.DIM_DRIVER', 'TABLE'))

    UNION ALL

    SELECT object_schema, object_name, column_name,
           tag_database, tag_schema, tag_name, tag_value
    FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS(
        'NYC_TAXI.MARTS.MART_DRIVER_MONTHLY', 'TABLE'))

    UNION ALL

    SELECT object_schema, object_name, column_name,
           tag_database, tag_schema, tag_name, tag_value
    FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS(
        'NYC_TAXI.MARTS.DIM_DEPOT', 'TABLE'))
)
SELECT
    c.table_schema AS SCHEMA_NOM,
    c.table_name AS TABLE_NOM,
    c.column_name AS COLONNE,
    c.data_type AS TYPE_DONNEE,
    c.comment AS DESCRIPTION,
    MAX(CASE WHEN g.tag_name = 'SENSIBILITE' THEN g.tag_value END) AS SENSIBILITE,
    MAX(CASE WHEN g.tag_name = 'DONNEE_PERSONNELLE' THEN g.tag_value END) AS DONNEE_PERSONNELLE,
    MAX(CASE WHEN g.tag_name = 'DUREE_CONSERVATION' THEN g.tag_value END) AS DUREE_CONSERVATION
FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN tags g
  ON g.object_schema = c.table_schema
 AND g.object_name = c.table_name
 AND g.column_name = c.column_name
 AND g.tag_database = 'NYC_TAXI'
 AND g.tag_schema = 'GOUVERNANCE'
WHERE c.table_schema = 'MARTS'
  AND c.table_name IN ('DIM_DRIVER', 'MART_DRIVER_MONTHLY', 'DIM_DEPOT')
GROUP BY 1, 2, 3, 4, 5;

-- La fonction inclut les tags hérités des tables. LEFT JOIN préserve toute colonne
-- sans tag ; MAX rassemble les trois tags sur une seule ligne, sans classification ajoutée.
-- DESCRIPTION reste le commentaire de colonne réel, éventuellement NULL :
-- le mart mensuel a une fiche courte, sans descriptions individuelles imposées.

-- Vérifications avec TRANSFORMER : attendus à confirmer dans Snowsight.
SELECT COUNT(*) AS nb_colonnes
FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE;
-- Attendu : 24.

SELECT SCHEMA_NOM, TABLE_NOM, COUNT(*) AS nb_colonnes,
       COUNT(DESCRIPTION) AS nb_descriptions,
       COUNT(SENSIBILITE) AS nb_sensibilites,
       COUNT(DUREE_CONSERVATION) AS nb_durees
FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE
GROUP BY SCHEMA_NOM, TABLE_NOM
ORDER BY TABLE_NOM;
-- Attendu : DIM_DRIVER=12, MART_DRIVER_MONTHLY=8, DIM_DEPOT=4.
-- Les fiches complètes prévoient 12 descriptions DIM_DRIVER et 4 DIM_DEPOT ;
-- les descriptions manquantes du mart mensuel ne sont pas inventées.

SELECT SCHEMA_NOM, TABLE_NOM, COLONNE, COUNT(*) AS nb_lignes
FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE
GROUP BY SCHEMA_NOM, TABLE_NOM, COLONNE
HAVING COUNT(*) > 1;
-- Attendu : aucune ligne en double.

SELECT SCHEMA_NOM, TABLE_NOM, COLONNE, TYPE_DONNEE, DESCRIPTION,
       SENSIBILITE, DONNEE_PERSONNELLE, DUREE_CONSERVATION
FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE
ORDER BY TABLE_NOM, COLONNE;
-- Vérifier les valeurs des tags existants, y compris ceux hérités des tables.

SELECT TABLE_NOM, COLONNE, DESCRIPTION, DONNEE_PERSONNELLE
FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE
WHERE DONNEE_PERSONNELLE IS NULL
ORDER BY TABLE_NOM, COLONNE;
-- L'absence de catégorie ne retire pas la colonne et ne prouve pas qu'elle est non personnelle.

SHOW GRANTS ON VIEW NYC_TAXI.GOUVERNANCE.V_CATALOGUE;
-- Vérifier SELECT pour RH_PAIE, RESP_DEPOT_QUEENS, RESP_DEPOT_BRONX et ANALYSTE
-- après la première création et après réexécution, via les grants futurs du script 02.

-- Tests manuels séparés : copier ce bloc seul, après succès des vérifications précédentes.
-- USE SECONDARY ROLES NONE;
-- USE ROLE ANALYSTE;
-- USE WAREHOUSE NYC_TAXI_WH;
-- SELECT COUNT(*) AS nb_colonnes FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE;
-- SELECT TABLE_NOM, COUNT(*) AS nb_colonnes
-- FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE GROUP BY TABLE_NOM ORDER BY TABLE_NOM;
-- SELECT * FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE ORDER BY TABLE_NOM, COLONNE;
-- Attendu : 24 lignes, les trois tables et les métadonnées accessibles à ce rôle.
-- Refaire le bloc avec RH_PAIE, RESP_DEPOT_QUEENS puis RESP_DEPOT_BRONX.
-- INFORMATION_SCHEMA et la fonction de tags ont des règles de visibilité :
-- comparer les résultats entre rôles, sans déclarer les tests validés avant exécution.
