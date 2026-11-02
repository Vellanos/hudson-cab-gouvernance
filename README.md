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

## État d'avancement

Correction Git et rédaction documentaire du jour 1 matin réalisées : quatre fiches datées, trois sources officielles proposées pour le suivi, inventaire et lecture statique du lignage. Le contrat et les SQL fournis sont inchangés.

Restent pour clôturer le matin : abonnement réel au lecteur RSS et capture par l'utilisateur, relecture du binôme et validation des questions juridiques. EUR-Lex n'a pas pu être lu directement (anti-robot) : texte consulté sur la CNIL ; PDF CEPD français indisponible (429), version anglaise officielle vérifiée.

Le compte Snowflake est déjà créé selon l'utilisateur ; sa région et sa configuration n'ont pas été vérifiées. Aucun accès au compte, chargement, SQL, tag, politique ou test Snowflake n'a été exécuté dans cette intervention. Les parties des jours suivants sont conservées à compléter.
