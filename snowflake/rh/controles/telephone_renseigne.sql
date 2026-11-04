-- Exécuter avec TRANSFORMER, rôles secondaires désactivés et warehouse NYC_TAXI_WH.
-- Règle : seuls les chauffeurs en poste (end_date IS NULL) doivent avoir un téléphone.
-- NULL, chaîne vide et chaîne composée uniquement de blancs sont des anomalies.
-- Seuil numérique à calculer lors de la mesure :
-- 0.05 * (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS WHERE end_date IS NULL)
-- Sans arrondi : nb_anomalies > seuil produit ALERTE, non bloquante.
-- Un seul résultat numérique, réutilisable dans la future tâche T_QUALITE.
SELECT COUNT(*) AS nb_anomalies
FROM NYC_TAXI.RAW.DRIVERS
WHERE end_date IS NULL
  AND (phone IS NULL OR REGEXP_LIKE(phone, '^[[:space:]]*$'));
