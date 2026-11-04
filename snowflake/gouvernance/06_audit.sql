-- Jour 3, étape 8 : accès à DIM_DRIVER sur les sept derniers jours.
-- Métadonnées uniquement : ni valeurs RH ni texte des requêtes.
-- ACCESS_HISTORY peut avoir jusqu'à trois heures de retard.
-- Un résultat vide ne prouve pas l'absence d'accès : attendre la disponibilité
-- des historiques ; les requêtes échouées ne sont pas consignées dans ACCESS_HISTORY.
-- Références officielles :
-- https://docs.snowflake.com/en/sql-reference/account-usage/access_history
-- https://docs.snowflake.com/en/sql-reference/account-usage/query_history
-- https://docs.snowflake.com/en/sql-reference/functions/flatten

USE SECONDARY ROLES NONE;
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE NYC_TAXI_WH;

-- DISTINCT conserve une seule ligne par requête et objet, même si la liste
-- contient plusieurs occurrences. Le rôle vient de QUERY_HISTORY.
-- LEFT JOIN conserve l'accès si QUERY_HISTORY n'est pas encore disponible :
-- le rôle et le type sont alors NULL, à revérifier après le délai de disponibilité.
SELECT DISTINCT
    ah.query_start_time AS date_heure,
    ah.user_name AS utilisateur,
    qh.role_name AS role_nom,
    qh.query_type AS type_requete,
    objet.value:objectName::VARCHAR AS objet_consulte,
    ah.query_id
FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY ah
LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY qh
    ON qh.query_id = ah.query_id,
LATERAL FLATTEN(INPUT => ah.base_objects_accessed) objet
WHERE ah.query_start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
  AND ah.query_start_time <= CURRENT_TIMESTAMP()
  AND UPPER(objet.value:objectDomain::VARCHAR) = 'TABLE'
  AND objet.value:objectName::VARCHAR = 'NYC_TAXI.MARTS.DIM_DRIVER'
ORDER BY date_heure DESC, ah.query_id;
