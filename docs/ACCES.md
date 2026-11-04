# Les accès — carte des droits et cahier de tests

État au 4 novembre 2026 : droits, masquage et filtrage mis en place selon les scripts versionnés et les vérifications rapportées par l'utilisateur. Ce document conserve les attendus écrits avant les politiques ; seuls les tests précisément rapportés reçoivent un résultat. Aucun test Snowflake n'est exécuté pour cette finalisation.

- **Partie 1** : carte des droits de l'implémentation ; les propriétaires sont ceux définis par les scripts, sans nouveau contrôle de propriété.
- **Partie 2** : mesures avant/après purge séparées. Une case vide signifie « résultat précis non rapporté », pas « échec ».

---

## Partie 1 — Carte des droits

Références : scripts 00 à 04 et vue catalogue versionnés. Les SHOW GRANTS des scripts 01/02 permettent de revérifier cette carte ; aucun SELECT RH n'est accordé à GOUVERNANCE.

### Qui possède quoi

| Objet | Propriétaire |
|---|---|
| Tables de `RAW` et de `MARTS` | `TRANSFORMER` selon les scripts fournis ; propriété définie par les scripts, sans contrôle supplémentaire lors de cette rédaction |
| Schéma `GOUVERNANCE` | `GOUVERNANCE`, après transfert par `ACCOUNTADMIN` avec conservation des droits |
| Tags | `GOUVERNANCE`, rôle qui les crée |
| Politiques de masquage | GOUVERNANCE : MASK_TEXTE et MASK_DATE (script 03) |
| Politique d'accès par ligne | GOUVERNANCE, propriétaire de RAP_DEPOT définie dans 04_acces_depot.sql |
| Table `ACCES_DEPOT` | GOUVERNANCE, propriétaire de la table définie dans 04_acces_depot.sql |
| Table `QUALITE_RESULTATS` | `GOUVERNANCE`, rôle qui la crée |
| Vue `V_CATALOGUE` | TRANSFORMER, créateur de la vue |
| T_PURGE, T_QUALITE, T_TABLES | TRANSFORMER, créateur des tâches |

Les objets sont créés ; la séparation des propriétaires des données et des règles est conservée après les reconstructions rapportées.

### Qui fait quoi, avec quel droit

| Action | Rôle qui la fait | Privilège nécessaire | Accordé par |
|---|---|---|---|
| Utiliser la base et le warehouse | `GOUVERNANCE` | `USAGE` sur `NYC_TAXI` et `NYC_TAXI_WH` | `ACCOUNTADMIN` |
| Utiliser les schémas de données, sans lire leurs tables | `GOUVERNANCE` | `USAGE` sur `NYC_TAXI.RAW` et `NYC_TAXI.MARTS` ; aucun `SELECT` accordé | `ACCOUNTADMIN` |
| Créer les tags et `QUALITE_RESULTATS` | `GOUVERNANCE` | Propriété du schéma `NYC_TAXI.GOUVERNANCE` | `ACCOUNTADMIN` transfère la propriété |
| Utiliser le schéma des tags | `TRANSFORMER` | `USAGE` sur `NYC_TAXI.GOUVERNANCE` | `GOUVERNANCE` |
| Poser un tag sur une colonne de `DIM_DRIVER` | `TRANSFORMER` (catalogue vérifié par l'utilisateur) | Propriété de la table et `APPLY` sur chacun des trois tags ; `USAGE` sur leur schéma | `GOUVERNANCE` pour les tags et leur schéma ; propriété de la table conservée |
| Créer une politique de masquage | GOUVERNANCE | Propriété du schéma GOUVERNANCE, CREATE MASKING POLICY | ACCOUNTADMIN transfère le schéma |
| Attacher une politique de masquage à un tag | GOUVERNANCE | Propriété du tag et APPLY MASKING POLICY sur le compte | ACCOUNTADMIN pour APPLY ; tag créé par GOUVERNANCE |
| Ajouter une politique d'accès par ligne à une table | `GOUVERNANCE`, attachements appliqués sur DIM_DRIVER et MART_DRIVER_MONTHLY | `APPLY ROW ACCESS POLICY` sur le compte, sans SELECT RH | `ACCOUNTADMIN` au jour 1 |
| Écrire et lire les résultats de qualité | `TRANSFORMER` | `INSERT`, `SELECT` sur `NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS` | `GOUVERNANCE` |
| Créer une vue dans le schéma de gouvernance | `TRANSFORMER` (V_CATALOGUE créée) | `CREATE VIEW` sur `NYC_TAXI.GOUVERNANCE` | `GOUVERNANCE` |
| Disposer des droits d'attachement des politiques | `GOUVERNANCE` (politiques créées et attachées) | `APPLY MASKING POLICY` et `APPLY ROW ACCESS POLICY` sur le compte | `ACCOUNTADMIN` |
| Lire `DIM_DRIVER` | Les quatre rôles métier | `USAGE` sur base et schéma MARTS, `SELECT` sur la table | `ACCOUNTADMIN` |
| Exécuter une requête de calcul avec le warehouse existant | `GOUVERNANCE` | `USAGE` sur `NYC_TAXI_WH` ; droits sur les objets nécessaires à la requête | `ACCOUNTADMIN` pour le warehouse |
| Créer et exécuter la chaîne RH | TRANSFORMER | CREATE TASK sur MARTS, EXECUTE TASK sur le compte ; droits de lecture/écriture existants | ACCOUNTADMIN, script 00 ; GOUVERNANCE pour QUALITE_RESULTATS |
| Auditer les accès RH | ACCOUNTADMIN | Lecture des vues SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY et QUERY_HISTORY avec ses droits existants | Aucun nouveau GRANT ; script 06_audit.sql |

`GOUVERNANCE` est attribué à l'utilisateur courant par `ACCOUNTADMIN`, sans recevoir `TRANSFORMER` ni être rattaché à `SYSADMIN`. Les rôles secondaires sont désactivés dans le script. Les droits préexistants de `TRANSFORMER` sur la base et le warehouse viennent de l'installation.

### Droits métier — jour 2, étape 2

Les lignes suivantes sont définies dans [02_roles_metier.sql](../snowflake/gouvernance/02_roles_metier.sql), exécuté et rejoué par l'utilisateur avec ACCOUNTADMIN.

| Rôle | Droits communs | Lecture MARTS | Catalogue |
|---|---|---|---|
| RH_PAIE | USAGE sur NYC_TAXI, NYC_TAXI_WH, MARTS et GOUVERNANCE | SELECT sur DIM_DRIVER, MART_DRIVER_MONTHLY et DIM_DEPOT | SELECT sur les futures vues de GOUVERNANCE |
| RESP_DEPOT_QUEENS | Mêmes USAGE | SELECT sur les trois mêmes tables ; restriction de lignes par RAP_DEPOT, distincte des GRANT | Même droit sur les futures vues |
| RESP_DEPOT_BRONX | Mêmes USAGE | SELECT sur les trois mêmes tables ; restriction de lignes par RAP_DEPOT, distincte des GRANT | Même droit sur les futures vues |
| ANALYSTE | Mêmes USAGE | SELECT sur toutes les tables existantes et futures de MARTS | Même droit sur les futures vues |

Les quatre rôles sont attribués à CURRENT_USER pour les tests. Aucun héritage de TRANSFORMER ou de GOUVERNANCE, aucun USAGE ou SELECT sur RAW/STAGING, aucun droit de modification des données, de création d'objet ou de gestion des tags n'est ajouté aux métiers. L'USAGE du schéma GOUVERNANCE ne donne pas SELECT sur ses tables ; le droit aux futures vues n'ouvre pas les vues déjà existantes. V_CATALOGUE est maintenant créée ; ANALYSTE en a confirmé la lecture, et les quatre métiers disposent de SELECT.

Le script est additif : IF NOT EXISTS et GRANT le rendent rejouable, sans retirer d'éventuels droits ou héritages préexistants. Comparer les SHOW GRANTS et SHOW FUTURE GRANTS finaux avec cette carte ; signaler tout surplus plutôt que le corriger arbitrairement. Les rôles métier et leurs droits sont validés selon l'utilisateur. Le masquage et le filtrage des scripts 03/04 sont en place ; les résultats précis connus figurent en partie 2.


### Contrôle par dépôt — étape 6 réalisée

Le [script 04](../snowflake/gouvernance/04_acces_depot.sql) définit les correspondances et RAP_DEPOT sous GOUVERNANCE ; son fonctionnement a été vérifié par l'utilisateur.

| Objet ou action | Rôle et droits |
|---|---|
| Créer et alimenter ACCES_DEPOT | GOUVERNANCE, propriétaire du schéma puis de la table ; chargement des cinq correspondances par INSERT OVERWRITE, sans doublons à la réexécution |
| Créer et actualiser RAP_DEPOT | GOUVERNANCE, propriétaire du schéma puis de la politique ; signature VARCHAR → BOOLEAN, initialisation restrictive puis ALTER SET BODY |
| Lire ACCES_DEPOT pour évaluer la politique | Droits du propriétaire de la politique, GOUVERNANCE ; aucun SELECT accordé aux rôles métier sur la table de correspondance |
| Attacher RAP_DEPOT aux deux tables MARTS | GOUVERNANCE, avec APPLY ROW ACCESS POLICY sur le compte accordé au jour 1 ; aucun SELECT RH supplémentaire |
| Lire les données RH | Privilèges de lecture existants, limités ensuite par la politique selon CURRENT_ROLE() ; les rôles secondaires ou hérités ne déterminent pas la correspondance |

Correspondances appliquées : TRANSFORMER, RH_PAIE et ANALYSTE → `*` (tous les dépôts) ; RESP_DEPOT_QUEENS → Queens ; RESP_DEPOT_BRONX → Bronx. Aucun droit de ligne pour un rôle absent, dont ACCOUNTADMIN, SYSADMIN et GOUVERNANCE. Le refus de SELECT pour GOUVERNANCE reste distinct d'un filtre qui renvoie zéro ligne.

La même RAP_DEPOT est appliquée sur `DIM_DRIVER.depot` et `MART_DRIVER_MONTHLY.depot`, chacune avec son propre dépôt ; DIM_DEPOT reste non filtrée. Les droits de TRANSFORMER doivent préserver toutes les lignes et les valeurs originales pour reconstruire le mart avec les vrais noms.

L'attachement est ajouté seulement s'il n'existe pas de politique de lignes ; s'il correspond déjà à RAP_DEPOT sur la seule colonne DEPOT, il est conservé. Toute autre politique ou colonne déclenche une erreur visible, sans détachement. Après reconstruction, les 11 références sont ACTIVE, dont les deux attachements de RAP_DEPOT, selon l'utilisateur.

Les limites **C20 partiel** et **ACCOUNTADMIN/RAW** demeurent. La partie 2 consigne seulement les observations précises rapportées ; la reconstruction et la conservation des protections sont confirmées, sans valider tous les tests individuels.

Références officielles vérifiées pour la préparation : [GRANT privileges](https://docs.snowflake.com/en/sql-reference/sql/grant-privilege), [GRANT OWNERSHIP](https://docs.snowflake.com/en/sql-reference/sql/grant-ownership), [CREATE TAG](https://docs.snowflake.com/en/sql-reference/sql/create-tag).

### Ce que cette carte permet à un rôle de défaire

`TRANSFORMER`, propriétaire des données et titulaire de `APPLY` sur les tags, peut changer ou retirer leur affectation ; la protection par tag doit tenir compte de ce pouvoir. `GOUVERNANCE` peut gérer ses règles et leur attachement avec ses privilèges de compte. Ces capacités ne sont ni testées ni utilisées ici ; acceptabilité et surveillance restent des limites de cette séparation.

---

## Partie 2 — Cahier de tests

Rédigé le 3 novembre 2026 **avant les politiques du projet**, puis actualisé après les vérifications rapportées. Les GRANT seuls ne limitent ni les lignes ni les valeurs : les protections résultent des politiques 03/04. Les attentes initiales sont conservées ; les résultats ne sont pas déduits des seuls scripts.

Observations de périmètre **avant purge** :

| Rôle | DIM_DRIVER | MART_DRIVER_MONTHLY |
|---|---|---|
| RESP_DEPOT_QUEENS | 161 chauffeurs | 365 activités |
| RESP_DEPOT_BRONX | 122 chauffeurs | 290 activités |
| RH_PAIE | 400 chauffeurs | 914 activités |
| ANALYSTE | 400 chauffeurs | 914 activités |

Après purge et reconstruction : DIM_DRIVER = 354, MART_DRIVER_MONTHLY = 914, DIM_DEPOT = 3. Aucun nouvel effectif par dépôt n'a été rapporté ; les nombres 161/122/365/290 ne sont donc pas présentés comme des résultats actuels.

### Préparer chaque test manuel

Avant chaque requête : `USE SECONDARY ROLES NONE;`, puis `USE ROLE <rôle testé>;`, puis `USE WAREHOUSE NYC_TAXI_WH;`. Utiliser le rôle principal indiqué ; les rôles métier ont été attribués au même utilisateur pour les essais, sans héritage entre eux.

Représentations implémentées dans le script 03 ; leur description ne vaut pas test individuel de chaque cellule :

| Type ou cas | Valeur attendue si le rôle n'a pas droit au détail |
|---|---|
| Texte personnel catégorisé | `'*****'`, masque complet, sans reprendre le domaine de l'e-mail ; une source NULL reste NULL |
| Date de naissance masquée | `NULL` typé DATE ; aucune chaîne de caractères dans une colonne DATE |
| Date de naissance pour ANALYSTE | DATE correspondant au 1er janvier de l'année source, pour ne conserver que l'année ; source NULL → NULL. Il s'agit d'une représentation de l'année, pas de la date de naissance réelle |
| driver_id | Identifiant interne inchangé pour les quatre rôles métier, conformément au contrat |
| Nombre, booléen ou métadonnée personnelle sans catégorie | Aucun masque décidé ici ; les restrictions éventuelles sont à clarifier, sans détourner un tag |

Décision de l'étape 4 : conserver les colonnes et masquer selon le rôle, sans DROP COLUMN ni modification des transformations. Voir le README pour les justifications par colonne.

### Lignes visibles

Les 400 chauffeurs et les effectifs par dépôt ci-dessous ont été observés avant purge. Les attentes actuelles sont de 354 chauffeurs tous dépôts après reconstruction ; les effectifs actuels par dépôt restent à mesurer.

| N° | Rôle | Requête | Attendu | Obtenu | Vert ? |
|---|---|---|---|---|---|
| 1 | RH_PAIE | `SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;` | 400 avant purge ; 354 attendus après purge/reconstruction | 400 avant purge ; pas de nouvelle mesure RH_PAIE rapportée | Oui, avant purge seulement |
| 2 | RESP_DEPOT_QUEENS | Même requête | Uniquement les chauffeurs rattachés à Queens ; 161 avant purge ; après purge à confirmer | 161 avant purge | Oui, avant purge seulement |
| 3 | RESP_DEPOT_QUEENS | `SELECT DISTINCT depot FROM NYC_TAXI.MARTS.DIM_DRIVER;` | Queens seulement | | |
| 4 | RESP_DEPOT_BRONX | `SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY;` | Uniquement les lignes dont le dépôt du service est Bronx ; 290 avant purge ; après purge à confirmer | 290 avant purge | Oui, avant purge seulement |
| 5 | ANALYSTE | `SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;` | 400 avant purge ; 354 après purge ; le masquage ne réduit pas les lignes | 400 avant purge ; 354 après reconstruction (contrôle de masquage rapporté) | Oui pour ces volumes |
| 6 | GOUVERNANCE | Même requête | Accès refusé : pas de SELECT ; « aucune ligne » ne signifie pas forcément un COUNT égal à zéro | | |
| 7 | ACCOUNTADMIN | Même requête | Cible du contrat : aucune ligne RH. Si le SELECT hérité de TRANSFORMER est effectif et RAP_DEPOT attachée, COUNT attendu égal à zéro ; sinon accès refusé. Vérifier les GRANT, sans imposer un refus artificiel | | |
| 8 | RH_PAIE | `SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS;` | Accès refusé, aucun accès direct à RAW | | |
| 9 | ANALYSTE | `SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS;` | Accès refusé, aucun accès direct à RAW | Accès RAW refusé, validation rapportée au jour 2 | Oui, test rapporté |
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
| date de naissance | Date source en clair, sans la publier | NULL DATE si Q | NULL DATE si B | Année seule, sous la représentation DATE retenue ci-dessus | | |
| numéro de licence | Valeur source en clair, sans la publier | Masque texte si Q | Masque texte si B | Masque texte complet ; le caractère public de la licence n'autorise pas sa diffusion ici | | |
| driver_name dans MART_DRIVER_MONTHLY | Nom complet en clair, sans le publier | Nom en clair si Q | Nom en clair si B | Masque texte complet, y compris après reconstruction | | |

Les sources NULL restent NULL ; un masque ne doit pas inventer une valeur de contact. GOUVERNANCE ne peut pas lire les lignes de D0003, faute de SELECT. ACCOUNTADMIN ne doit en voir aucune dans les tables MARTS avec RAP_DEPOT ; un refus d'accès reste possible selon les droits réels. Le cas RAW de l'administrateur reste l'ambiguïté 9 bis.

### Colonnes personnelles sans catégorie — attente à clarifier

La décision utilisateur du jour 1 conserve le vocabulaire des tags et interdit les catégories trompeuses. Elle ne décide pas de la visibilité finale de ces informations pour chaque rôle.

| Table | Colonnes non couvertes par DONNEE_PERSONNELLE | Attendu à documenter avant les tests concernés | Obtenu | Vert ? |
|---|---|---|---|---|
| RAW.DRIVERS et DIM_DRIVER | depot, hire_date, end_date ; dans DIM_DRIVER : is_active et tenure_years calculés | Accès RAW interdit aux métiers ; RH_PAIE voit le détail MARTS selon le contrat. Pour les autres rôles, le dépôt reste nécessaire au test de périmètre, mais la portée de « nom, prénom, téléphone » sur les dates et indicateurs demande clarification | | |
| RAW.DRIVER_SHIFTS et MART_DRIVER_MONTHLY | Dates/mois, dépôt, horaires, heures, courses, recettes ; nb_shifts dans le mart | Aucun masque arbitraire. L'analyse d'activité et le filtre de dépôt ne rendent pas ces données anonymes ; confirmer le détail nécessaire pour chaque rôle | | |
| Deux tables RAW | _source_file, _loaded_at | Métadonnées liées aux lignes RH, sans catégorie adaptée ; accès métiers refusé, cas administrateur à clarifier | | |

La liste exhaustive figure dans [REGISTRE.md](REGISTRE.md). Une colonne personnelle sans ce tag n'est pas automatiquement protégée par un masquage fondé uniquement sur lui. **C20 reste partiellement couvert**. Les colonnes catégorisées, notamment driver_name, doivent respecter les attentes de masquage ci-dessus ; cela ne résout pas les autres colonnes.

### Le pipeline fonctionne toujours — résultats connus et tests ouverts

Reconstruction effectuée avec TRANSFORMER selon l'utilisateur. Les mesures connues sont consignées ci-dessous ; aucun chargement ni reconstruction n'est lancé lors de cette rédaction.

| N° | Vérification | Attendu | Obtenu | Vert ? |
|---|---|---|---|---|
| 10 | Après relance avec TRANSFORMER : nombre de lignes de DIM_DRIVER | 354 après purge et reconstruction ; aucune ligne perdue par le filtrage du rôle des outils | 354 après reconstruction | Oui |
| 11 | RH_PAIE lit l'e-mail de D0003 après reconstruction | Même valeur que la source autorisée, à comparer uniquement dans Snowsight, sans la copier dans Git ; aucune valeur masquée matérialisée | | |
| 12 | Contrôler les politiques attachées via la requête de la section 7 du contrat | Protections conservées après reconstruction ; références ACTIVE | 11 références ACTIVE, dont RAP_DEPOT sur DIM_DRIVER et MART_DRIVER_MONTHLY | Oui pour les références |
| 20 | Refaire les tests de lignes et de valeurs avec les quatre rôles métier après reconstruction | Identiques aux cibles ci-dessus, y compris driver_name et la différence Queens/Bronx ; adapter les volumes à l'après-purge | | |
| 21 | ANALYSTE lit une future table métier de MARTS, lorsqu'une telle table sera créée dans le cadre du projet | SELECT prévu par le droit futur ; contenu soumis aux protections qui lui seront applicables. Ne pas créer une table de test supplémentaire ici | | |
| 22 | Les quatre métiers lisent V_CATALOGUE | SELECT sur V_CATALOGUE pour les quatre métiers ; 24 colonnes de trois tables | ANALYSTE : lecture des 24 colonnes confirmée ; SELECT accordé aux quatre métiers, lectures des trois autres non rapportées | Partiel : ANALYSTE validé |

### Masquage et chaîne de tâches — observations après reconstruction

Résultats rapportés globalement, sans données individuelles ni résultat attribué au cas D0003 :

| Contrôle | Résultat observé | Preuve versionnée ou contrôle à retrouver |
|---|---|---|
| ANALYSTE, noms et e-mails de DIM_DRIVER | 354 noms et 354 e-mails masqués | [03_masquage.sql](../snowflake/gouvernance/03_masquage.sql) ; mesures agrégées rapportées, requête exacte de comptage non fournie |
| ANALYSTE, driver_name dans MART_DRIVER_MONTHLY | 889 masqués / 914 lignes ; 25 NULL | Même script ; vérification agrégée rapportée après reconstruction |
| Catalogue | ANALYSTE lit 24 colonnes ; descriptions DIM_DEPOT 4/4, DIM_DRIVER 12/12 | [vue_catalogue.sql](../snowflake/rh/catalogue/vue_catalogue.sql) ; fiche courte conservée pour MART_DRIVER_MONTHLY |
| Qualité au seuil normal | licence_unique : 4 / 0 / ALERTE ; telephone_renseigne : 12 / 14,50 / OK ; service_rattache : 25 / 50 / OK | [Contrôles RAW](../snowflake/rh/controles/) et QUALITE_RESULTATS, consultable via [taches_rh.sql](../snowflake/rh/taches_rh.sql) |
| Lancement normal | T_PURGE, T_QUALITE, T_TABLES : trois SUCCEEDED | TASK_HISTORY, requête de taches_rh.sql |
| Lancement bloquant, seuil temporaire 20 | T_QUALITE FAILED ; T_TABLES non exécutée sur ce lancement ; trois mesures qualité conservées | Même script ; COMMIT des résultats avant exception |
| État final | Seuil contractuel 50 restauré ; trois tâches SUSPENDED | GET_DDL et SHOW TASKS prévus dans taches_rh.sql |

Le test spécifique de conservation des e-mails RH_PAIE de D0003 (n° 11) reste sans résultat précis rapporté. Les succès de reconstruction et de masquage ci-dessus ne le remplacent pas. Les captures du graphe réussi, de QUALITE_RESULTATS et de l'audit restent à ajouter ; seule la [capture Lineage](lineage_mart_driver_monthly.png) est fournie.

### Ambiguïtés et conditions de validation

- **ACCOUNTADMIN** : la section 4 du contrat distingue le texte RAW hérité/masqué de la matrice « aucune ligne RH ». Les étapes de filtrage du guide visent les deux tables RH de MARTS. Demander un arbitrage sur RAW ; ne pas inventer une politique RAW ni supprimer des droits pour cacher cette divergence.
- **GOUVERNANCE** : « aucune ligne » prend ici la forme d'un accès refusé, faute de SELECT. L'USAGE des schémas de données ne donne pas la lecture.
- **Rôles métier** : RH_PAIE voit tous les dépôts et toutes les valeurs ; les responsables voient leur périmètre, avec identité et téléphone en clair ; ANALYSTE voit tous les dépôts sans identifiant direct et avec l'année de naissance seulement. Les informations non catégorisées ci-dessus restent à clarifier.
- **Exemples pédagogiques** : l'utilisateur indique leur exécution, mais le contrôle vendeur de l'exemple 03 reste à confirmer. Aucun résultat de cet exemple n'est repris comme preuve d'une protection des tables NYC_TAXI.
- **Validation** : D0003, les effectifs par dépôt après purge et les autres cellules sans résultat précis restent à confirmer dans Snowsight. Les résultats de volume ou les références ACTIVE ne valident pas arbitrairement les tests de valeurs ou de refus de chaque rôle.
