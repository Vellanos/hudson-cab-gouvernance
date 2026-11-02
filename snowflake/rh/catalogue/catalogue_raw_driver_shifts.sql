USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- Jour 1, étape 11 : fiche courte, adaptée du modèle DIM_DEPOT.
-- Prérequis : tags et droits de 01_gouvernance.sql en place.
-- Rejouable : seuls les commentaires et les affectations de tags sont remplacés.
-- Vérification statique uniquement ; exécution et réexécution à faire dans Snowsight.

COMMENT ON TABLE NYC_TAXI.RAW.DRIVER_SHIFTS IS
  'Services des chauffeurs : une ligne source par prise de poste, avant déduplication STAGING. Source : data/driver_shifts.csv chargé par chargement_rh_2_copier.sql, avec métadonnées de chargement. Mise à jour lors de chaque chargement manuel de fichier ; fréquence métier non précisée.';

-- R1 est une règle interne du contrat ; sa justification juridique reste à valider.
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS SET TAG
  NYC_TAXI.GOUVERNANCE.SENSIBILITE = 'confidentiel',
  NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION = '5 ans après la fin du contrat';

ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN shift_id SET TAG
  NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN driver_id SET TAG
  NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';

-- Les colonnes personnelles sans catégorie adaptée sont recensées dans docs/REGISTRE.md.
-- Leur absence de tag ne les anonymise pas et ne déclenche pas un masquage fondé sur ce tag.

-- Vérifier le commentaire de table.
SELECT table_name, comment FROM NYC_TAXI.INFORMATION_SCHEMA.TABLES
WHERE table_schema = 'RAW' AND table_name = 'DRIVER_SHIFTS';

-- Attendu : les deux tags de table avec les valeurs ci-dessus.
SELECT tag_name, tag_value
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES('NYC_TAXI.RAW.DRIVER_SHIFTS', 'TABLE'))
WHERE tag_database = 'NYC_TAXI' AND tag_schema = 'GOUVERNANCE'
  AND tag_name IN ('SENSIBILITE', 'DUREE_CONSERVATION')
ORDER BY tag_name;

-- Attendu : 2 colonnes catégorisées ; vérifier les noms et valeurs.
SELECT column_name, tag_name, tag_value
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.RAW.DRIVER_SHIFTS', 'TABLE'))
WHERE tag_database = 'NYC_TAXI' AND tag_schema = 'GOUVERNANCE'
  AND tag_name = 'DONNEE_PERSONNELLE'
ORDER BY column_name;
