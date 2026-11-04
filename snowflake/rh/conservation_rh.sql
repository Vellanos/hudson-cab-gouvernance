USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- Jour 3, étape 2 : conservation R2 uniquement ; exécution manuelle dans Snowsight.
-- TRANSFORMER est propriétaire des tables RH selon les scripts fournis.
-- SET est rejouable : aucune table n'est recréée et les données, tags, descriptions,
-- politiques et privilèges existants sont préservés.
-- Time Travel est configuré à un jour pour chacune des quatre tables RH.
-- Les vues STAGING lisent RAW et ne stockent pas ces données : aucun réglage ici.
-- DIM_DEPOT est exclue : référentiel sans données personnelles selon le contrat.
-- Les tables permanentes ont aussi 7 jours de Fail-safe, distincts de Time Travel,
-- après celui-ci ; ce mécanisme de récupération par Snowflake n'est pas modifié.
-- Aucun SQL exécuté ni résultat de contrôle validé par cette intervention.
-- Références officielles :
-- https://docs.snowflake.com/en/sql-reference/sql/alter-table
-- https://docs.snowflake.com/en/sql-reference/sql/show-parameters
-- https://docs.snowflake.com/en/user-guide/data-time-travel
-- https://docs.snowflake.com/en/user-guide/data-failsafe

ALTER TABLE NYC_TAXI.RAW.DRIVERS SET DATA_RETENTION_TIME_IN_DAYS = 1;
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS SET DATA_RETENTION_TIME_IN_DAYS = 1;
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER SET DATA_RETENTION_TIME_IN_DAYS = 1;
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY SET DATA_RETENTION_TIME_IN_DAYS = 1;

-- Vérifier value = 1 et level = TABLE pour chaque paramètre explicitement posé.
SHOW PARAMETERS LIKE 'DATA_RETENTION_TIME_IN_DAYS' IN TABLE NYC_TAXI.RAW.DRIVERS;
SHOW PARAMETERS LIKE 'DATA_RETENTION_TIME_IN_DAYS' IN TABLE NYC_TAXI.RAW.DRIVER_SHIFTS;
SHOW PARAMETERS LIKE 'DATA_RETENTION_TIME_IN_DAYS' IN TABLE NYC_TAXI.MARTS.DIM_DRIVER;
SHOW PARAMETERS LIKE 'DATA_RETENTION_TIME_IN_DAYS' IN TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY;

-- Lecture seule : le minimum de compte ne remplace pas la valeur affichée ci-dessus.
-- La durée effective de chaque table vaut MAX(1, MIN_DATA_RETENTION_TIME_IN_DAYS).
-- Si ce minimum dépasse 1, signaler que R2 n'est pas satisfaite ; ne pas modifier le compte.
-- Si cette valeur n'est pas visible avec TRANSFORMER, demander sa vérification à
-- l'administrateur avant de conclure à une durée effective d'un jour.
SHOW PARAMETERS LIKE 'MIN_DATA_RETENTION_TIME_IN_DAYS' IN ACCOUNT;
