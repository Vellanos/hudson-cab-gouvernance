# Note de veille réglementaire — données du personnel de Hudson Cab Partners

État au 2 novembre 2026 : travail documentaire du jour 1 matin. Aucune mesure Snowflake n'a été exécutée ni vérifiée. Les données du kit sont annoncées fictives par le guide ; l'analyse porte sur le traitement RH décrit.

## 1. Le droit applicable

Le traitement : les données de chauffeurs employés à New York, gérées depuis Paris par Hudson Cab Europe, à qui le groupe a confié leur gestion.

| Question | Réponse | Source (texte et article) |
|---|---|---|
| Le RGPD s'applique-t-il à ce traitement ? | Oui, au traitement décrit, automatisé et réalisé dans le cadre de l'établissement parisien. | RGPD, art. 2 §1 et 3 §1 ; [CNIL, chapitre I](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre1). |
| Pourquoi, alors que les chauffeurs ne sont pas en Europe ? | L'art. 3 §1 vise l'établissement et ses activités. L'art. 3 §2 n'est pas le fondement retenu : le scénario ne décrit ni offre ni suivi de personnes présentes dans l'Union par une entité sans établissement européen. | Art. 3 §1 et §2 ; fiche 2. |
| Qui est responsable du traitement ? Qui est sous-traitant ? | Qualification de travail : Hudson Cab Europe, si elle décide des finalités et moyens ; Snowflake, prestataire de stockage sur instruction, sous-traitant. Le seul mandat de gestion ne prouve pas le pouvoir décisionnel : les responsabilités respectives de l'Europe et du groupe restent à confirmer par leurs accords. | Art. 4 points 7 et 8 ; art. 28 ; [chapitre I](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre1), [chapitre IV](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre4). |
| Quelle autorité de contrôle est compétente ? | La CNIL pour l'établissement français. Le statut éventuel d'autorité chef de file dépend des établissements et du caractère transfrontalier au sens du RGPD, pas du seul lien Paris–New York. | Art. 55 §1 et 56 §1 ; [chapitre VI](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre6). |

L'applicabilité du RGPD ne rend pas automatiquement applicable le droit du travail français. Les obligations américaines et les bases légales par finalité restent à établir avec le juriste. Le contrat de gouvernance interne ne constitue pas, à lui seul, une base légale au sens de l'art. 6 ([chapitre II](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre2)).

## 2. Le dispositif de veille

Dispositif proposé ; abonnements et notifications non activés.

| Source | Type (officielle, professionnelle…) | Ce qu'on y surveille | Fréquence | Outil de suivi |
|---|---|---|---|---|
| [EUR-Lex — RGPD](https://eur-lex.europa.eu/legal-content/FR/TXT/?uri=CELEX:32016R0679) | Officielle, Union européenne | Modifications et rectificatifs du règlement | Mensuelle, et après une alerte | Favori et rappel calendrier à créer ; contrôle de la version |
| [CNIL — actualités](https://www.cnil.fr/fr/actualites) | Officielle, autorité française | RH, conservation, sécurité, sanctions | Hebdomadaire | Lecteur RSS choisi par l'utilisateur, [flux fourni par le brief](https://www.cnil.fr/fr/rss.xml), abonnement à réaliser |
| [CEPD — actualités](https://www.edpb.europa.eu/news_en) | Officielle, comité européen | Lignes directrices, champ territorial et transferts | Hebdomadaire | Lecteur RSS via le bouton « RSS Feed » de la page ; abonnement à réaliser |

Responsable proposé pendant la formation : David, auteur du dépôt ; relecture par le second membre du binôme, à identifier. Dans l'organisation : référent gouvernance pour le suivi, DPO/juriste pour la validation, direction pour les décisions. Cette organisation reste à confirmer.

À faire par l'utilisateur : activer les abonnements et le rappel, tester une notification, ajouter dans `docs/` une capture sans identifiants personnels, puis obtenir la relecture croisée. Lorsqu'une nouveauté a un impact, ajouter une fiche datée et son action ici.

## 3. Les fiches de veille

### Fiche 1 — RGPD : principes applicables à l'entrepôt

- **Source** : Union européenne, règlement (UE) 2016/679 ; [EUR-Lex](https://eur-lex.europa.eu/legal-content/FR/TXT/?uri=CELEX:32016R0679), lecture vérifiée dans la [reproduction officielle CNIL](https://www.cnil.fr/fr/reglement-europeen-protection-donnees).
- **Date** : règlement du 27 avril 2016, applicable depuis le 25 mai 2018 (art. 99 §2) ; consulté le 2 novembre 2026. EUR-Lex bloqué par une vérification anti-robot : sa version consolidée n'a pas été contrôlée directement.
- **Ce que dit le texte** : les art. 5 §1 c, d, e et f imposent minimisation, exactitude, conservation limitée et confidentialité. Les art. 25 et 32 demandent des mesures adaptées et évaluées ; aucun ne prescrit cinq ans, un jour ou un seuil de cinquante anomalies.
- **Ce que cela change pour notre entrepôt** : justifier chaque colonne RH, chaque destinataire et la conservation des copies décrites dans le registre ; prévoir la vérification des accès et de l'effacement.
- **Action** : à signaler à la direction : justifications manquantes recensées en section 4. Mise en œuvre et tests hors de cette intervention.
- **Nature** : règle juridique obligatoire pour le traitement décrit.

### Fiche 2 — CEPD : l'établissement européen et l'article 3

- **Source** : CEPD, [lignes directrices 3/2018, page officielle](https://www.edpb.europa.eu/documents/guideline/guidelines-32018-on-the-territorial-scope-of-the-gdpr-article-3-version-adopted_fr) ; [PDF officiel anglais vérifié, section 1](https://www.edpb.europa.eu/sites/default/files/files/file1/edpb_guidelines_3_2018_territorial_scope_after_public_consultation_en_1.pdf).
- **Date** : adoption finale le 12 novembre 2019 ; version 2.1 du 7 janvier 2020 (mise en forme) ; consultées le 2 novembre 2026.
- **Ce que dit le texte** : l'analyse distingue établissement (art. 3 §1) et ciblage (art. 3 §2). Elle examine le lien concret entre le traitement et les activités européennes, séparément pour les acteurs concernés.
- **Ce que cela change pour notre entrepôt** : la gestion RH confiée à Paris justifie l'analyse RGPD malgré la localisation des chauffeurs ; le pays du serveur ne suffit pas à l'écarter.
- **Action** : à signaler au juriste : confirmer les décisions prises à Paris et les qualifications des entités. Le PDF français a renvoyé une erreur 429 ; sa traduction n'a pas été vérifiée.
- **Nature** : interprétation officielle du RGPD, distincte du texte législatif.

### Fiche 3 — CNIL : référentiel de gestion du personnel fourni par le brief

- **Source** : CNIL, [référentiel RH, sections 2 et 7, notamment pages 10–11](https://www.cnil.fr/sites/cnil/files/atoms/files/referentiel_grh_novembre_2019_0.pdf).
- **Date** : adopté le 21 novembre 2019 ; consulté le 2 novembre 2026. Document du brief, à confronter aux ressources plus récentes lors du suivi.
- **Ce que dit le texte** : la conservation active se distingue de l'archivage intermédiaire à accès restreint. Les cinq ans après départ figurent pour le registre unique du personnel, avec renvoi au Code du travail français, art. R. 1221-26 ; ce n'est pas une durée générale du RGPD.
- **Ce que cela change pour notre entrepôt** : R1 ne justifie pas à elle seule cinq ans de visibilité opérationnelle de toutes les coordonnées et de tous les services.
- **Action** : à signaler au juriste : valider les durées par catégorie et les obligations locales ; ne pas modifier le contrat.
- **Nature** : référentiel d'accompagnement ; les obligations des textes cités dépendent de leur applicabilité.

### Fiche 4 — CNIL : cycle de vie et durées de conservation

- **Source** : CNIL, [Les durées de conservation des données](https://www.cnil.fr/fr/passer-laction/les-durees-de-conservation-des-donnees).
- **Date** : date affichée sur la page : 2 avril 2026 ; consultée le 2 novembre 2026.
- **Ce que dit le texte** : le responsable détermine la durée selon la finalité et les obligations applicables. Un archivage intermédiaire justifié exige une séparation physique ou logique et des habilitations spécifiques ; les références nationales ne s'étendent pas automatiquement aux autres États.
- **Ce que cela change pour notre entrepôt** : distinguer les données encore utiles aux opérations de celles conservées uniquement pour une obligation ou un contentieux.
- **Action** : à signaler à la direction et au juriste : demander une politique de conservation justifiée et les accès associés.
- **Nature** : accompagnement officiel ; la limitation de conservation est une obligation de l'art. 5 §1 e.

## 4. Le contrat face aux textes

Analyse documentaire, sans verdict de conformité technique. Les durées et seuils du contrat sont des décisions internes à justifier.

| Règle du contrat | Ce que disent les textes | Source | Conforme ? | Écart et proposition |
|---|---|---|---|---|
| R1 : suppression 5 ans après la fin du contrat | Durée nécessaire à la finalité ; effacement lorsque les conditions sont réunies, avec exceptions. | Art. 5 §1 e ; [art. 17 §1 et §3](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre3) ; fiches 3–4 | Non démontré | Justification uniforme manquante ; absence de distinction actif/archive. Faire valider les durées par donnée et finalité, puis couvrir RAW, MARTS et autres copies ; ne pas transposer R. 1221-26 aux chauffeurs américains. |
| R2 : Time Travel limité à 1 jour | Aucun délai légal universel d'un jour. Une restauration technique ne vaut pas justification de conservation. | Art. 5 §1 e, 17 ; [Time Travel](https://docs.snowflake.com/en/user-guide/data-time-travel), [Fail-safe](https://docs.snowflake.com/en/user-guide/data-failsafe), consultés le 2 novembre 2026 | Objectif interne cohérent ; insuffisant pour prouver l'effacement | Pour les tables permanentes, Fail-safe prévoit encore sept jours après Time Travel, avec récupération exceptionnelle par Snowflake ; des requêtes longues peuvent retarder la transition. Faire valider les copies, sauvegardes et délais réels ; aucun réglage du compte vérifié. |
| R3 : fichier RH retiré du stage | Minimisation et sécurité, sans prescription juridique d'un stage Snowflake. | Art. 5 §1 c et f ; art. 32 ; fiche 1 | Mesure cohérente, non testée | Le SQL fourni prévoit la purge après chargement ; cela ne prouve ni le stage vide ni l'effacement des copies locales ou déjà publiées. Définir aussi leur conservation. |
| Matrice des accès (qui voit quoi) | Accès limités aux besoins, protection par défaut et sécurité adaptée. | Art. 5 §1 c et f, 25 §2, 32 ; [chapitre IV](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre4) | Partiellement justifiée sur le papier | « Tout » pour RH_PAIE et l'étendue du rôle des outils demandent justification. Identifiant interne, année de naissance et mesures mensuelles restent réidentifiants. Clarifier la contradiction apparente entre héritage administrateur sur RAW et absence de lignes RH dans la matrice. |
| Tags des colonnes personnelles | Une information rattachable à une personne reste personnelle, même sans nom. | Art. 4 point 1 ; [chapitre I](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre1) | Couverture incomplète | Aucun tag autorisé ne décrit fidèlement dépôt, dates professionnelles, horaires ou recettes. Les inventorier comme personnels ; demander une décision de protection sans inventer de valeur de tag. |
| licence_unique : 0, avertissement | Exactitude et rectification des erreurs. | Art. 5 §1 d ; [art. 16](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre3) | Contrôle utile, insuffisant | Une licence unique n'est pas forcément correcte ; prévoir le traitement de l'alerte. |
| telephone_renseigne : 5 %, avertissement | Données nécessaires et exactes. | Art. 5 §1 c et d | Seuil interne à justifier | Le RGPD n'impose pas un téléphone à chaque chauffeur ; justifier ce besoin et corriger les manquants nécessaires. |
| email_valide : 0, avertissement | Exactitude. | Art. 5 §1 d | Contrôle incomplet | La présence de @ ne prouve ni validité ni appartenance ; ne pas déclarer l'adresse vérifiée. |
| dates_coherentes : 0, avertissement | Exactitude. | Art. 5 §1 d | Contrôle utile, partiel | Des dates cohérentes peuvent être fausses ; organiser la correction à la source. |
| depot_connu : 0, avertissement | Exactitude et sécurité. | Art. 5 §1 d ; art. 32 | Contrôle utile | Une valeur erronée peut affecter le filtrage ; tracer la correction plutôt que conclure après normalisation. |
| service_rattache : 50, bloquant au-delà | Exactitude, sans seuil de tolérance légal fixé. | Art. 5 §1 d | Seuil interne à justifier | Jusqu'à cinquante services orphelins peuvent passer ; prévoir leur résolution même sous le seuil. |
| service_unique : 0, avertissement | Exactitude. | Art. 5 §1 d | Contrôle utile, partiel | La déduplication STAGING ne corrige pas RAW ; définir la résolution des doublons. |
| duree_plausible : 0, avertissement | Exactitude au regard des finalités. | Art. 5 §1 d | Contrôle utile, partiel | Seize heures est un seuil interne ; ni validation du droit du travail américain ni détection de toutes les durées erronées. |

Les huit contrôles ne prouvent pas l'exactitude globale ; aucun résultat de qualité n'a été calculé. Les propositions sont des points de validation, pas des modifications du contrat.

## 5. Ce que la veille ne tranche pas

- **Juriste/DPO et direction** : qui décide effectivement des finalités et moyens entre Hudson Cab Europe et le groupe ? Confirmer responsable, éventuelle responsabilité conjointe et contrat avec Snowflake (art. 4, 26, 28).
- **Juriste RH compétent aux États-Unis** : quelles obligations locales et durées par catégorie ? Justifier R1 et l'archivage ; le droit américain n'a pas été étudié ici.
- **DPO** : valider les bases légales par finalité (art. 6), l'information et les droits des chauffeurs (art. 13–17), ainsi que la nécessité éventuelle d'une AIPD (art. 35), sans la déclarer obligatoire à ce stade.
- **Responsable cloud et juriste** : région du compte inconnue ; vérifier aussi destinataires, accès de support, sous-traitants et flux. Un transfert hors EEE éventuel relève des [art. 44–49](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre5) ; aucun mécanisme ni certification du prestataire n'est présumé.
- **Direction et DPO** : arbitrer les tags incomplets, les habilitations étendues, les accès aux anciens chauffeurs, le traitement des alertes et l'ambiguïté administrateur.
- **Utilisateur** : contrôler directement la version EUR-Lex, le PDF français du CEPD, l'abonnement RSS et ses notifications ; ces vérifications n'ont pas été simulées.

Références pédagogiques consultées : [RESSOURCES.md du projet source](https://github.com/gsoulat/formation-data-IA/blob/main/99-Brief/Data-Engineer/Snowflake/Snowflake%2BGouvernance/RESSOURCES.md), guide, contrat et fiche juridique du dépôt. Les sources juridiques ci-dessus priment sur leur résumé pédagogique.
