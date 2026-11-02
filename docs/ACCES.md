# Les accès — carte des droits et cahier de tests

Étape 10 : carte des droits préparée à partir de `snowflake/gouvernance/01_gouvernance.sql`. Le contexte d'installation et de chargement a été confirmé par l'utilisateur ; ce nouveau script n'a pas été exécuté ni testé dans Snowflake. Les droits ci-dessous sont prévus, pas constatés.

- **Partie 1, jours 1 et 2** : complétée uniquement pour les objets et droits de l'étape 10.
- **Partie 2, jour 2** : trame conservée, sans résultat inventé.

---

## Partie 1 — Carte des droits

Après exécution puis réexécution dans Snowsight, comparer cette carte avec les commandes finales du script. Vérifier notamment les propriétaires et l'absence de lecture des données RH pour `GOUVERNANCE`.

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
| Poser un tag sur une colonne de `DIM_DRIVER` | `TRANSFORMER` (pose non réalisée à cette étape) | Propriété de la table et `APPLY` sur chacun des trois tags ; `USAGE` sur leur schéma | `GOUVERNANCE` pour les tags et leur schéma ; propriété de la table conservée |
| Créer une politique de masquage | | | |
| Attacher une politique de masquage à un tag | | | |
| Ajouter une politique d'accès par ligne à une table | | | |
| Écrire et lire les résultats de qualité | `TRANSFORMER` | `INSERT`, `SELECT` sur `NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS` | `GOUVERNANCE` |
| Créer une vue dans le schéma de gouvernance | `TRANSFORMER` (aucune vue créée ici) | `CREATE VIEW` sur `NYC_TAXI.GOUVERNANCE` | `GOUVERNANCE` |
| Disposer des droits d'attachement pour les futures politiques | `GOUVERNANCE` (aucune politique créée ou attachée ici) | `APPLY MASKING POLICY` et `APPLY ROW ACCESS POLICY` sur le compte | `ACCOUNTADMIN` |
| Lire `DIM_DRIVER` | | | |
| Exécuter une requête de calcul avec le warehouse existant | `GOUVERNANCE` | `USAGE` sur `NYC_TAXI_WH` ; droits sur les objets nécessaires à la requête | `ACCOUNTADMIN` pour le warehouse |

`GOUVERNANCE` est attribué à l'utilisateur courant par `ACCOUNTADMIN`, sans recevoir `TRANSFORMER` ni être rattaché à `SYSADMIN`. Les rôles secondaires sont désactivés dans le script. Les droits préexistants de `TRANSFORMER` sur la base et le warehouse viennent de l'installation.

Références officielles vérifiées pour la préparation : [GRANT privileges](https://docs.snowflake.com/en/sql-reference/sql/grant-privilege), [GRANT OWNERSHIP](https://docs.snowflake.com/en/sql-reference/sql/grant-ownership), [CREATE TAG](https://docs.snowflake.com/en/sql-reference/sql/create-tag).

### Ce que cette carte permet à un rôle de défaire

`TRANSFORMER`, propriétaire des données et titulaire de `APPLY` sur les tags, pourra changer ou retirer leur affectation ; une protection reposant ensuite sur ces tags devra tenir compte de ce pouvoir. `GOUVERNANCE` pourra gérer ses règles et leur attachement avec ses privilèges de compte. Ces capacités ne sont ni testées ni utilisées ici ; acceptabilité et surveillance restent à documenter lors des étapes concernées.

---

## Partie 2 — Cahier de tests

Décidez d'abord à quoi ressemble une valeur masquée pour chaque type de colonne (texte, date) et notez-le ici : ______. Puis remplissez en deux temps : la colonne « attendu » **avant** d'écrire les politiques, à partir de la matrice du contrat ; la colonne « obtenu » après, en exécutant la requête avec le rôle indiqué (`USE ROLE ...`).

Un test est vert quand « obtenu » est identique à « attendu ». Un accès refusé (`Object does not exist or not authorized`) est un résultat comme un autre : écrivez-le.

### Lignes visibles

| N° | Rôle | Requête | Attendu | Obtenu | Vert ? |
|---|---|---|---|---|---|
| 1 | `RH_PAIE` | `SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER` | | | |
| 2 | `RESP_DEPOT_QUEENS` | la même | | | |
| 3 | `RESP_DEPOT_QUEENS` | `SELECT DISTINCT depot FROM NYC_TAXI.MARTS.DIM_DRIVER` | | | |
| 4 | `RESP_DEPOT_BRONX` | `SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY` | | | |
| 5 | `ANALYSTE` | `SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER` | | | |
| 6 | `GOUVERNANCE` | la même | | | |
| 7 | `ACCOUNTADMIN` | la même | | | |
| 8 | `RH_PAIE` | `SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS` | | | |
| 9 | `ANALYSTE` | `SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS` | | | |
| 9 bis | `ACCOUNTADMIN` | `SELECT first_name, email FROM NYC_TAXI.RAW.DRIVERS LIMIT 3` | | | |

### Valeurs visibles

Pour le chauffeur `D0003`, la valeur que chaque rôle doit lire dans chaque colonne (ou « colonne absente », ou « ligne invisible »).

| Colonne | `RH_PAIE` | `RESP_DEPOT_QUEENS` | `RESP_DEPOT_BRONX` | `ANALYSTE` |
|---|---|---|---|---|
| nom et prénom | | | | |
| e-mail | | | | |
| téléphone | | | | |
| date de naissance | | | | |
| numéro de licence | | | | |
| `driver_name` dans `MART_DRIVER_MONTHLY` | | | | |

### Le pipeline fonctionne toujours

| N° | Vérification | Attendu | Obtenu | Vert ? |
|---|---|---|---|---|
| 10 | Avec le rôle des outils, après avoir relancé les fichiers SQL : nombre de lignes de `DIM_DRIVER` | | | |
| 11 | Avec `RH_PAIE` : l'e-mail de `D0003` est toujours une vraie adresse | | | |
| 12 | Les politiques sont toujours attachées après la relance (requête de la section 7 du contrat) | | | |

Ajoutez vos propres tests : un cahier qui ne contient que des tests verts dès le premier essai n'a probablement pas cherché les cas limites.
