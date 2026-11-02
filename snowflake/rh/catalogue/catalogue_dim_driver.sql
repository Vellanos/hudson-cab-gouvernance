USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- Jour 1, étape 11 : fiche complète, adaptée du modèle DIM_DEPOT.
-- Prérequis : tags et droits de 01_gouvernance.sql en place.
-- Rejouable : seuls les commentaires et les affectations de tags sont remplacés.
-- Vérification statique uniquement ; exécution et réexécution à faire dans Snowsight.

COMMENT ON TABLE NYC_TAXI.MARTS.DIM_DRIVER IS
  'Dimension RH des chauffeurs : une ligne par chauffeur selon le contrat, avec coordonnées et indicateurs de situation professionnelle. Source : STAGING.STG_RH__DRIVERS, issue de RAW.DRIVERS. Mise à jour par remplacement du contenu à chaque exécution de marts/dim_driver.sql ; fréquence métier non précisée.';

COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.driver_id IS 'Identifiant interne du chauffeur, utilisé pour rattacher ses services et joindre les tables RH.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.first_name IS 'Prénom du chauffeur, élément de son identité.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.last_name IS 'Nom de famille du chauffeur, élément de son identité.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.email IS 'Adresse électronique du chauffeur, mise en minuscules après retrait des espaces externes en STAGING.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.phone IS 'Téléphone du chauffeur après retrait des espaces externes ; une chaîne vide est convertie en NULL en STAGING.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.birth_date IS 'Date de naissance du chauffeur ; donnée personnelle même sans son nom.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.tlc_license_number IS 'Numéro de licence du chauffeur délivré par la Taxi and Limousine Commission.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.depot IS 'Dépôt de rattachement après TRIM et INITCAP en STAGING ; information professionnelle personnelle.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.hire_date IS 'Date de début du contrat du chauffeur ; utilisée pour calculer son ancienneté.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.end_date IS 'Date de fin du contrat ; une valeur NULL indique un chauffeur en poste selon le contrat de gouvernance.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.is_active IS 'Indicateur calculé par end_date IS NULL ; vrai si aucune date de fin de contrat n''est renseignée.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.tenure_years IS 'Ancienneté calculée en jours depuis hire_date jusqu''à end_date, ou la date courante si elle est absente, divisée par 365,25 et arrondie à une décimale.';

-- R1 est une règle interne du contrat ; sa justification juridique reste à valider.
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER SET TAG
  NYC_TAXI.GOUVERNANCE.SENSIBILITE = 'confidentiel',
  NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION = '5 ans après la fin du contrat';

ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN driver_id SET TAG
  NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN first_name SET TAG
  NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN last_name SET TAG
  NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN email SET TAG
  NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'email';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN phone SET TAG
  NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'telephone';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN birth_date SET TAG
  NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'date_naissance';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN tlc_license_number SET TAG
  NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_officiel';

-- Les colonnes personnelles sans catégorie adaptée sont recensées dans docs/REGISTRE.md.
-- Leur absence de tag ne les anonymise pas et ne déclenche pas un masquage fondé sur ce tag.

-- Vérifier le commentaire de table et les 12 commentaires de colonnes.
SELECT table_name, comment FROM NYC_TAXI.INFORMATION_SCHEMA.TABLES
WHERE table_schema = 'MARTS' AND table_name = 'DIM_DRIVER';

SELECT column_name, comment FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = 'MARTS' AND table_name = 'DIM_DRIVER'
ORDER BY ordinal_position;

-- Attendu : les deux tags de table avec les valeurs ci-dessus.
SELECT tag_name, tag_value
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES('NYC_TAXI.MARTS.DIM_DRIVER', 'TABLE'))
WHERE tag_database = 'NYC_TAXI' AND tag_schema = 'GOUVERNANCE'
  AND tag_name IN ('SENSIBILITE', 'DUREE_CONSERVATION')
ORDER BY tag_name;

-- Attendu : 7 colonnes catégorisées ; vérifier les noms et valeurs.
SELECT column_name, tag_name, tag_value
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.DIM_DRIVER', 'TABLE'))
WHERE tag_database = 'NYC_TAXI' AND tag_schema = 'GOUVERNANCE'
  AND tag_name = 'DONNEE_PERSONNELLE'
ORDER BY column_name;
