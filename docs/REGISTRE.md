# Registre du traitement — données du personnel

État au 4 novembre 2026 : inventaire et fiche de registre complétés. Les observations Snowflake ci-dessous sont rapportées par l'utilisateur ; cette finalisation documentaire n'exécute aucune requête. Les scripts cités décrivent les mécanismes, sans constituer à eux seuls une preuve d'exécution.

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

Lignage décrit par les fichiers SQL ; l'alimentation du mart mensuel depuis la vue des services et DIM_DRIVER est aussi visible dans la [capture Lineage](lineage_mart_driver_monthly.png). Préfixe commun : `NYC_TAXI`. D = `RAW.DRIVERS` → `STAGING.STG_RH__DRIVERS` → `MARTS.DIM_DRIVER`. S = `RAW.DRIVER_SHIFTS` → `STAGING.STG_RH__DRIVER_SHIFTS` ; M = `MARTS.MART_DRIVER_MONTHLY`.

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

Preuves statiques : [chargement](../snowflake/rh/chargement_rh_2_copier.sql), [vue chauffeurs](../snowflake/rh/staging/stg_rh__drivers.sql), [vue services](../snowflake/rh/staging/stg_rh__driver_shifts.sql), [dimension chauffeur](../snowflake/rh/marts/dim_driver.sql), [activité mensuelle](../snowflake/rh/marts/mart_driver_monthly.sql), [référentiel dépôt](../snowflake/rh/marts/dim_depot.sql). Les CSV passent aussi par le stage temporaire prévu par le chargement ; R3 impose son nettoyage ; le stage vide a été vérifié par l'utilisateur.

Les colonnes techniques `_source_file` et `_loaded_at`, absentes des CSV, sont ajoutées au chargement et renommées `source_file` et `loaded_at` dans les vues. Elles ne sont pas conservées dans les marts fournis. Leur présence ne rend pas les lignes anonymes.

Tags de table appliqués selon les fiches de catalogue et vérifiés par l'utilisateur : `SENSIBILITE=confidentiel` pour les quatre tables RH et `interne` pour DIM_DEPOT, conformément au modèle officiel. `DUREE_CONSERVATION=5 ans après la fin du contrat` décrit R1 pour les tables RH ; sa justification juridique reste en attente (VEILLE, section 4). Les affectations versionnées dans les fiches de catalogue ont été vérifiées dans Snowsight, puis conservées après reconstruction selon l'utilisateur.

### Catalogue RH — étape 11 : couverture et limites

Les quatre fiches SQL de `snowflake/rh/catalogue/` ont été exécutées et vérifiées par l'utilisateur. RAW.DRIVERS et MARTS.DIM_DRIVER ont une description de chacune de leurs 12 colonnes ; RAW.DRIVER_SHIFTS et MARTS.MART_DRIVER_MONTHLY ont une fiche courte.

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

**Limite C20 : couverture incomplète.** Une colonne personnelle non taguée n'est pas automatiquement protégée par le masquage fondé uniquement sur DONNEE_PERSONNELLE. Les tags de table ne remplacent pas cette couverture et les tags seuls n'appliquent aucun masquage. Ce choix respecte le vocabulaire du contrat ; il ne satisfait pas entièrement C20. MASK_TEXTE et MASK_DATE sont désormais attachées à ce tag ; leur existence ne résout pas cette limite.

Les quatre tables RH reçoivent dans les fiches `SENSIBILITE=confidentiel` et `DUREE_CONSERVATION=5 ans après la fin du contrat`. Cette dernière valeur décrit R1, sans validation juridique ni mécanisme de purge. DIM_DEPOT reste non personnel et de sensibilité `interne`, selon le modèle officiel exécuté avant les quatre fiches. La chaîne de tâches est configurée chaque jour à 7 h Europe/Paris ; ses trois tâches sont suspendues en fin de test.

### Ce qui a surpris

Les recettes et horaires décrivent un chauffeur même sans son nom ; l'agrégation mensuelle par driver_id reste personnelle.
La licence publique reste un identifiant officiel. Le nom complet est recopié dans driver_name : masquer seulement les colonnes d'origine ne couvrirait pas cette copie.
Le vocabulaire des tags laisse plusieurs données personnelles sans valeur adaptée ; c'est une limite du contrat à faire valider.

---

## Partie 2 — Fiche de registre (jour 3)

Fiche réduite suivant la trame du projet. Les résultats sont les observations rapportées par l'utilisateur, pas des tests exécutés lors de cette rédaction. Les liens SQL permettent de retrouver les mécanismes et requêtes de contrôle.

### Le traitement

| Rubrique | Réponse |
|---|---|
| Nom du traitement | Gestion RH et suivi de l'activité des chauffeurs Hudson Cab Partners. Périmètre : [contrat, sections 1–2](../CONTRAT_GOUVERNANCE.md). |
| Finalité : à quoi servent ces données | Gestion de la paie, rattachement aux dépôts et analyse mensuelle des services, heures, courses et recettes ; voir les [transformations MARTS](../snowflake/rh/marts/) et la matrice du contrat. |
| Personnes concernées | Chauffeurs du jeu pédagogique annoncé fictif : 400 avant purge, 354 après ; observations rapportées et contrôles de volumes de [purge_rh.sql](../snowflake/rh/purge_rh.sql). |
| Service responsable des données | Service RH/paie pour les données du périmètre ; gestion confiée à Hudson Cab Europe à Paris selon le guide. Les responsabilités juridiques exactes entre entités restent à confirmer : [VEILLE, section 1](VEILLE.md). |

### Les données

| Catégorie de données | Colonnes concernées | Tables où elles se trouvent |
|---|---|---|
| Identité | driver_id, first_name, last_name, birth_date, tlc_license_number ; driver_name calculé | RAW.DRIVERS et MARTS.DIM_DRIVER ; driver_id et driver_name dans MARTS.MART_DRIVER_MONTHLY ; driver_id dans RAW.DRIVER_SHIFTS. Preuves : inventaire de la partie 1, [catalogue](../snowflake/rh/catalogue/) et [dimension chauffeur](../snowflake/rh/marts/dim_driver.sql). |
| Coordonnées | email, phone | RAW.DRIVERS et MARTS.DIM_DRIVER, via la [vue STAGING chauffeurs](../snowflake/rh/staging/stg_rh__drivers.sql). |
| Vie professionnelle | depot, hire_date, end_date, is_active, tenure_years ; shift_id, shift_date, start_hour, hours_worked, trips_count, revenue_usd ; activity_month, nb_shifts | RAW.DRIVERS/DRIVER_SHIFTS, MARTS.DIM_DRIVER/MART_DRIVER_MONTHLY, selon la liste détaillée de la partie 1. Preuves : [vue services](../snowflake/rh/staging/stg_rh__driver_shifts.sql), [mart mensuel](../snowflake/rh/marts/mart_driver_monthly.sql), [Lineage observé](lineage_mart_driver_monthly.png). |

Les vues STAGING lisent RAW sans copie persistante supplémentaire. DIM_DEPOT est un référentiel sans données personnelles selon le contrat. Le catalogue contient 24 colonnes des trois tables MARTS ; descriptions confirmées : DIM_DEPOT 4/4 et DIM_DRIVER 12/12. MART_DRIVER_MONTHLY conserve sa fiche courte. Preuves : [V_CATALOGUE et vérifications](../snowflake/rh/catalogue/vue_catalogue.sql), fiches de catalogue et observations rapportées.

### Qui y accède

| Rôle | Ce qu'il voit | Pourquoi il en a besoin | Preuve (requête ou test) |
|---|---|---|---|
| RH_PAIE | Tous les dépôts et valeurs RH en clair dans MARTS selon les règles ; aucun accès direct RAW/STAGING accordé | Gestion RH et paie | [Rôles](../snowflake/gouvernance/02_roles_metier.sql), [masquage](../snowflake/gouvernance/03_masquage.sql), [filtrage](../snowflake/gouvernance/04_acces_depot.sql). Avant purge : 400 chauffeurs et 914 activités observés ; détail des valeurs non documenté comme test individuel. |
| RESP_DEPOT_QUEENS | Queens seulement ; nom, prénom, téléphone et driver_name en clair ; e-mail/licence masqués et naissance NULL selon les politiques | Encadrement de son dépôt | [RAP_DEPOT](../snowflake/gouvernance/04_acces_depot.sql), [MASK_TEXTE/MASK_DATE](../snowflake/gouvernance/03_masquage.sql). Avant purge : 161 chauffeurs, 365 activités observés. Comptages après purge et valeurs individuelles non rapportés. |
| RESP_DEPOT_BRONX | Bronx seulement, mêmes règles de masquage que Queens | Encadrement de son dépôt | Mêmes scripts ; avant purge : 122 chauffeurs, 290 activités observés. Comptages après purge non rapportés. |
| ANALYSTE | Tous les dépôts ; driver_id conservé, identité directe masquée, année de naissance seule selon la politique ; catalogue lisible | Analyse sans nommer directement les chauffeurs | Après reconstruction : 354 noms et 354 e-mails masqués dans DIM_DRIVER ; 889 driver_name masqués sur 914, 25 NULL. Lecture des 24 colonnes de V_CATALOGUE confirmée. [ACCES](ACCES.md), [masquage](../snowflake/gouvernance/03_masquage.sql), [catalogue](../snowflake/rh/catalogue/vue_catalogue.sql). |
| TRANSFORMER | Sources RAW/STAGING et MARTS avec valeurs originales ; toutes les lignes autorisées | Chargement, purge, contrôles et reconstruction | [Installation](../snowflake/00_installation.sql), [politiques](../snowflake/gouvernance/03_masquage.sql), [tâches](../snowflake/rh/taches_rh.sql). Pipeline normal : trois SUCCEEDED ; MARTS reconstruits à 3/354/914. |
| GOUVERNANCE | Gère les règles et leurs correspondances ; aucun SELECT accordé sur les tables RH | Séparation entre propriétaire des données et propriétaire des règles | [Droits](../snowflake/gouvernance/01_gouvernance.sql), [politiques](../snowflake/gouvernance/03_masquage.sql) et [ACCES](ACCES.md). Refus individuel non rapporté : ne pas le déclarer testé. |
| ACCOUNTADMIN | Audit des métadonnées ; absent de RAP_DEPOT, donc aucune ligne RH MARTS selon la règle, sous réserve des droits réels ; ambiguïté RAW non résolue | Administration et traçabilité | [RAP_DEPOT](../snowflake/gouvernance/04_acces_depot.sql), [audit](../snowflake/gouvernance/06_audit.sql). Les 21 opérations d'audit rapportées ne valent pas validation de tous ses accès RH. |

Les droits sont décrits par les scripts ; les résultats précisément connus sont consignés dans [ACCES.md](ACCES.md). La présence de 11 références ACTIVE après reconstruction est confirmée, dont RAP_DEPOT sur les deux tables RH MARTS ; elle ne remplace pas les tests de chaque valeur et de chaque rôle.

### Combien de temps

| Règle | Comment elle est appliquée | Preuve |
|---|---|---|
| R1 : suppression 5 ans après la fin du contrat | Date limite dynamique incluse, end_date non NULL ; suppression des services associés puis des chauffeurs dans une transaction. Reconstruction des copies MARTS ensuite. Les services déjà orphelins restent contrôlés séparément. | [Purge](../snowflake/rh/purge_rh.sql) et [T_PURGE/T_TABLES](../snowflake/rh/taches_rh.sql). Observé : 46 chauffeurs supprimés, 400 → 354 ; aucun service associé supprimé, RAW.DRIVER_SHIFTS reste à 25 951 lignes et 25 orphelins. MARTS après reconstruction : 3 dépôts, 354 chauffeurs, 914 activités. |
| R2 : pas de restauration au-delà de 1 jour | DATA_RETENTION_TIME_IN_DAYS = 1 sur RAW.DRIVERS, RAW.DRIVER_SHIFTS, MARTS.DIM_DRIVER et MARTS.MART_DRIVER_MONTHLY, tables permanentes. STAGING ne stocke pas les données ; DIM_DEPOT est exclue. | [Conservation et SHOW PARAMETERS](../snowflake/rh/conservation_rh.sql). Réglage à 1 jour rapporté sur les quatre tables ; lecture Time Travel avant purge réussie (400 chauffeurs retrouvés). Cela ne prouve pas par un test l'impossibilité de restauration après expiration. Le minimum de compte peut augmenter la durée effective : contrôle prévu dans le script. |
| R3 : pas de fichier sur le stage | COPY INTO utilise PURGE=TRUE ; suppression des fichiers chargés, stage contrôlé vide | [Chargement](../snowflake/rh/chargement_rh_2_copier.sql) et commande de contrôle LIST sur RH_STAGE ; résultat vide rapporté par l'utilisateur. Les CSV locaux ne sont pas effacés par ce mécanisme. |

Délai réel entre l'exécution de la purge et la disparition définitive d'une donnée dans Snowflake, en tenant compte de Time Travel et de Fail-safe : **8 jours de fenêtre nominale (1 + 7), pas un délai de disparition physique garanti**. Le jour commence à la suppression dans chaque table : les copies MARTS sont retirées lors de leur reconstruction. Après le jour de Time Travel, la restauration SQL ordinaire cesse ; Fail-safe reste une récupération exceptionnelle par Snowflake, distincte de l'accès utilisateur. Une requête Time Travel longue peut retarder la transition et un minimum de rétention de compte peut prolonger la fenêtre. Les copies externes/historiques doivent être traitées séparément. Sources : [Time Travel](https://docs.snowflake.com/en/user-guide/data-time-travel), [Fail-safe](https://docs.snowflake.com/en/user-guide/data-failsafe).

### Comment on le contrôle

| Question | Réponse | Preuve |
|---|---|---|
| Peut-on dire qui a lu ces données la semaine dernière ? | Sur les sept derniers jours de la mesure rapportée : 21 opérations sur DIM_DRIVER, dont 17 SELECT et 4 INSERT, avec cinq rôles identifiés. Ce ne sont pas 21 lectures SELECT. Métadonnées seulement ; retard possible de trois heures et résultat vide non probant. | [06_audit.sql](../snowflake/gouvernance/06_audit.sql) joint ACCESS_HISTORY et QUERY_HISTORY par query_id ; [capture d'audit](audit_acces.png) disponible. |
| Sait-on quand une donnée est fausse ? | Trois contrôles sur huit, pas une garantie d'exactitude globale : licence_unique 4 / seuil 0 / ALERTE non bloquante ; telephone_renseigne 12 / 14,50 / OK ; service_rattache 25 / 50 / OK. Le seuil téléphone est 5 % des actifs, sans arrondi. Au-delà de 50 services, erreur bloquante après enregistrement des trois mesures. | [Contrôles](../snowflake/rh/controles/), [T_QUALITE](../snowflake/rh/taches_rh.sql), SELECT de QUALITE_RESULTATS dans ce script. Test observé à seuil temporaire 20 : T_QUALITE FAILED, T_TABLES non exécutée, trois mesures conservées. Seuil 50 restauré ; trois tâches SUSPENDED. Preuves : [graphe réussi](taches_execution_reussie.png), [test bloquant](taches_test_blocage.png), [QUALITE_RESULTATS au seuil normal](qualite_resultats.png) et [historique T_QUALITE](taches_historique_qualite.png). |
| Que se passe-t-il si le rôle des outils est compromis ? | TRANSFORMER peut lire les originaux, modifier/purger les données et reconstruire les MARTS ; il peut aussi modifier les affectations de tags dont il possède APPLY. La séparation des rôles limite GOUVERNANCE mais ne protège pas contre la compromission du rôle des outils lui-même. Aucune compromission simulée. | [Installation](../snowflake/00_installation.sql), [droits sur les tags](../snowflake/gouvernance/01_gouvernance.sql), exceptions des [masques](../snowflake/gouvernance/03_masquage.sql), [tâches](../snowflake/rh/taches_rh.sql). L'audit fournit une trace, sans constituer une prévention de ce risque. |

### Limites connues

C20 reste partiel : les attributs personnels sans catégorie autorisée ne sont pas couverts par le masque de tag ; l'ambiguïté administrateur/RAW demeure. Les cinq ans sont une règle du contrat de formation, sans validation juridique universelle ; Time Travel/Fail-safe et les copies empêchent d'assimiler purge SQL et disparition définitive. Un futur fichier complet peut réintroduire d'anciens chauffeurs avant la prochaine purge ; trois règles qualité sur huit seulement sont implémentées. Les captures du [graphe réussi](taches_execution_reussie.png), de la [qualité](qualite_resultats.png), de l'[audit](audit_acces.png) et du [Lineage](lineage_mart_driver_monthly.png) sont disponibles. Les abonnements [CNIL](veille_rss_cnil.png)/[CEPD](veille_rss_cepd.png) dans Inoreader et l'[alerte RGPD My EUR-Lex](veille_rss_eurlex_alerte.png) sont confirmés ; le [flux EUR-Lex](veille_rss_eurlex_flux.png) est consulté, sans réception ni test de notification confirmés. Les tests non rapportés restent ouverts dans le cahier d'accès.
