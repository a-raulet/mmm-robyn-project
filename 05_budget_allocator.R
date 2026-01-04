# =============================================================================
# 05_budget_allocator.R
# Projet 3 : MMM avec Robyn — Optimisation du budget marketing
# =============================================================================

# -----------------------------------------------------------------------------
# 1. SETUP
# -----------------------------------------------------------------------------

library(Robyn)
library(data.table)
library(ggplot2)
library(scales)

# Créer le dossier outputs
dir.create("outputs/optimization", showWarnings = FALSE)

# -----------------------------------------------------------------------------
# 2. CHARGER LE MODÈLE SAUVEGARDÉ
# -----------------------------------------------------------------------------

# Charger le modèle depuis le fichier JSON
json_file <- "outputs/robyn/Robyn_202601032051_init/RobynModel-models.json"

if (!file.exists(json_file)) {
  stop("Fichier JSON non trouvé. Exécute d'abord 03_model_training.R")
}

cat("Fichier modèle:", json_file, "\n")

# Charger le modèle avec robyn_recreate
RobynModel <- robyn_recreate(json_file = json_file)

InputCollect <- RobynModel$InputCollect
OutputCollect <- RobynModel$OutputCollect
select_model <- "1_119_7"  # Modèle sélectionné (meilleur équilibre NRMSE/RSSD)

cat("Modèle chargé:", select_model, "\n")
cat("Période des données:",
    as.character(InputCollect$window_start), "à",
    as.character(InputCollect$window_end), "\n")

# -----------------------------------------------------------------------------
# 3. ANALYSER LES COURBES DE RÉPONSE
# -----------------------------------------------------------------------------

cat("\n=== COURBES DE RÉPONSE ===\n")

# Les courbes de réponse montrent la relation spend → contribution
# C'est la base de l'optimisation budget

# Charger les données pareto depuis le CSV
pareto_file <- "outputs/robyn/Robyn_202601041755_init/pareto_aggregated.csv"
if (file.exists(pareto_file)) {
  pareto_data <- fread(pareto_file)
  model_params <- pareto_data[pareto_data$solID == select_model, ]
  cat("Paramètres du modèle sélectionné:\n")
  if (nrow(model_params) > 0 && all(c("rn", "coef", "xDecompPerc", "roi_mean") %in% names(model_params))) {
    print(head(model_params[, c("rn", "coef", "xDecompPerc", "roi_mean")]))
  } else {
    cat("Colonnes disponibles:", paste(names(model_params)[1:10], collapse = ", "), "...\n")
  }
} else {
  cat("Fichier pareto non trouvé, passage à l'optimisation...\n")
}

# Visualiser les courbes de saturation
# (déjà généré dans le one-pager, mais on peut les refaire)

# -----------------------------------------------------------------------------
# 4. SCÉNARIO 1 : OPTIMISER LE BUDGET ACTUEL
# -----------------------------------------------------------------------------

cat("\n=== SCÉNARIO 1: OPTIMISATION DU BUDGET ACTUEL ===\n")
cat("Question: Comment réallouer le même budget pour maximiser les ventes?\n\n")

# Définir la période pour l'allocation (toute la période)
date_range <- "all"
cat("Période d'allocation: toute la période du modèle\n")

# Lancer l'optimisation avec le budget actuel
AllocatorCollect_current <- robyn_allocator(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  date_range = date_range,
  scenario = "max_response",  # Maximiser la réponse avec le même budget
  channel_constr_low = 0.5,   # Minimum 50% du spend actuel par canal
  channel_constr_up = 2.0,    # Maximum 200% du spend actuel par canal
  export = TRUE,
  plot_folder = "outputs/optimization"
)

# Afficher les résultats
cat("\n--- Résultats de l'allocation optimale ---\n")
print(AllocatorCollect_current)

# Extraire les recommandations
allocation_results <- AllocatorCollect_current$dt_optimOut

cat("\n--- Comparaison Initial vs Optimal ---\n")
# avec data.table (bug ?)
#print(allocation_results[, .(
#  channels,
#  initSpendShare = round(initSpendShare, 3),
#  optmSpendShare = round(optmSpendShare, 3),
#  optmSpendShareDist = round(optmSpendShareDist, 3),
#  initResponseUnitShare = round(initResponseUnitShare, 3),
#  optmResponseUnitShare = round(optmResponseUnitShare, 3)
#)])

# Impression normale
print(allocation_results[, c("channels", "initSpendShare", "optmSpendShare",
                             "initResponseUnitShare", "optmResponseUnitShare")])

# Calculer le lift attendu
initial_response <- sum(allocation_results$initResponseUnit)
optimal_response <- sum(allocation_results$optmResponseUnit)
expected_lift <- (optimal_response - initial_response) / initial_response * 100

cat("\n--- Impact attendu ---\n")
cat("Réponse initiale:", format(initial_response, big.mark = ","), "\n")
cat("Réponse optimale:", format(optimal_response, big.mark = ","), "\n")
cat("Lift attendu:", round(expected_lift, 2), "%\n")

# -----------------------------------------------------------------------------
# 5. SCÉNARIO 2 : AUGMENTATION DU BUDGET (+20%)
# -----------------------------------------------------------------------------

cat("\n=== SCÉNARIO 2: AUGMENTATION DU BUDGET +20% ===\n")

# Calculer le budget actuel
current_budget <- sum(allocation_results$initSpendUnit)
increased_budget <- current_budget * 1.20

cat("Budget actuel:", format(current_budget, big.mark = ","), "\n")
cat("Budget +20%:", format(increased_budget, big.mark = ","), "\n")

AllocatorCollect_increase <- robyn_allocator(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  date_range = date_range,
  scenario = "max_response",
  total_budget = increased_budget,  # Nouveau budget
  channel_constr_low = 0.3,
  channel_constr_up = 3.0,
  export = TRUE,
  plot_folder = "outputs/optimization"
)

print(AllocatorCollect_increase)

# -----------------------------------------------------------------------------
# 6. SCÉNARIO 3 : RÉDUCTION DU BUDGET (-20%)
# -----------------------------------------------------------------------------

cat("\n=== SCÉNARIO 3: RÉDUCTION DU BUDGET -20% ===\n")

reduced_budget <- current_budget * 0.80

cat("Budget -20%:", format(reduced_budget, big.mark = ","), "\n")

AllocatorCollect_reduce <- robyn_allocator(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  date_range = date_range,
  scenario = "max_response",
  total_budget = reduced_budget,
  channel_constr_low = 0.3,
  channel_constr_up = 3.0,
  export = TRUE,
  plot_folder = "outputs/optimization"
)

print(AllocatorCollect_reduce)

# -----------------------------------------------------------------------------
# 7. SCÉNARIO 4 : ATTEINDRE UN ROI CIBLE
# -----------------------------------------------------------------------------

cat("\n=== SCÉNARIO 4: ATTEINDRE UN ROI CIBLE ===\n")

# Calculer le ROI actuel
current_roi <- initial_response / current_budget
target_roi <- current_roi * 1.10  # Viser 10% de ROI en plus

cat("ROI actuel:", round(current_roi, 4), "\n")
cat("ROI cible:", round(target_roi, 4), "\n")

AllocatorCollect_roi <- robyn_allocator(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  date_range = date_range,
  scenario = "target_efficiency",  # Atteindre une efficacité cible
  target_value = target_roi,
  channel_constr_low = 0.3,
  channel_constr_up = 3.0,
  export = TRUE,
  plot_folder = "outputs/optimization"
)

print(AllocatorCollect_roi)

# -----------------------------------------------------------------------------
# 8. CRÉER UN RAPPORT DE SYNTHÈSE
# -----------------------------------------------------------------------------

cat("\n=== GÉNÉRATION DU RAPPORT DE SYNTHÈSE ===\n")

# Compiler les résultats des différents scénarios
summary_report <- data.table(
  scenario = c("Actuel", "Optimisé (même budget)", "+20% budget", "-20% budget"),
  total_budget = c(
    current_budget,
    current_budget,
    increased_budget,
    reduced_budget
  ),
  expected_response = c(
    initial_response,
    optimal_response,
    sum(AllocatorCollect_increase$dt_optimOut$optmResponseUnit),
    sum(AllocatorCollect_reduce$dt_optimOut$optmResponseUnit)
  )
)

summary_report[, roi := expected_response / total_budget]
summary_report[, lift_vs_current := (expected_response - initial_response) / initial_response * 100]

cat("\n--- RAPPORT DE SYNTHÈSE ---\n")
print(summary_report)

# Sauvegarder le rapport
fwrite(summary_report, "outputs/optimization/budget_scenarios_summary.csv")

# -----------------------------------------------------------------------------
# 9. VISUALISATION DES RECOMMANDATIONS
# -----------------------------------------------------------------------------

# Graphique comparatif des allocations
# Convertir allocation_results (df) en data table
allocation_results_dt <- as.data.table(allocation_results)
allocation_comparison <- rbind(
  allocation_results_dt[, .(channel = channels, spend = initSpendUnit, type = "Initial")],
  allocation_results_dt[, .(channel = channels, spend = optmSpendUnit, type = "Optimal")]
)

p_allocation <- ggplot(allocation_comparison, aes(x = reorder(channel, spend), y = spend, fill = type)) +
  geom_bar(stat = "identity", position = "dodge") +
  coord_flip() +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Allocation budgétaire : Initial vs Optimal",
    subtitle = paste("Lift attendu:", round(expected_lift, 1), "%"),
    x = "Canal",
    y = "Budget",
    fill = "Scénario"
  ) +
  theme_minimal() +
  scale_fill_manual(values = c("Initial" = "gray60", "Optimal" = "steelblue"))

ggsave("outputs/optimization/allocation_comparison.png", p_allocation, width = 10, height = 6)

cat("\nVisualisation sauvegardée: outputs/optimization/allocation_comparison.png\n")

# -----------------------------------------------------------------------------
# 10. PROCHAINES ÉTAPES
# -----------------------------------------------------------------------------

cat("\n=== OPTIMISATION TERMINÉE ===\n")
cat("\nFichiers générés:\n")
cat("- outputs/optimization/budget_scenarios_summary.csv\n")
cat("- outputs/optimization/allocation_comparison.png\n")
cat("- Plots Robyn dans outputs/optimization/\n")

cat("\nProchaines étapes:\n")
cat("1. Analyser les résultats et valider avec le business\n")
cat("2. Créer le dashboard Shiny interactif (app/)\n")
cat("3. Préparer la présentation pour le portfolio\n")

