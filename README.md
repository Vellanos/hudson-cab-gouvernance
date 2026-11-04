# Hudson Cab — Snowflake et gouvernance des données

Projet de formation Simplon : documenter puis protéger un entrepôt RH de chauffeurs new-yorkais, dont la gestion est confiée à Hudson Cab Europe à Paris. Le [guide](GUIDE_BRIEF_GOUVERNANCE.md) fixe la chronologie ; le [contrat](CONTRAT_GOUVERNANCE.md) reste inchangé.

## Gouvernance

Les deux CSV RH, annoncés fictifs par le guide, restent locaux dans `data/` et sont ignorés par Git : un dépôt public ne doit pas servir à diffuser un fichier de personnel. Le commit initial a été réécrit pour les exclure de l'historique de la branche publiée. Cela ne garantit pas la disparition d'anciennes copies, caches ou clones.

Documents finalisés : [veille RGPD](docs/VEILLE.md), [inventaire et registre du traitement](docs/REGISTRE.md), [droits et cahier de tests](docs/ACCES.md). Les observations techniques ci-dessous sont rapportées par l'utilisateur après ses vérifications dans Snowsight ; aucun test n'est exécuté lors de cette rédaction.

Écarts et points à valider, détaillés dans la veille :

- **R1** : les cinq ans pour toutes les données ne sont pas justifiés par finalité ; actif et archive ne sont pas distingués. Les cinq ans du registre unique du personnel français ne s'appliquent pas automatiquement aux chauffeurs américains ([CNIL, référentiel RH de 2019, section 7](https://www.cnil.fr/sites/cnil/files/atoms/files/referentiel_grh_novembre_2019_0.pdf) ; [CNIL, conservation](https://www.cnil.fr/fr/passer-laction/les-durees-de-conservation-des-donnees)).
- **R2** : un jour est une décision interne, pas un délai du RGPD ; Time Travel ne couvre pas Fail-safe ni toutes les copies ([art. 17](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre3), [Snowflake Fail-safe](https://docs.snowflake.com/en/user-guide/data-failsafe)).
- **R3** : le stage a été vérifié vide ; la purge ne couvre pas les copies locales ou publiées ([art. 5 §1 c et f](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre2)).
- **Accès et tags** : justifier les accès étendus, les données réidentifiantes et les colonnes personnelles sans tag adapté ; clarifier l'accès administrateur ([art. 4 point 1](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre1), [art. 25 et 32](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre4)).
- **Qualité** : seuls trois des huit contrôles du contrat sont implémentés ; leurs seuils sont internes ; une alerte exige une correction suivie, même sous le seuil bloquant ([art. 5 §1 d](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre2), [art. 16](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre3)).

Catalogue RH (étape 11) vérifié dans Snowsight selon l'utilisateur ; [les quatre fiches SQL](snowflake/rh/catalogue/) restent versionnées. Seules les catégories exactes du contrat sont affectées : les dates professionnelles, dépôts, indicateurs calculés et mesures par chauffeur sans catégorie restent explicitement recensés dans le [registre](docs/REGISTRE.md). Une colonne personnelle non taguée n'est pas automatiquement protégée par un masquage fondé uniquement sur ce tag : **C20 reste partiellement couvert**. Les tags seuls ne masquent pas les données ; R1 reste à valider juridiquement.

### Jour 2, étape 4 — conserver les colonnes et masquer selon le rôle

**Décision : conserver toutes les colonnes des quatre tables RH et choisir le masquage plutôt que la suppression.** Aucun DROP COLUMN ni changement des pipelines n'est nécessaire. RH_PAIE doit garder l'ensemble des informations RH dans MARTS ; TRANSFORMER doit lire les valeurs originales nécessaires aux transformations, afin de ne pas matérialiser des masques lors de la reconstruction.

Les comportements suivants sont implémentés dans les [masques](snowflake/gouvernance/03_masquage.sql) et le [filtrage](snowflake/gouvernance/04_acces_depot.sql). Les résultats précisément rapportés sont distingués des tests restant ouverts dans ACCES.md :

- RH_PAIE : toutes les lignes et valeurs de ses tables MARTS en clair.
- RESP_DEPOT_QUEENS et RESP_DEPOT_BRONX : uniquement leur dépôt, avec nom, prénom et téléphone en clair ; e-mail, date de naissance et licence masqués. Le nom calculé driver_name suit la même règle que le nom source.
- ANALYSTE : tous les dépôts, sans identifiant direct en clair ; driver_id reste visible par exception explicite du contrat. Les mesures analytiques sont conservées pour l'analyse ; cela ne rend pas les lignes anonymes et ne tranche pas les restrictions encore ambiguës sur les attributs personnels sans catégorie.
- GOUVERNANCE : aucune lecture des données RH, faute de SELECT ; un accès refusé est attendu, pas nécessairement un comptage nul.
- ACCOUNTADMIN : aucune ligne RH dans MARTS avec RAP_DEPOT, ou accès refusé selon les droits réels. **Ambiguïté RAW conservée** : le texte du contrat prévoit des lignes héritées avec colonnes personnelles masquées, alors que la matrice annonce aucune ligne RH. Aucun accès personnel en clair n'est retenu comme cible ; l'arbitrage reste nécessaire, sans inventer une politique RAW.

Les rôles métier n'ont aucun accès direct à RAW/STAGING : conserver une colonne RAW ne leur ouvre pas sa lecture. La restriction par dépôt est distincte du masquage et s'applique aux deux tables RH de MARTS.

Pour les colonnes catégorisées, les représentations retenues dans les politiques dans [ACCES.md](docs/ACCES.md) sont conservées : texte masqué intégralement par `'*****'`, date masquée par NULL de type DATE et valeurs source NULL préservées. Pour ANALYSTE, birth_date ne doit révéler que l'année : la représentation est une DATE au 1er janvier de l'année source, sans jour ni mois réels. Aucune valeur individuelle n'est recopiée.

#### RAW.DRIVERS

| Colonne | Décision et justification |
|---|---|
| `driver_id` | Conserver : clé de rapprochement des chauffeurs et services ; catégorie identifiant_interne. L'exception métier sur driver_id ne donne pas accès à RAW. |
| `first_name` | Conserver et appliquer le masquage selon le rôle : identité nécessaire à la paie et aux responsables dans MARTS. |
| `last_name` | Conserver et appliquer le masquage selon le rôle : nom nécessaire à la paie, aux responsables et au calcul de driver_name. |
| `email` | Conserver et appliquer le masquage hors lecture autorisée : contact RH à transmettre sans altération à la paie via le pipeline. |
| `phone` | Conserver et appliquer le masquage selon le rôle : contact utile à la paie et aux responsables dans leur dépôt. |
| `birth_date` | Conserver la date originale pour la paie et TRANSFORMER ; réduire le détail à l'année pour ANALYSTE dans MARTS. |
| `tlc_license_number` | Conserver : identification officielle et contrôle d'unicité ; masquer hors lecture autorisée, même si la licence est publique. |
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
| `depot` | Conserver sans faux tag : localiser le service et filtrer son périmètre ; ne pas le confondre avec le dépôt actuel du chauffeur. |
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
| `depot` | Conserver sans faux tag : regroupement analytique et filtre sur le dépôt du service. |
| `nb_shifts` | Conserver sans faux tag : comptage mensuel utile à l'analyse ; agrégat individuel non anonyme. |
| `hours_worked` | Conserver sans faux tag : total mensuel utile au suivi RH et à l'analyse ; détail accessible par rôle à clarifier. |
| `trips_count` | Conserver sans faux tag : volume mensuel de courses nécessaire à l'analyse ; demeure rattaché au chauffeur. |
| `revenue_usd` | Conserver sans faux tag : recette mensuelle nécessaire à l'analyse ; demeure une information économique personnelle. |

Les colonnes sans catégorie adaptée restent conservées et recensées dans [REGISTRE.md](docs/REGISTRE.md), sans nouvelle valeur de tag ni affectation trompeuse. Le choix du masquage plutôt que de la suppression ne résout pas leur visibilité finale pour chaque rôle : ces limites restent celles du cahier de tests. Les masques fondés sur DONNEE_PERSONNELLE ne les couvrent pas automatiquement ; **C20 reste partiellement couvert**, malgré les politiques appliquées.


### Architecture réalisée et conservation

Le flux est CSV locaux → stage RH → RAW → vues STAGING → MARTS. Les [scripts MARTS](snowflake/rh/marts/) utilisent INSERT OVERWRITE : les tables ne sont pas recréées, ce qui conserve commentaires, tags et politiques. TRANSFORMER possède les données et exécute les traitements ; GOUVERNANCE possède les règles sans SELECT RH. Les quatre métiers lisent MARTS et V_CATALOGUE selon les [droits versionnés](snowflake/gouvernance/02_roles_metier.sql).

La [purge R1](snowflake/rh/purge_rh.sql) calcule CURRENT_DATE() moins cinq ans, borne incluse, avec end_date non NULL. R1 concerne aussi les services rattachés au chauffeur : suppression des services avant les chauffeurs, dans une transaction avec annulation en cas d'erreur. Les orphelins préexistants restent traités par le contrôle qualité. Le script manuel sépare les contrôles A de la purge B ; la tâche reprend seulement la purge. À données et limite inchangées, un rejeu ne doit supprimer aucune nouvelle ligne ; ce comportement ne vaut pas test de rejeu rapporté.

**Observations de purge et de reconstruction** : 46 chauffeurs supprimés, RAW.DRIVERS de 400 à 354 ; aucun service associé supprimé, RAW.DRIVER_SHIFTS reste à 25 951 lignes dont 25 orphelines. Les copies MARTS ont ensuite été retirées par reconstruction : DIM_DEPOT = 3, DIM_DRIVER = 354, MART_DRIVER_MONTHLY = 914. Les 11 références de politiques sont restées ACTIVE, dont RAP_DEPOT sur les deux tables RH MARTS ; tags, descriptions et masquage ont été conservés.

La [conservation R2](snowflake/rh/conservation_rh.sql) est réglée à un jour sur les quatre tables RH permanentes. La lecture Time Travel de l'état avant purge a retrouvé les 400 chauffeurs. Un jour de restauration SQL ne signifie pas disparition physique immédiate : **1 jour + 7 jours de Fail-safe** forment une fenêtre nominale, sans garantie d'effacement à huit jours. Fail-safe relève d'une récupération exceptionnelle par Snowflake ; une requête Time Travel longue ou un minimum de rétention de compte peut prolonger le délai ([documentation](https://docs.snowflake.com/en/user-guide/data-failsafe)). Chaque copie MARTS a son propre départ de rétention lors de sa suppression. Les vues STAGING ne stockent pas de copie ; DIM_DEPOT est non personnel et exclu du réglage.

R3 est appliquée par PURGE=TRUE dans le [chargement rejouable](snowflake/rh/chargement_rh_2_copier.sql) ; le stage RH_STAGE a été contrôlé vide. Une purge SQL n'efface pas les CSV locaux, clones ou autres copies éventuelles. Un fichier complet ultérieur peut réintroduire d'anciens chauffeurs avant une nouvelle purge. Les cinq ans sont imposés par le contrat de formation, sans validation juridique universelle.

### Catalogue, qualité et tâches

La [vue V_CATALOGUE](snowflake/rh/catalogue/vue_catalogue.sql) expose uniquement les métadonnées de 24 colonnes des trois tables MARTS ; ANALYSTE a confirmé sa lecture. Les quatre métiers disposent de SELECT sur la vue. Descriptions vérifiées : DIM_DEPOT 4/4 et DIM_DRIVER 12/12 ; le mart mensuel conserve volontairement une fiche courte.

Après reconstruction, les mesures de masquage ANALYSTE rapportées sont : 354 noms et 354 e-mails masqués dans DIM_DRIVER ; 889 driver_name masqués sur 914 activités, les 25 autres étant NULL. Ces nombres ne valident pas à eux seuls chaque colonne, chaque rôle ou le cas individuel D0003. Les effectifs Queens/Bronx consignés dans [ACCES.md](docs/ACCES.md) sont ceux **avant purge**, pas des comptages actuels.

Trois [règles qualité](snowflake/rh/controles/) sur les huit du contrat sont réalisées :

| Règle | Anomalies observées | Seuil mesuré | Statut et effet |
|---|---|---|---|
| licence_unique | 4 | 0 | ALERTE, non bloquante |
| telephone_renseigne | 12 | 14,50 (5 % des chauffeurs actifs, sans arrondi) | OK, non bloquante |
| service_rattache | 25 | 50 | OK ; dépassement bloquant |

Les [trois tâches](snowflake/rh/taches_rh.sql) enchaînent T_PURGE → T_QUALITE → T_TABLES, avec un horaire configuré à 7 h Europe/Paris. Le lancement normal a donné trois SUCCEEDED. T_QUALITE enregistre et valide les trois mesures dans QUALITE_RESULTATS avant de lever l'exception bloquante. Le test temporaire à seuil 20 a donné T_QUALITE FAILED, T_TABLES non exécutée, et trois mesures conservées. **Le seuil contractuel 50 a été restauré et les trois tâches sont SUSPENDED** : aucune exécution quotidienne n'est actuellement attendue.

### Audit et preuves

L'[audit](snowflake/gouvernance/06_audit.sql), sous ACCOUNTADMIN, déplie base_objects_accessed et joint QUERY_HISTORY sur query_id. Sur les sept jours de la mesure rapportée : 21 opérations sur DIM_DRIVER, dont 17 SELECT et 4 INSERT, avec cinq rôles identifiés. Il ne s'agit pas de 21 lectures SELECT. Le délai de disponibilité peut atteindre trois heures ; une sortie vide ne prouve pas l'absence d'accès.

La [capture Lineage](docs/lineage_mart_driver_monthly.png) fournie montre STG_RH__DRIVER_SHIFTS et DIM_DRIVER alimentant MART_DRIVER_MONTHLY. Aucun résultat individuel de chauffeur n'y figure.

| Capture demandée dans docs/ | État réel |
|---|---|
| Lineage | [Capture fournie](docs/lineage_mart_driver_monthly.png) |
| Graphe des tâches, lancement réussi | [Trois tâches réussies](docs/taches_execution_reussie.png) |
| QUALITE_RESULTATS | [Trois mesures au seuil normal](docs/qualite_resultats.png) |
| Audit | [21 opérations sur DIM_DRIVER](docs/audit_acces.png) |

Le [test bloquant](docs/taches_test_blocage.png) montre T_PURGE réussie, T_QUALITE en échec et T_TABLES non exécutée. L'[historique de T_QUALITE](docs/taches_historique_qualite.png) montre les deux lancements (réussi et échoué), son propriétaire TRANSFORMER, le warehouse NYC_TAXI_WH et son état suspendu ; il ne prouve pas à lui seul l'état des deux autres tâches.

La veille est configurée : abonnements [CNIL](docs/veille_rss_cnil.png) et [CEPD](docs/veille_rss_cepd.png) confirmés dans Inoreader ; [alerte RGPD](docs/veille_rss_eurlex_alerte.png) créée dans My EUR-Lex et [flux consulté](docs/veille_rss_eurlex_flux.png). Aucune réception ni aucun test de notification ne sont confirmés. Voir [VEILLE.md](docs/VEILLE.md).

L'image existante gouvernance.png est un schéma pédagogique, pas une capture de validation Snowsight.

## État d'avancement

Projet individuel : les étapes techniques des trois jours et leurs observations rapportées sont documentées dans le registre. Les tests sans résultat précis restent ouverts dans ACCES.md ; aucune validation globale du cahier de tests n'est déclarée.

Les quatre captures de validation demandées et les preuves de configuration de la veille sont disponibles. Restent ouverts les tests sans résultat précis, les validations juridiques et les arbitrages C20/administrateur RAW. La version consolidée EUR-Lex et le PDF français du CEPD restent à vérifier selon VEILLE.md ; réception et test des notifications non confirmés. La finalisation technique ne constitue pas une validation juridique du traitement.
