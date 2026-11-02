USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- Jour 1, étape 11 : fiche complète, adaptée du modèle DIM_DEPOT.
-- Prérequis : tags et droits de 01_gouvernance.sql en place.
-- Rejouable : seuls les commentaires et les affectations de tags sont remplacés.
-- Vérification statique uniquement ; exécution et réexécution à faire dans Snowsight.

COMMENT ON TABLE NYC_TAXI.RAW.DRIVERS IS
  'Données RH des chauffeurs : une ligne source par chauffeur selon le contrat. Source : data/drivers.csv chargé par chargement_rh_2_copier.sql, avec métadonnées de chargement. Mise à jour lors de chaque chargement manuel de fichier ; fréquence métier non précisée.';

COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.driver_id IS 'Identifiant interne du chauffeur, utilisé pour rattacher ses services et joindre les tables RH.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.first_name IS 'Prénom du chauffeur, élément de son identité.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.last_name IS 'Nom de famille du chauffeur, élément de son identité.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.email IS 'Adresse électronique de contact du chauffeur.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.phone IS 'Numéro de téléphone de contact du chauffeur.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.birth_date IS 'Date de naissance du chauffeur ; donnée personnelle même sans son nom.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.tlc_license_number IS 'Numéro de licence du chauffeur délivré par la Taxi and Limousine Commission.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.depot IS 'Dépôt de rattachement du chauffeur ; information professionnelle associée à la personne.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.hire_date IS 'Date de début du contrat du chauffeur ; utilisée pour calculer son ancienneté.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.end_date IS 'Date de fin du contrat ; une valeur NULL indique un chauffeur en poste selon le contrat de gouvernance.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS._source_file IS 'Nom du fichier source enregistré par METADATA$FILENAME lors du chargement.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS._loaded_at IS 'Date et heure de début de lecture du fichier, issues de METADATA$START_SCAN_TIME et stockées sans fuseau horaire.';

-- R1 est une règle interne du contrat ; sa justification juridique reste à valider.
ALTER TABLE NYC_TAXI.RAW.DRIVERS SET TAG
  NYC_TAXI.GOUVERNANCE.SENSIBILITE = 'confidentiel',
  NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION = '5 ans après la fin du contrat';

ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN driver_id SET TAG
  NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN first_name SET TAG
  NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN last_name SET TAG
  NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN email SET TAG
  NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'email';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN phone SET TAG
  NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'telephone';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN birth_date SET TAG
  NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'date_naissance';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN tlc_license_number SET TAG
  NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_officiel';

-- Les colonnes personnelles sans catégorie adaptée sont recensées dans docs/REGISTRE.md.
-- Leur absence de tag ne les anonymise pas et ne déclenche pas un masquage fondé sur ce tag.

-- Vérifier le commentaire de table et les 12 commentaires de colonnes.
SELECT table_name, comment FROM NYC_TAXI.INFORMATION_SCHEMA.TABLES
WHERE table_schema = 'RAW' AND table_name = 'DRIVERS';

SELECT column_name, comment FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = 'RAW' AND table_name = 'DRIVERS'
ORDER BY ordinal_position;

-- Attendu : les deux tags de table avec les valeurs ci-dessus.
SELECT tag_name, tag_value
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES('NYC_TAXI.RAW.DRIVERS', 'TABLE'))
WHERE tag_database = 'NYC_TAXI' AND tag_schema = 'GOUVERNANCE'
  AND tag_name IN ('SENSIBILITE', 'DUREE_CONSERVATION')
ORDER BY tag_name;

-- Attendu : 7 colonnes catégorisées ; vérifier les noms et valeurs.
SELECT column_name, tag_name, tag_value
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.RAW.DRIVERS', 'TABLE'))
WHERE tag_database = 'NYC_TAXI' AND tag_schema = 'GOUVERNANCE'
  AND tag_name = 'DONNEE_PERSONNELLE'
ORDER BY column_name;
