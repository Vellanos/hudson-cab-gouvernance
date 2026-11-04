-- Exécuter avec TRANSFORMER, rôles secondaires désactivés et warehouse NYC_TAXI_WH.
-- Règle : chaque ligne de service doit être rattachée à un chauffeur présent dans RAW.
-- NOT EXISTS compte aussi les driver_id NULL ; aucun service n'est corrigé ou supprimé.
-- Seuil : 50 services ; nb_anomalies > 50 produit ALERTE et sera bloquant dans
-- la future tâche T_QUALITE. Aucun arrêt de pipeline n'est implémenté à cette étape.
SELECT COUNT(*) AS nb_anomalies
FROM NYC_TAXI.RAW.DRIVER_SHIFTS s
WHERE NOT EXISTS (
    SELECT 1
    FROM NYC_TAXI.RAW.DRIVERS d
    WHERE d.driver_id = s.driver_id
);
