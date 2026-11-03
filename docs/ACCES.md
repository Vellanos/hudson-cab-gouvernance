# Les accès — carte des droits et cahier de tests

État au 3 novembre 2026 : le jour 1 et son catalogue sont vérifiés dans Snowsight selon l'utilisateur. Les droits métier de l'étape 2 sont préparés, non exécutés par cette intervention. Le cahier de l'étape 3 fixe les attendus avant les politiques du projet.

- **Partie 1, jours 1 et 2** : actualisée pour le jour 1 et les droits métier préparés.
- **Partie 2, jour 2** : attendus renseignés ; Obtenu et Vert laissés vides.

---

## Partie 1 — Carte des droits

Après exécution puis réexécution du nouveau script 02 dans Snowsight, comparer cette carte avec ses commandes finales et celles du script 01. Vérifier notamment les propriétaires et l'absence de lecture des données RH pour `GOUVERNANCE`.

### Qui possède quoi

| Objet | Propriétaire |
|---|---|
| Tables de `RAW` et de `MARTS` | `TRANSFORMER` selon les scripts fournis ; propriété effective à confirmer, inchangée par l'étape 10 |
| Schéma `GOUVERNANCE` | `GOUVERNANCE`, après transfert par `ACCOUNTADMIN` avec conservation des droits |
| Tags | `GOUVERNANCE`, rôle qui les crée |
| Politiques de masquage | |
| Politique d'accès par ligne | |
| Table `ACCES_DEPOT` | |
| Table `QUALITE_RESULTATS` | `GOUVERNANCE`, rôle qui la crée |
| Vue `V_CATALOGUE` | |

Les lignes vides concernent les étapes ultérieures ; ces objets ne sont pas créés ici.

### Qui fait quoi, avec quel droit

| Action | Rôle qui la fait | Privilège nécessaire | Accordé par |
|---|---|---|---|
| Utiliser la base et le warehouse | `GOUVERNANCE` | `USAGE` sur `NYC_TAXI` et `NYC_TAXI_WH` | `ACCOUNTADMIN` |
| Utiliser les schémas de données, sans lire leurs tables | `GOUVERNANCE` | `USAGE` sur `NYC_TAXI.RAW` et `NYC_TAXI.MARTS` ; aucun `SELECT` accordé | `ACCOUNTADMIN` |
| Créer les tags et `QUALITE_RESULTATS` | `GOUVERNANCE` | Propriété du schéma `NYC_TAXI.GOUVERNANCE` | `ACCOUNTADMIN` transfère la propriété |
| Utiliser le schéma des tags | `TRANSFORMER` | `USAGE` sur `NYC_TAXI.GOUVERNANCE` | `GOUVERNANCE` |
| Poser un tag sur une colonne de `DIM_DRIVER` | `TRANSFORMER` (catalogue vérifié par l'utilisateur) | Propriété de la table et `APPLY` sur chacun des trois tags ; `USAGE` sur leur schéma | `GOUVERNANCE` pour les tags et leur schéma ; propriété de la table conservée |
| Créer une politique de masquage | | | |
| Attacher une politique de masquage à un tag | | | |
| Ajouter une politique d'accès par ligne à une table | | | |
| Écrire et lire les résultats de qualité | `TRANSFORMER` | `INSERT`, `SELECT` sur `NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS` | `GOUVERNANCE` |
| Créer une vue dans le schéma de gouvernance | `TRANSFORMER` (aucune vue créée ici) | `CREATE VIEW` sur `NYC_TAXI.GOUVERNANCE` | `GOUVERNANCE` |
| Disposer des droits d'attachement pour les futures politiques | `GOUVERNANCE` (aucune politique créée ou attachée ici) | `APPLY MASKING POLICY` et `APPLY ROW ACCESS POLICY` sur le compte | `ACCOUNTADMIN` |
| Lire `DIM_DRIVER` | Les quatre rôles métier, droits préparés | `USAGE` sur base et schéma MARTS, `SELECT` sur la table | `ACCOUNTADMIN` |
| Exécuter une requête de calcul avec le warehouse existant | `GOUVERNANCE` | `USAGE` sur `NYC_TAXI_WH` ; droits sur les objets nécessaires à la requête | `ACCOUNTADMIN` pour le warehouse |

`GOUVERNANCE` est attribué à l'utilisateur courant par `ACCOUNTADMIN`, sans recevoir `TRANSFORMER` ni être rattaché à `SYSADMIN`. Les rôles secondaires sont désactivés dans le script. Les droits préexistants de `TRANSFORMER` sur la base et le warehouse viennent de l'installation.

### Droits métier préparés au jour 2, étape 2

Toutes les lignes suivantes sont préparées dans `snowflake/gouvernance/02_roles_metier.sql` avec ACCOUNTADMIN ; leur exécution et leur réexécution restent manuelles.

| Rôle | Droits communs | Lecture MARTS | Catalogue futur |
|---|---|---|---|
| RH_PAIE | USAGE sur NYC_TAXI, NYC_TAXI_WH, MARTS et GOUVERNANCE | SELECT sur DIM_DRIVER, MART_DRIVER_MONTHLY et DIM_DEPOT | SELECT sur les futures vues de GOUVERNANCE |
| RESP_DEPOT_QUEENS | Mêmes USAGE | SELECT sur les trois mêmes tables ; aucune restriction de lignes créée ici | Même droit sur les futures vues |
| RESP_DEPOT_BRONX | Mêmes USAGE | SELECT sur les trois mêmes tables ; aucune restriction de lignes créée ici | Même droit sur les futures vues |
| ANALYSTE | Mêmes USAGE | SELECT sur toutes les tables existantes et futures de MARTS | Même droit sur les futures vues |

Les quatre rôles sont attribués à CURRENT_USER pour les tests. Aucun héritage de TRANSFORMER ou de GOUVERNANCE, aucun USAGE ou SELECT sur RAW/STAGING, aucun droit de modification des données, de création d'objet ou de gestion des tags n'est ajouté aux métiers. L'USAGE du schéma GOUVERNANCE ne donne pas SELECT sur ses tables ; le droit aux futures vues n'ouvre pas les vues déjà existantes. V_CATALOGUE n'est pas créée à cette étape.

Le script est additif : IF NOT EXISTS et GRANT le rendent rejouable, sans retirer d'éventuels droits ou héritages préexistants. Comparer les SHOW GRANTS et SHOW FUTURE GRANTS finaux avec cette carte ; signaler tout surplus plutôt que le corriger arbitrairement. Le filtrage par dépôt et le masquage restent à implémenter aux étapes ultérieures.


Références officielles vérifiées pour la préparation : [GRANT privileges](https://docs.snowflake.com/en/sql-reference/sql/grant-privilege), [GRANT OWNERSHIP](https://docs.snowflake.com/en/sql-reference/sql/grant-ownership), [CREATE TAG](https://docs.snowflake.com/en/sql-reference/sql/create-tag).

### Ce que cette carte permet à un rôle de défaire

`TRANSFORMER`, propriétaire des données et titulaire de `APPLY` sur les tags, pourra changer ou retirer leur affectation ; une protection reposant ensuite sur ces tags devra tenir compte de ce pouvoir. `GOUVERNANCE` pourra gérer ses règles et leur attachement avec ses privilèges de compte. Ces capacités ne sont ni testées ni utilisées ici ; acceptabilité et surveillance restent à documenter lors des étapes concernées.

---

## Partie 2 — Cahier de tests

Rédigé le 3 novembre 2026 **avant les politiques du projet**. Les résultats ci-dessous décrivent la **cible après les futures étapes de masquage et de filtrage**, pas le résultat du script de rôles seul. Aucune politique ni table ACCES_DEPOT n'est créée par cette intervention ; toutes les cases « Obtenu » et « Vert ? » restent vides.

Après le seul script 02, les quatre rôles métier ont SELECT sur les trois tables MARTS existantes : ces droits ne limitent ni les lignes par dépôt ni les valeurs en clair. Les tests de la cible seront exécutés plus tard, une fois les protections mises en place ; ne pas marquer les restrictions comme acquises après les seuls GRANT.

### Préparer chaque test manuel

Avant chaque requête : `USE SECONDARY ROLES NONE;`, puis `USE ROLE <rôle testé>;`, puis `USE WAREHOUSE NYC_TAXI_WH;`. Utiliser le rôle principal indiqué ; les rôles métier ont été attribués au même utilisateur pour les essais, sans héritage entre eux.

Propositions de représentation, à confirmer lors de la conception des politiques :

| Type ou cas | Valeur attendue si le rôle n'a pas droit au détail |
|---|---|
| Texte personnel catégorisé | `'*****'`, masque complet, sans reprendre le domaine de l'e-mail ; une source NULL reste NULL |
| Date de naissance masquée | `NULL` typé DATE ; aucune chaîne de caractères dans une colonne DATE |
| Date de naissance pour ANALYSTE | DATE correspondant au 1er janvier de l'année source, pour ne conserver que l'année ; source NULL → NULL. Il s'agit d'une représentation proposée, pas de la date de naissance réelle |
| driver_id | Identifiant interne inchangé pour les quatre rôles métier, conformément au contrat |
| Nombre, booléen ou métadonnée personnelle sans catégorie | Aucun masque décidé ici ; les restrictions éventuelles sont à clarifier, sans détourner un tag |

La décision entre supprimer une colonne et la masquer appartient à l'étape 4, hors périmètre. Les attentes de valeurs ci-dessous supposent les colonnes actuelles conservées pour tester le masquage ; si une suppression est décidée ensuite, actualiser l'attendu en « colonne absente » avant d'exécuter le test concerné.

### Lignes visibles

Les 400 chauffeurs sont vérifiables dans les 400 lignes locales de drivers.csv et dans DIM_DRIVER qui les reprend sans filtre. Les effectifs par dépôt et les volumes mensuels détaillés sont laissés « à confirmer dans Snowflake » : aucun compte de dépôt ni rattachement individuel n'est publié depuis les CSV.

| N° | Rôle | Requête | Attendu | Obtenu | Vert ? |
|---|---|---|---|---|---|
| 1 | RH_PAIE | `SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;` | 400 chauffeurs, tous les dépôts, sur le jeu actuel avant purge | | |
| 2 | RESP_DEPOT_QUEENS | Même requête | Uniquement les chauffeurs rattachés à Queens ; nombre à confirmer dans Snowflake | | |
| 3 | RESP_DEPOT_QUEENS | `SELECT DISTINCT depot FROM NYC_TAXI.MARTS.DIM_DRIVER;` | Queens seulement | | |
| 4 | RESP_DEPOT_BRONX | `SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY;` | Uniquement les lignes dont le dépôt du service est Bronx ; nombre à confirmer dans Snowflake | | |
| 5 | ANALYSTE | `SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;` | 400 chauffeurs, tous les dépôts ; le masquage ne réduit pas le nombre de lignes | | |
| 6 | GOUVERNANCE | Même requête | Accès refusé : pas de SELECT ; « aucune ligne » ne signifie pas forcément un COUNT égal à zéro | | |
| 7 | ACCOUNTADMIN | Même requête | Cible du contrat : aucune ligne RH. Si le SELECT hérité de TRANSFORMER est effectif et le futur filtre attaché, COUNT attendu égal à zéro ; sinon accès refusé. Vérifier les GRANT, sans imposer un refus artificiel | | |
| 8 | RH_PAIE | `SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS;` | Accès refusé, aucun accès direct à RAW | | |
| 9 | ANALYSTE | `SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS;` | Accès refusé, aucun accès direct à RAW | | |
| 9 bis | ACCOUNTADMIN | `SELECT first_name, email FROM NYC_TAXI.RAW.DRIVERS LIMIT 3;` | Ambiguïté à arbitrer : le texte annonce des lignes RAW héritées mais des valeurs personnelles masquées ; la matrice annonce aucune ligne RH. Aucune donnée personnelle en clair ne doit être considérée acceptable ; ne pas fixer ici un résultat unique | | |
| 13 | RESP_DEPOT_BRONX | `SELECT DISTINCT depot FROM NYC_TAXI.MARTS.DIM_DRIVER;` | Bronx seulement, aucun chauffeur de Queens | | |
| 14 | RESP_DEPOT_QUEENS | `SELECT DISTINCT depot FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY;` | Queens seulement, aucun service du Bronx | | |
| 15 | RH_PAIE, puis ANALYSTE | `SELECT DISTINCT depot FROM NYC_TAXI.MARTS.DIM_DRIVER;` | Tous les dépôts présents ; le rôle ne doit pas être limité à Queens ou Bronx | | |
| 16 | Chacun des quatre rôles métier | `SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DEPOT;` | 3 dépôts, référentiel non personnel sans filtre de lignes | | |
| 17 | Chacun des quatre rôles métier | `SELECT COUNT(*) FROM NYC_TAXI.STAGING.STG_RH__DRIVERS;` | Accès refusé à STAGING pour chacun | | |
| 18 | Chacun des quatre rôles métier | `SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS;` | Accès refusé à RAW pour chacun, y compris les responsables de dépôt | | |
| 19 | Chacun des quatre rôles métier | `SELECT COUNT(*) FROM NYC_TAXI.STAGING.STG_RH__DRIVER_SHIFTS;` | Accès refusé à STAGING pour chacun | | |

Le dépôt de DIM_DRIVER vient du rattachement du chauffeur ; le dépôt de MART_DRIVER_MONTHLY vient des services. Les transformations n'imposent pas leur égalité : tester chaque table séparément, sans déduire les services visibles du seul dépôt actuel du chauffeur.

### Valeurs visibles — cas D0003

Requête de référence pour DIM_DRIVER : `SELECT * FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE driver_id = 'D0003';`. Pour l'activité : `SELECT * FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY WHERE driver_id = 'D0003';`.

Aucune valeur individuelle du CSV n'est recopiée. Le rattachement de D0003 est **à confirmer dans Snowflake**. Dans la table suivante, Q signifie « si la ligne porte depot=Queens, sinon ligne invisible » ; B signifie la même condition pour Bronx. Pour l'activité mensuelle, Q/B s'apprécie sur le dépôt du service de chaque ligne. Un responsable ne doit jamais voir une ligne d'un autre dépôt.

Toutes les cellules de rôle de cette matrice sont des **attendus** ; elles ne constituent pas des valeurs obtenues.

| Colonne | RH_PAIE — attendu | RESP_DEPOT_QUEENS — attendu | RESP_DEPOT_BRONX — attendu | ANALYSTE — attendu | Obtenu | Vert ? |
|---|---|---|---|---|---|---|
| driver_id | Identifiant inchangé | Inchangé si Q | Inchangé si B | Identifiant inchangé | | |
| nom et prénom | Valeurs source en clair, sans les publier | En clair si Q | En clair si B | Masque texte complet | | |
| e-mail | Valeur source en clair, sans la publier | Masque texte si Q | Masque texte si B | Masque texte complet | | |
| téléphone | Valeur source en clair, sans la publier | En clair si Q | En clair si B | Masque texte complet | | |
| date de naissance | Date source en clair, sans la publier | NULL DATE si Q | NULL DATE si B | Année seule, sous la représentation DATE proposée ci-dessus | | |
| numéro de licence | Valeur source en clair, sans la publier | Masque texte si Q | Masque texte si B | Masque texte complet ; le caractère public de la licence n'autorise pas sa diffusion ici | | |
| driver_name dans MART_DRIVER_MONTHLY | Nom complet en clair, sans le publier | Nom en clair si Q | Nom en clair si B | Masque texte complet, y compris après reconstruction | | |

Les sources NULL restent NULL ; un masque ne doit pas inventer une valeur de contact. GOUVERNANCE ne peut pas lire les lignes de D0003, faute de SELECT. ACCOUNTADMIN ne doit en voir aucune dans les tables MARTS une fois le futur filtre effectif ; un refus d'accès reste possible selon les droits réels. Le cas RAW de l'administrateur reste l'ambiguïté 9 bis.

### Colonnes personnelles sans catégorie — attente à clarifier

La décision utilisateur du jour 1 conserve le vocabulaire des tags et interdit les catégories trompeuses. Elle ne décide pas de la visibilité finale de ces informations pour chaque rôle.

| Table | Colonnes non couvertes par DONNEE_PERSONNELLE | Attendu à documenter avant les tests concernés | Obtenu | Vert ? |
|---|---|---|---|---|
| RAW.DRIVERS et DIM_DRIVER | depot, hire_date, end_date ; dans DIM_DRIVER : is_active et tenure_years calculés | Accès RAW interdit aux métiers ; RH_PAIE voit le détail MARTS selon le contrat. Pour les autres rôles, le dépôt reste nécessaire au test de périmètre, mais la portée de « nom, prénom, téléphone » sur les dates et indicateurs demande clarification | | |
| RAW.DRIVER_SHIFTS et MART_DRIVER_MONTHLY | Dates/mois, dépôt, horaires, heures, courses, recettes ; nb_shifts dans le mart | Aucun masque arbitraire. L'analyse d'activité et le filtre de dépôt ne rendent pas ces données anonymes ; confirmer le détail nécessaire pour chaque rôle | | |
| Deux tables RAW | _source_file, _loaded_at | Métadonnées liées aux lignes RH, sans catégorie adaptée ; accès métiers refusé, cas administrateur à clarifier | | |

La liste exhaustive figure dans [REGISTRE.md](REGISTRE.md). Une colonne personnelle sans ce tag ne sera pas automatiquement protégée par un masquage fondé uniquement sur lui. **C20 reste partiellement couvert**. Les colonnes catégorisées, notamment driver_name, doivent respecter les attentes de masquage ci-dessus ; cela ne résout pas les autres colonnes.

### Le pipeline fonctionne toujours — tests futurs

À exécuter seulement après les futures politiques, avec les fichiers fournis et le rôle TRANSFORMER. Aucun chargement ni reconstruction n'est lancé par cette intervention.

| N° | Vérification | Attendu | Obtenu | Vert ? |
|---|---|---|---|---|
| 10 | Après relance avec TRANSFORMER : nombre de lignes de DIM_DRIVER | 400 sur le jeu actuel, avant purge ; aucune ligne perdue par un filtre appliqué au rôle des outils | | |
| 11 | RH_PAIE lit l'e-mail de D0003 après reconstruction | Même valeur que la source autorisée, à comparer uniquement dans Snowsight, sans la copier dans Git ; aucune valeur masquée matérialisée | | |
| 12 | Contrôler les politiques attachées via la requête de la section 7 du contrat | Après leur future création, mêmes protections attachées après reconstruction ; vérifier les références, pas seulement les valeurs affichées. Aucune politique du projet n'est présumée exister aujourd'hui | | |
| 20 | Refaire les tests de lignes et de valeurs avec les quatre rôles métier après reconstruction | Identiques aux cibles ci-dessus, y compris driver_name et la différence Queens/Bronx | | |
| 21 | ANALYSTE lit une future table métier de MARTS, lorsqu'une telle table sera créée dans le cadre du projet | SELECT prévu par le droit futur ; contenu soumis aux protections qui lui seront applicables. Ne pas créer une table de test supplémentaire ici | | |
| 22 | Les quatre métiers lisent V_CATALOGUE après sa création au jour 3 | SELECT prévu par les droits sur les futures vues ; la vue n'est pas créée pour ce test aujourd'hui | | |

### Ambiguïtés et conditions de validation

- **ACCOUNTADMIN** : la section 4 du contrat distingue le texte RAW hérité/masqué de la matrice « aucune ligne RH ». Les étapes de filtrage du guide visent les deux tables RH de MARTS. Demander un arbitrage sur RAW ; ne pas inventer une politique RAW ni supprimer des droits pour cacher cette divergence.
- **GOUVERNANCE** : « aucune ligne » prend ici la forme d'un accès refusé, faute de SELECT. L'USAGE des schémas de données ne donne pas la lecture.
- **Rôles métier** : RH_PAIE voit tous les dépôts et toutes les valeurs ; les responsables voient leur périmètre, avec identité et téléphone en clair ; ANALYSTE voit tous les dépôts sans identifiant direct et avec l'année de naissance seulement. Les informations non catégorisées ci-dessus restent à clarifier.
- **Exemples pédagogiques** : l'utilisateur indique leur exécution, mais le contrôle vendeur de l'exemple 03 reste à confirmer. Aucun résultat de cet exemple n'est repris comme preuve d'une protection des tables NYC_TAXI.
- **Validation** : les nombres par dépôt, l'appartenance de D0003, les droits effectifs et les ambiguïtés seront contrôlés dans Snowsight ; les cases Obtenu et Vert resteront vides jusqu'aux tests manuels appropriés.
