# Hudson Cab — Snowflake et gouvernance des données

Projet de formation Simplon : documenter puis protéger un entrepôt RH de chauffeurs new-yorkais, dont la gestion est confiée à Hudson Cab Europe à Paris. Le [guide](GUIDE_BRIEF_GOUVERNANCE.md) fixe la chronologie ; le [contrat](CONTRAT_GOUVERNANCE.md) reste inchangé.

## Gouvernance

Les deux CSV RH, annoncés fictifs par le guide, restent locaux dans `data/` et sont ignorés par Git : un dépôt public ne doit pas servir à diffuser un fichier de personnel. Le commit initial a été réécrit pour les exclure de l'historique de la branche publiée. Cela ne garantit pas la disparition d'anciennes copies, caches ou clones.

Documents du jour 1 matin : [veille RGPD](docs/VEILLE.md), [inventaire des 18 colonnes et lignage prévu](docs/REGISTRE.md), [trame des accès](docs/ACCES.md).

Écarts et points à valider, détaillés dans la veille :

- **R1** : les cinq ans pour toutes les données ne sont pas justifiés par finalité ; actif et archive ne sont pas distingués. Les cinq ans du registre unique du personnel français ne s'appliquent pas automatiquement aux chauffeurs américains ([CNIL, référentiel RH de 2019, section 7](https://www.cnil.fr/sites/cnil/files/atoms/files/referentiel_grh_novembre_2019_0.pdf) ; [CNIL, conservation](https://www.cnil.fr/fr/passer-laction/les-durees-de-conservation-des-donnees)).
- **R2** : un jour est une décision interne, pas un délai du RGPD ; Time Travel ne couvre pas Fail-safe ni toutes les copies ([art. 17](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre3), [Snowflake Fail-safe](https://docs.snowflake.com/en/user-guide/data-failsafe)).
- **R3** : la purge du stage prévue dans le SQL ne prouve pas sa réalisation et ne couvre pas les copies locales ou publiées ([art. 5 §1 c et f](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre2)).
- **Accès et tags** : justifier les accès étendus, les données réidentifiantes et les colonnes personnelles sans tag adapté ; clarifier l'accès administrateur ([art. 4 point 1](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre1), [art. 25 et 32](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre4)).
- **Qualité** : les huit contrôles sont partiels et leurs seuils internes ; une alerte exige une correction suivie, même sous le seuil bloquant ([art. 5 §1 d](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre2), [art. 16](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre3)).

Catalogue RH (étape 11) vérifié dans Snowsight selon l'utilisateur ; [les quatre fiches SQL](snowflake/rh/catalogue/) restent versionnées. Seules les catégories exactes du contrat sont affectées : les dates professionnelles, dépôts, indicateurs calculés et mesures par chauffeur sans catégorie restent explicitement recensés dans le [registre](docs/REGISTRE.md). Une colonne personnelle non taguée ne sera pas automatiquement protégée par un masquage fondé uniquement sur ce tag : **C20 reste partiellement couvert**. Les tags seuls ne masquent pas les données ; R1 reste à valider juridiquement.

### Jour 2, étape 4 — conserver les colonnes et masquer selon le rôle

**Décision : conserver toutes les colonnes des quatre tables RH et choisir le masquage plutôt que la suppression.** Aucun DROP COLUMN ni changement des pipelines n'est nécessaire. RH_PAIE doit garder l'ensemble des informations RH dans MARTS ; TRANSFORMER doit lire les valeurs originales nécessaires aux transformations, afin de ne pas matérialiser des masques lors de la reconstruction.

Les comportements suivants sont des **cibles documentaires, pas des protections déjà appliquées** :

- RH_PAIE : toutes les lignes et valeurs de ses tables MARTS en clair.
- RESP_DEPOT_QUEENS et RESP_DEPOT_BRONX : uniquement leur dépôt, avec nom, prénom et téléphone en clair ; e-mail, date de naissance et licence masqués. Le nom calculé driver_name suit la même règle que le nom source.
- ANALYSTE : tous les dépôts, sans identifiant direct en clair ; driver_id reste visible par exception explicite du contrat. Les mesures analytiques sont conservées pour l'analyse ; cela ne rend pas les lignes anonymes et ne tranche pas les restrictions encore ambiguës sur les attributs personnels sans catégorie.
- GOUVERNANCE : aucune lecture des données RH, faute de SELECT ; un accès refusé est attendu, pas nécessairement un comptage nul.
- ACCOUNTADMIN : aucune ligne RH dans MARTS une fois le futur filtrage effectif, ou accès refusé selon les droits réels. **Ambiguïté RAW conservée** : le texte du contrat prévoit des lignes héritées avec colonnes personnelles masquées, alors que la matrice annonce aucune ligne RH. Aucun accès personnel en clair n'est retenu comme cible ; l'arbitrage reste nécessaire, sans inventer une politique RAW.

Les rôles métier n'ont aucun accès direct à RAW/STAGING : conserver une colonne RAW ne leur ouvre pas sa lecture. La restriction par dépôt sera distincte du masquage ; elle n'est pas mise en œuvre ici.

Pour les colonnes catégorisées, les représentations proposées dans [ACCES.md](docs/ACCES.md) sont conservées : texte masqué intégralement par `'*****'`, date masquée par NULL de type DATE et valeurs source NULL préservées. Pour ANALYSTE, birth_date ne doit révéler que l'année : la représentation proposée est une DATE au 1er janvier de l'année source, sans jour ni mois réels. Aucune valeur individuelle n'est recopiée.

#### RAW.DRIVERS

| Colonne | Décision et justification |
|---|---|
| `driver_id` | Conserver : clé de rapprochement des chauffeurs et services ; catégorie identifiant_interne. L'exception métier sur driver_id ne donne pas accès à RAW. |
| `first_name` | Conserver et prévoir le masquage selon le rôle : identité nécessaire à la paie et aux responsables dans MARTS. |
| `last_name` | Conserver et prévoir le masquage selon le rôle : nom nécessaire à la paie, aux responsables et au calcul de driver_name. |
| `email` | Conserver et prévoir le masquage hors lecture autorisée : contact RH à transmettre sans altération à la paie via le pipeline. |
| `phone` | Conserver et prévoir le masquage selon le rôle : contact utile à la paie et aux responsables dans leur dépôt. |
| `birth_date` | Conserver la date originale pour la paie et TRANSFORMER ; prévoir un détail réduit à l'année pour ANALYSTE dans MARTS. |
| `tlc_license_number` | Conserver : identification officielle et contrôle d'unicité ; prévoir le masquage hors lecture autorisée, même si la licence est publique. |
| `depot` | Conserver sans catégorie trompeuse : rattachement professionnel nécessaire au périmètre des accès ; absence de catégorie adaptée documentée. |
| `hire_date` | Conserver sans faux tag : début de contrat utilisé pour l'ancienneté ; protection détaillée à clarifier. |
| `end_date` | Conserver sans faux tag : fin de contrat utilisée pour le statut et R1 ; protection détaillée à clarifier. |
| `_source_file` | Conserver sans faux tag : provenance technique de la ligne RH, utile à la traçabilité du chargement. |
| `_loaded_at` | Conserver sans faux tag : horodatage technique du chargement, utile à sa traçabilité. |

#### MARTS.DIM_DRIVER

| Colonne | Décision et justification |
|---|---|
| `driver_id` | Conserver en clair pour les quatre rôles métier : jointures et comptages autorisés explicitement, sans nommer le chauffeur. |
| `first_name` | Conserver ; clair pour RH_PAIE et les responsables dans leur dépôt, masqué pour ANALYSTE : identifier pour gérer, sans exposer l'identité à l'analyse. |
| `last_name` | Conserver ; mêmes droits que first_name : identité nécessaire à la gestion RH et à l'encadrement local. |
| `email` | Conserver ; clair pour RH_PAIE, masqué pour les responsables et ANALYSTE : la paie garde le contact administratif sans l'exposer à tous. |
| `phone` | Conserver ; clair pour RH_PAIE et les responsables dans leur dépôt, masqué pour ANALYSTE : contact opérationnel sans besoin analytique d'identification. |
| `birth_date` | Conserver ; date complète pour RH_PAIE, NULL DATE pour les responsables, année seule pour ANALYSTE : besoins différents sans perte de l'original. |
| `tlc_license_number` | Conserver ; clair pour RH_PAIE, masqué pour les responsables et ANALYSTE : identifiant officiel inutile à exposer pour l'analyse. |
| `depot` | Conserver sans nouveau tag : regroupement analytique et contrôle du périmètre Queens/Bronx ; ce rattachement reste personnel. |
| `hire_date` | Conserver sans faux tag : suivi RH et origine du calcul d'ancienneté ; visibilité détaillée hors RH_PAIE à clarifier. |
| `end_date` | Conserver sans faux tag : suivi des départs et conservation R1 ; visibilité détaillée hors RH_PAIE à clarifier. |
| `is_active` | Conserver sans faux tag : situation professionnelle calculée depuis end_date ; son caractère calculé ne la rend pas non personnelle. |
| `tenure_years` | Conserver sans faux tag : ancienneté calculée utile au suivi RH ; restrictions par rôle à clarifier. |

#### RAW.DRIVER_SHIFTS

| Colonne | Décision et justification |
|---|---|
| `shift_id` | Conserver avec sa catégorie existante identifiant_interne : repérer les services et leurs doublons ; aucune ouverture de RAW aux métiers. |
| `driver_id` | Conserver avec identifiant_interne : rattacher le service au chauffeur pour reconstruire les agrégats. |
| `shift_date` | Conserver sans faux tag : dater le service et calculer le mois d'activité ; information personnelle non catégorisée. |
| `depot` | Conserver sans faux tag : localiser le service et préparer son périmètre ; ne pas le confondre avec le dépôt actuel du chauffeur. |
| `start_hour` | Conserver sans faux tag : garder l'horaire source du service ; besoin détaillé et protection à clarifier. |
| `hours_worked` | Conserver sans faux tag : alimenter le total mensuel des heures ; mesure personnelle d'activité. |
| `trips_count` | Conserver sans faux tag : alimenter le total mensuel des courses ; mesure personnelle d'activité. |
| `revenue_usd` | Conserver sans faux tag : alimenter les recettes mensuelles ; donnée économique rattachée au chauffeur. |
| `_source_file` | Conserver sans faux tag : provenance technique utile au suivi du chargement des services. |
| `_loaded_at` | Conserver sans faux tag : horodatage utilisé notamment pour ordonner la déduplication STAGING. |

#### MARTS.MART_DRIVER_MONTHLY

| Colonne | Décision et justification |
|---|---|
| `activity_month` | Conserver sans faux tag : axe temporel de l'analyse mensuelle ; le regroupement par chauffeur reste personnel. |
| `driver_id` | Conserver en clair pour les quatre rôles métier : jointures et comptages autorisés par le contrat. |
| `driver_name` | Conserver ; clair pour RH_PAIE et les responsables dans leur dépôt, masqué pour ANALYSTE : le nom concaténé reste un identifiant direct. TRANSFORMER doit le reconstruire depuis les vrais noms. |
| `depot` | Conserver sans faux tag : regroupement analytique et futur filtre sur le dépôt du service. |
| `nb_shifts` | Conserver sans faux tag : comptage mensuel utile à l'analyse ; agrégat individuel non anonyme. |
| `hours_worked` | Conserver sans faux tag : total mensuel utile au suivi RH et à l'analyse ; détail accessible par rôle à clarifier. |
| `trips_count` | Conserver sans faux tag : volume mensuel de courses nécessaire à l'analyse ; demeure rattaché au chauffeur. |
| `revenue_usd` | Conserver sans faux tag : recette mensuelle nécessaire à l'analyse ; demeure une information économique personnelle. |

Les colonnes sans catégorie adaptée restent conservées et recensées dans [REGISTRE.md](docs/REGISTRE.md), sans nouvelle valeur de tag ni affectation trompeuse. Le choix du masquage plutôt que de la suppression ne résout pas leur visibilité finale pour chaque rôle : ces limites restent celles du cahier de tests. Un futur masque fondé uniquement sur DONNEE_PERSONNELLE ne les couvrira pas automatiquement ; **C20 reste partiellement couvert**. Aucune politique n'est créée ni appliquée par cette étape.


### Jour 3, étape 1 — purge RH selon R1

La purge est préparée dans [purge_rh.sql](snowflake/rh/purge_rh.sql), sans exécution Snowflake. R1 s'applique aussi aux services : ils portent driver_id et décrivent l'activité du chauffeur. Le script cible les contrats terminés depuis au moins cinq ans, avec une limite incluse calculée depuis CURRENT_DATE(), et exclut les chauffeurs dont end_date est NULL. Il supprime les services associés avant les chauffeurs dans une même transaction, avec annulation et erreur visible en cas d'échec. Les services déjà orphelins restent à examiner par le contrôle service_rattache prévu ultérieurement.

Exécuter la partie A seule et examiner les volumes avant de lancer séparément la partie B, commentée par défaut. Conserver dans Snowsight le repère horodaté de A et les identifiants des deux DELETE retournés par B, avant un second passage, pour le futur test Time Travel. À données et date limite inchangées, une seconde purge ne doit rien supprimer.

**Les MARTS doivent ensuite être reconstruits** pour retirer leurs copies ; cette reconstruction n'est pas incluse dans le script. Les historiques peuvent rester temporairement accessibles via Time Travel selon la rétention existante. Les cinq ans proviennent du contrat de formation et ne constituent pas une validation juridique générale. Une purge SQL ne supprime pas automatiquement toutes les copies externes ou historiques, notamment les CSV locaux. Aucun réglage Time Travel, registre final ou résultat de test n'est modifié à cette étape.

## État d'avancement

Correction Git et rédaction documentaire du jour 1 matin réalisées : quatre fiches datées, trois sources officielles proposées pour le suivi, inventaire et lecture statique du lignage. Le contrat reste inchangé.

Restent pour clôturer le matin : abonnement réel au lecteur RSS et capture par l'utilisateur, validation des questions juridiques ; le projet est réalisé individuellement. EUR-Lex n'a pas pu être lu directement (anti-robot) : texte consulté sur la CNIL ; PDF CEPD français indisponible (429), version anglaise officielle vérifiée.

Selon l'utilisateur, le jour 1 technique et les étapes 2 et 3 du jour 2 sont validés dans Snowsight. L'étape 4 documente ici le choix de conserver les colonnes et de les masquer selon le rôle ; aucun masque n'est encore appliqué par cette intervention, aucun SQL ni test Snowflake n'est exécuté. Les résultats du cahier de tests ne sont pas remplis.
