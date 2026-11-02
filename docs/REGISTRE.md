# Registre du traitement — données du personnel

État au 2 novembre 2026 : seule la partie 1 est remplie, par lecture des en-têtes CSV, du contrat et des SQL. Aucun chargement ni résultat observé dans Snowflake.

## Partie 1 — Inventaire des données personnelles (jour 1)

Selon l'[art. 4 point 1 du RGPD](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre1), une donnée personnelle concerne une personne identifiée ou identifiable : identité directe, ou information indirectement rattachable. Les mentions de format entre crochets ne sont pas des valeurs extraites des fichiers ; aucune donnée individuelle n'est reproduite.

Les 18 colonnes sont personnelles dans leur contexte RH. Un nom seul n'est pas toujours unique ; il est classé comme identité directe selon la trame. Un dépôt isolé dans un référentiel ne décrit pas une personne : `MARTS.DIM_DEPOT` est non personnel selon le contrat. Le même dépôt rattaché à un chauffeur ou à son service devient une information personnelle indirecte.

« — » signifie : aucune des six valeurs autorisées ne convient. Cela ne signifie pas « non personnel » ; ne pas inventer de tag ni détourner `identifiant_interne` pour une mesure ou une date. Les besoins ci-dessous sont une analyse du contrat et des transformations, pas des habilitations constatées.

### `drivers.csv` : les colonnes

| Colonne | Exemple de valeur | Donnée personnelle ? (direct, indirect, non) | Valeur du tag `DONNEE_PERSONNELLE` | Qui en a besoin, et pour quoi faire |
|---|---|---|---|---|
| `driver_id` | [texte] | indirect — clé de rapprochement | `identifiant_interne` | Tous les rôles métier : compter et joindre ; outils : rattacher les services. |
| `first_name` | [texte] | direct — identité | `nom` | Paie et responsables de dépôt : reconnaître le chauffeur. |
| `last_name` | [texte] | direct — identité | `nom` | Paie et responsables de dépôt : reconnaître le chauffeur. |
| `email` | [texte] | direct — contact | `email` | Paie : échanges administratifs ; outils : nettoyage. |
| `phone` | [texte] | direct — contact | `telephone` | Paie et responsable du dépôt : joindre le chauffeur. |
| `birth_date` | [date] | indirect — caractéristique personnelle | `date_naissance` | Paie : besoin exact à justifier ; analyste : année seulement selon le contrat. |
| `tlc_license_number` | [texte] | direct — identifiant officiel rapprochable | `identifiant_officiel` | Paie : vérifier la licence ; outils : contrôle d'unicité. |
| `depot` | [texte] | indirect — rattachement professionnel | — | Responsables : périmètre du dépôt ; paie et analyste : regroupements. |
| `hire_date` | [date] | indirect — parcours professionnel | — | Paie : suivi contractuel ; outils : calcul de l'ancienneté. |
| `end_date` | [date ou vide] | indirect — parcours professionnel | — | Paie : départ ; outils : statut actif et échéance de R1. |

### `driver_shifts.csv` : les colonnes

| Colonne | Exemple de valeur | Donnée personnelle ? (direct, indirect, non) | Valeur du tag `DONNEE_PERSONNELLE` | Qui en a besoin, et pour quoi faire |
|---|---|---|---|---|
| `shift_id` | [texte] | indirect — service rattachable | `identifiant_interne` | Outils : déduplication ; exploitation : distinguer les services. |
| `driver_id` | [texte] | indirect — clé de rapprochement | `identifiant_interne` | Outils : joindre le chauffeur ; métiers : comptages par chauffeur. |
| `shift_date` | [date] | indirect — activité datée | — | Exploitation : planning ; analyste : regroupement mensuel. |
| `depot` | [texte] | indirect — lieu du service | — | Responsables : périmètre du dépôt ; analyste : répartition d'activité. |
| `start_hour` | [entier] | indirect — horaire individuel | — | Exploitation : organisation des prises de poste ; besoin détaillé à confirmer. |
| `hours_worked` | [nombre décimal] | indirect — activité individuelle | — | Paie et responsables : suivi des heures ; analyste : somme mensuelle. |
| `trips_count` | [entier] | indirect — activité individuelle | — | Responsables et analyste : volume de courses. |
| `revenue_usd` | [nombre décimal] | indirect — résultat économique individuel | — | Paie : besoin à confirmer ; responsables et analyste : recettes d'activité. |

### Où cette donnée est-elle copiée ?

Lignage **prévu dans les fichiers SQL**, non observé dans un compte. Préfixe commun : `NYC_TAXI`. D = `RAW.DRIVERS` → `STAGING.STG_RH__DRIVERS` → `MARTS.DIM_DRIVER`. S = `RAW.DRIVER_SHIFTS` → `STAGING.STG_RH__DRIVER_SHIFTS` ; M = `MARTS.MART_DRIVER_MONTHLY`.

| Colonne d'origine | Table ou vue | Colonne | Sous quelle forme |
|---|---|---|---|
| drivers.driver_id | D ; jointure vers M | driver_id | Identique dans D ; clé de jointure pour retrouver driver_name dans M. Le driver_id de M est sélectionné depuis S. |
| drivers.first_name | D ; M | first_name ; driver_name | Identique dans D ; concaténation prénom + espace + nom dans M. |
| drivers.last_name | D ; M | last_name ; driver_name | Identique dans D ; concaténation dans M. |
| drivers.email | D | email | Brut dans RAW ; minuscules et espaces externes retirés en STAGING, puis copie dans DIM_DRIVER. |
| drivers.phone | D | phone | Brut dans RAW ; espaces externes retirés et chaîne vide convertie en NULL en STAGING, puis copie. |
| drivers.birth_date | D | birth_date | Conversion date, puis copie ; aucune dérivation en année dans les SQL fournis. |
| drivers.tlc_license_number | D | tlc_license_number | Copie sans anonymisation. |
| drivers.depot | D | depot | Brut dans RAW ; TRIM et INITCAP en STAGING, puis copie ; M utilise le dépôt du service. |
| drivers.hire_date | D | hire_date ; tenure_years | Date copiée ; ancienneté calculée jusqu'à end_date ou la date courante, arrondie à une décimale. |
| drivers.end_date | D | end_date ; is_active ; tenure_years | Date copiée ; NULL indique actif ; entre dans le calcul d'ancienneté. |
| driver_shifts.shift_id | S ; M | shift_id ; nb_shifts | Identifiant copié et déduplication en STAGING par shift_id, ordre _loaded_at ; contribue au COUNT(*) mensuel, sans être conservé dans M. |
| driver_shifts.driver_id | S ; M | driver_id | Copie ; regroupement par chauffeur et jointure gauche avec DIM_DRIVER. |
| driver_shifts.shift_date | S ; M | shift_date ; activity_month | Date puis premier jour du mois par DATE_TRUNC. |
| driver_shifts.depot | S ; M | depot | TRIM et INITCAP en STAGING, puis clé de regroupement mensuel. |
| driver_shifts.start_hour | S | start_hour | Conversion entier ; non sélectionné dans M. |
| driver_shifts.hours_worked | S ; M | hours_worked | Conversion numérique ; somme mensuelle arrondie à une décimale dans M. |
| driver_shifts.trips_count | S ; M | trips_count | Conversion entier ; somme mensuelle dans M. |
| driver_shifts.revenue_usd | S ; M | revenue_usd | Conversion numérique ; somme mensuelle arrondie à deux décimales dans M. |

Preuves statiques : [chargement](../snowflake/rh/chargement_rh_2_copier.sql), [vue chauffeurs](../snowflake/rh/staging/stg_rh__drivers.sql), [vue services](../snowflake/rh/staging/stg_rh__driver_shifts.sql), [dimension chauffeur](../snowflake/rh/marts/dim_driver.sql), [activité mensuelle](../snowflake/rh/marts/mart_driver_monthly.sql), [référentiel dépôt](../snowflake/rh/marts/dim_depot.sql). Les CSV passent aussi par le stage temporaire prévu par le chargement ; R3 impose son nettoyage, non vérifié ici.

Les colonnes techniques `_source_file` et `_loaded_at`, absentes des CSV, sont ajoutées au chargement et renommées `source_file` et `loaded_at` dans les vues. Elles ne sont pas conservées dans les marts fournis. Leur présence ne rend pas les lignes anonymes.

Proposition documentaire de tags de table : `SENSIBILITE=confidentiel` pour les quatre tables RH et `interne` pour DIM_DEPOT, conformément au modèle officiel. `DUREE_CONSERVATION=5 ans après la fin du contrat` décrit R1 pour les tables RH ; sa justification juridique reste en attente (VEILLE, section 4). Les affectations de tags sont préparées dans les fiches de catalogue ; elles restent à exécuter et vérifier dans Snowsight.

### Catalogue RH — étape 11 : couverture et limites

Les quatre fiches SQL de `snowflake/rh/catalogue/` sont préparées à partir des définitions existantes, sans exécution Snowflake. RAW.DRIVERS et MARTS.DIM_DRIVER ont une description de chacune de leurs 12 colonnes ; RAW.DRIVER_SHIFTS et MARTS.MART_DRIVER_MONTHLY ont une fiche courte.

Décision utilisateur : seules les correspondances exactes avec les valeurs autorisées du contrat sont taguées, sans nouvelle catégorie ni valeur de remplacement trompeuse.

| Table | Colonnes ayant une catégorie DONNEE_PERSONNELLE |
|---|---|
| RAW.DRIVERS et MARTS.DIM_DRIVER | driver_id → identifiant_interne ; first_name et last_name → nom ; email → email ; phone → telephone ; birth_date → date_naissance ; tlc_license_number → identifiant_officiel |
| RAW.DRIVER_SHIFTS | shift_id et driver_id → identifiant_interne |
| MARTS.MART_DRIVER_MONTHLY | driver_id → identifiant_interne ; driver_name → nom (concaténation de first_name et last_name) |

Les informations suivantes restent personnelles par leur rattachement au chauffeur, mais aucune catégorie autorisée ne leur correspond :

| Table | Colonnes personnelles sans tag adapté |
|---|---|
| RAW.DRIVERS | depot, hire_date, end_date |
| MARTS.DIM_DRIVER | depot, hire_date, end_date ; is_active (calculé depuis end_date), tenure_years (ancienneté calculée) |
| RAW.DRIVER_SHIFTS | shift_date, depot, start_hour, hours_worked, trips_count, revenue_usd |
| MARTS.MART_DRIVER_MONTHLY | activity_month (mois calculé), depot, nb_shifts (comptage), hours_worked, trips_count, revenue_usd (sommes mensuelles par chauffeur) |

Les métadonnées `_source_file` et `_loaded_at` des deux tables RAW ne sont pas des identifiants de chauffeur en elles-mêmes ; elles sont associées aux lignes RH et n'ont pas de catégorie adaptée. Elles restent sans tag DONNEE_PERSONNELLE. Les descriptions complètes de RAW.DRIVERS expliquent leur provenance technique.

**Limite C20 : couverture incomplète.** Une colonne personnelle non taguée n'est pas automatiquement protégée par un futur masquage fondé uniquement sur DONNEE_PERSONNELLE. Les tags de table ne remplacent pas cette couverture et les tags seuls n'appliquent aucun masquage. Ce choix respecte le vocabulaire du contrat ; il ne satisfait pas entièrement C20. Aucune politique n'est créée à cette étape.

Les quatre tables RH reçoivent dans les fiches `SENSIBILITE=confidentiel` et `DUREE_CONSERVATION=5 ans après la fin du contrat`. Cette dernière valeur décrit R1, sans validation juridique ni mécanisme de purge. DIM_DEPOT reste non personnel et de sensibilité `interne`, selon le modèle officiel inchangé, à exécuter séparément avant les quatre fiches. Les rythmes décrits correspondent aux exécutions des scripts fournis ; leur fréquence métier n'est pas précisée.

### Ce qui a surpris

Les recettes et horaires décrivent un chauffeur même sans son nom ; l'agrégation mensuelle par driver_id reste personnelle.
La licence publique reste un identifiant officiel. Le nom complet est recopié dans driver_name : masquer seulement les colonnes d'origine ne couvrirait pas cette copie.
Le vocabulaire des tags laisse plusieurs données personnelles sans valeur adaptée ; c'est une limite du contrat à faire valider.

---

## Partie 2 — Fiche de registre (jour 3)

Le registre des activités de traitement décrit ce qu'une organisation fait des données personnelles qu'elle détient. Cette fiche en est une version réduite, limitée à ce qu'un Data Engineer peut renseigner et prouver. La trame complète est celle de la CNIL (lien dans les ressources).

Chaque réponse de la colonne de droite doit pouvoir être vérifiée dans l'entrepôt : indiquez la requête ou le fichier qui le prouve.

### Le traitement

| Rubrique | Réponse |
|---|---|
| Nom du traitement | |
| Finalité : à quoi servent ces données | |
| Personnes concernées | |
| Service responsable des données | |

### Les données

| Catégorie de données | Colonnes concernées | Tables où elles se trouvent |
|---|---|---|
| Identité | | |
| Coordonnées | | |
| Vie professionnelle | | |

### Qui y accède

| Rôle | Ce qu'il voit | Pourquoi il en a besoin | Preuve (requête ou test) |
|---|---|---|---|
| | | | |

### Combien de temps

| Règle | Comment elle est appliquée | Preuve |
|---|---|---|
| R1 : suppression 5 ans après la fin du contrat | | |
| R2 : pas de restauration au-delà de 1 jour | | |
| R3 : pas de fichier sur le stage | | |

Délai réel entre l'exécution de la purge et la disparition définitive d'une donnée dans Snowflake, en tenant compte de Time Travel et de Fail-safe : ______ jours.

### Comment on le contrôle

| Question | Réponse | Preuve |
|---|---|---|
| Peut-on dire qui a lu ces données la semaine dernière ? | | |
| Sait-on quand une donnée est fausse ? | | |
| Que se passe-t-il si le rôle des outils est compromis ? | | |

### Limites connues

Ce que votre mise en œuvre ne couvre pas : deux ou trois lignes, sans détour.
