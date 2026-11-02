USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- Jour 1, étape 11 : fiche courte, adaptée du modèle DIM_DEPOT.
-- Prérequis : tags et droits de 01_gouvernance.sql en place.
-- Rejouable : seuls les commentaires et les affectations de tags sont remplacés.
-- Vérification statique uniquement ; exécution et réexécution à faire dans Snowsight.

COMMENT ON TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY IS
  'Activité mensuelle regroupée par mois, chauffeur, nom et dépôt du service : nombres de services et de courses, heures et recettes. Source : STAGING.STG_RH__DRIVER_SHIFTS, avec jointure gauche vers MARTS.DIM_DRIVER pour le nom complet. Mise à jour par remplacement du contenu à chaque exécution de marts/mart_driver_monthly.sql ; fréquence métier non précisée. Ces agrégats par chauffeur restent personnels.';

-- R1 est une règle interne du contrat ; sa justification juridique reste à valider.
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY SET TAG
  NYC_TAXI.GOUVERNANCE.SENSIBILITE = 'confidentiel',
  NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION = '5 ans après la fin du contrat';

ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN driver_id SET TAG
  NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN driver_name SET TAG
  NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';

-- Les colonnes personnelles sans catégorie adaptée sont recensées dans docs/REGISTRE.md.
-- Leur absence de tag ne les anonymise pas et ne déclenche pas un masquage fondé sur ce tag.

-- Vérifier le commentaire de table.
SELECT table_name, comment FROM NYC_TAXI.INFORMATION_SCHEMA.TABLES
WHERE table_schema = 'MARTS' AND table_name = 'MART_DRIVER_MONTHLY';

-- Attendu : les deux tags de table avec les valeurs ci-dessus.
SELECT tag_name, tag_value
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES('NYC_TAXI.MARTS.MART_DRIVER_MONTHLY', 'TABLE'))
WHERE tag_database = 'NYC_TAXI' AND tag_schema = 'GOUVERNANCE'
  AND tag_name IN ('SENSIBILITE', 'DUREE_CONSERVATION')
ORDER BY tag_name;

-- Attendu : 2 colonnes catégorisées ; vérifier les noms et valeurs.
SELECT column_name, tag_name, tag_value
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.MART_DRIVER_MONTHLY', 'TABLE'))
WHERE tag_database = 'NYC_TAXI' AND tag_schema = 'GOUVERNANCE'
  AND tag_name = 'DONNEE_PERSONNELLE'
ORDER BY column_name;
