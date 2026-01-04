# =============================================================================
# 03_model_training.R
# Projet 3 : MMM avec Robyn — Entraînement du modèle
# =============================================================================

# -----------------------------------------------------------------------------
# 1. SETUP
# -----------------------------------------------------------------------------

# Charger Robyn et dépendances
library(Robyn)
library(data.table)
library(ggplot2)
library(reticulate)

# Vérifier que Nevergrad est disponible
if (!py_module_available("nevergrad")) {
  stop("Nevergrad n'est pas installé. Voir 01_SETUP_GUIDE.md")
}

# Configuration pour le parallélisme
Sys.setenv(R_FUTURE_FORK_ENABLE = "true")
options(future.fork.enable = TRUE)

# Créer le dossier pour les outputs Robyn
dir.create("outputs/robyn", showWarnings = FALSE)

# Seed pour reproductibilité
set.seed(42)

# -----------------------------------------------------------------------------
# 2. CHARGER ET PRÉPARER LES DONNÉES
# -----------------------------------------------------------------------------

# Charger les données
df <- fread("data/Sample Media Spend Data.csv")

# Convertir la date
df[, DATE := as.Date(Calendar_Week, format = "%m/%d/%Y")]

# Pour ce premier modèle, on va :
# - Sélectionner UNE division (simplifier)
# - Ou agréger toutes les divisions

# Option 1 : Sélectionner une division (recommandé pour commencer)
selected_division <- "A"  # Adapter selon les données
df_model <- df[Division == selected_division]

# Option 2 : Agréger toutes les divisions (décommenter si préféré)
# df_model <- df[, .(
#   Paid_Views = sum(Paid_Views),
#   Organic_Views = sum(Organic_Views),
#   Google_Impressions = sum(Google_Impressions),
#   Email_Impressions = sum(Email_Impressions),
#   Facebook_Impressions = sum(Facebook_Impressions),
#   Affiliate_Impressions = sum(Affiliate_Impressions),
#   Overall_Views = sum(Overall_Views),
#   Sales = sum(Sales)
# ), by = DATE]

cat("Dataset pour modélisation:\n")
cat("- Division:", selected_division, "\n")
cat("- Période:", as.character(min(df_model$DATE)), "à", as.character(max(df_model$DATE)), "\n")
cat("- Observations:", nrow(df_model), "\n")

# Vérifier les données
print(head(df_model))

# -----------------------------------------------------------------------------
# 3. CONFIGURATION ROBYN - InputCollect
# -----------------------------------------------------------------------------

# Définir les colonnes
date_var <- "DATE"
dep_var <- "Sales"
dep_var_type <- "revenue"  # ou "conversion" selon le cas

# Variables média (canaux payants avec spend/impressions)
# Robyn attend des colonnes de SPEND et optionnellement d'IMPRESSIONS
# Si tu n'as que des impressions, tu peux les utiliser comme proxy du spend

paid_media_vars <- c(
  "Google_Impressions",
  "Facebook_Impressions",
  "Affiliate_Impressions"
)

# Variables média avec spend (si disponible)
# paid_media_spends <- c("Google_Spend", "Facebook_Spend", "Affiliate_Spend")

# Pour ce dataset, on n'a que des impressions
# On va les utiliser directement (Robyn peut fonctionner avec impressions)
paid_media_spends <- paid_media_vars  # Utiliser les impressions comme proxy

# Variables organiques (pas de spend associé)
organic_vars <- c(
  "Organic_Views",
  "Email_Impressions"  # Email souvent considéré comme organique/owned
)

# Variables de contexte (optionnel)
# context_vars <- c("price", "promotion", "competitor_spend")
context_vars <- NULL

# Charger les données de vacances (Prophet)
data("dt_prophet_holidays")
holidays <- dt_prophet_holidays[dt_prophet_holidays$country == "US", ]  # Adapter le pays

# -----------------------------------------------------------------------------
# 4. CRÉER InputCollect
# -----------------------------------------------------------------------------

InputCollect <- robyn_inputs(
  dt_input = df_model,
  dt_holidays = holidays,
  date_var = date_var,
  dep_var = dep_var,
  dep_var_type = dep_var_type,
  prophet_vars = c("trend", "season", "holiday"),  # Décomposition Prophet
  prophet_country = "US",  # Adapter selon le marché
  paid_media_spends = paid_media_spends,
  paid_media_vars = paid_media_vars,
  organic_vars = organic_vars,
  context_vars = context_vars,
  window_start = min(df_model$DATE),
  window_end = max(df_model$DATE),
  adstock = "geometric"  # ou "weibull_cdf", "weibull_pdf"
)

# Afficher le résumé des inputs
print(InputCollect)

# -----------------------------------------------------------------------------
# 5. DÉFINIR LES HYPERPARAMÈTRES
# -----------------------------------------------------------------------------

# Robyn optimise automatiquement les hyperparamètres, mais on définit les bornes

# Pour chaque média, on définit :
# - thetas : decay rate pour l'adstock (0-1, plus élevé = effet plus long)
# - alphas : forme de la courbe de saturation
# - gammas : point d'inflexion de la saturation

# Valeurs par défaut recommandées
hyper_names(adstock = InputCollect$adstock, all_media = InputCollect$all_media)

# Définir les hyperparamètres
hyperparameters <- list(
  # Google
  Google_Impressions_alphas = c(0.5, 3),      # Saturation shape
  Google_Impressions_gammas = c(0.3, 1),      # Saturation inflection
  Google_Impressions_thetas = c(0, 0.3),      # Adstock decay
  
  # Facebook
  Facebook_Impressions_alphas = c(0.5, 3),
  Facebook_Impressions_gammas = c(0.3, 1),
  Facebook_Impressions_thetas = c(0, 0.3),
  
  # Affiliate
  Affiliate_Impressions_alphas = c(0.5, 3),
  Affiliate_Impressions_gammas = c(0.3, 1),
  Affiliate_Impressions_thetas = c(0, 0.3),
  
  # Organic Views
  Organic_Views_alphas = c(0.5, 3),
  Organic_Views_gammas = c(0.3, 1),
  Organic_Views_thetas = c(0, 0.3),
  
  # Email
  Email_Impressions_alphas = c(0.5, 3),
  Email_Impressions_gammas = c(0.3, 1),
  Email_Impressions_thetas = c(0, 0.3)
)

# Ajouter les hyperparamètres à InputCollect
InputCollect <- robyn_inputs(
  InputCollect = InputCollect,
  hyperparameters = hyperparameters
)

# Vérifier
print(InputCollect)

# -----------------------------------------------------------------------------
# 6. ENTRAÎNER LE MODÈLE
# -----------------------------------------------------------------------------

cat("\n=== DÉMARRAGE DE L'ENTRAÎNEMENT ===\n")
cat("Cela peut prendre plusieurs minutes...\n\n")

# Paramètres d'entraînement
# - iterations : nombre d'itérations par trial (plus = meilleur mais plus long)
# - trials : nombre de trials (explorations différentes)
# - cores : nombre de CPU à utiliser

OutputModels <- robyn_run(
  InputCollect = InputCollect,
  cores = parallel::detectCores() - 1,  # Laisser 1 core libre
  iterations = 2000,                      # Recommandé: 2000-5000
  trials = 5,                             # Recommandé: 3-5
  ts_validation = TRUE,                   # Validation time-series
  add_penalty_factor = FALSE,             # Pas de pénalité supplémentaire
  outputs = FALSE                         # On génère les outputs après
)

# Afficher les résultats
print(OutputModels)

# -----------------------------------------------------------------------------
# 7. SÉLECTIONNER LES MEILLEURS MODÈLES
# -----------------------------------------------------------------------------

# Robyn génère plusieurs modèles sur le front de Pareto
# On doit sélectionner le meilleur selon nos critères business

# Visualiser le front de Pareto
OutputCollect <- robyn_outputs(
  InputCollect = InputCollect,
  OutputModels = OutputModels,
  pareto_fronts = "auto",  # Sélection automatique
  csv_out = "pareto",      # Export CSV
  clusters = TRUE,         # Clustering des solutions
  plot_pareto = TRUE,      # Générer les plots
  plot_folder = "outputs/robyn"
)

# Afficher les modèles Pareto-optimaux
print(OutputCollect)

# -----------------------------------------------------------------------------
# 8. ANALYSER UN MODÈLE SPÉCIFIQUE
# -----------------------------------------------------------------------------

# 1. Lister les modèles disponibles
cat("\n=== MODÈLES PARETO-OPTIMAUX ===\n")
print(OutputCollect$allSolutions)

# 2. Voir les métriques détaillées de chaque modèle
print(OutputCollect$xDecompAgg[solID %in% OutputCollect$allSolutions,
                               .(solID, rn, coef, xDecompPerc, roi_total)])

# 3. Résumé par modèle (métriques clés)
OutputCollect$resultHypParam[solID %in% OutputCollect$allSolutions,
                             .(solID, nrmse, decomp.rssd, mape)]

# 4. Voir les clusters (modèles similaires regroupés)
OutputCollect$clusters

# 5. Voir le "top_sol" recommandé par cluster
OutputCollect$clusters$data[top_sol == TRUE, .(solID, cluster, nrmse, decomp.rssd)]

# Critères pour choisir :
  
#  | Métrique    | Signification               | Idéal                    |
#  |-------------|-----------------------------|--------------------------|
#  | nrmse       | Erreur de prédiction        | Plus bas = meilleur fit  |
#  | decomp.rssd | Cohérence des contributions | Plus bas = plus réaliste |
#  | roi_total   | ROI global du modèle        | À comparer au business   |
  
#  En pratique, exécute :
  # Voir les meilleurs de chaque cluster
OutputCollect$clusters$data[top_sol == TRUE]# Sélectionner le meilleur modèle (par exemple, le premier du cluster 1)

# Tu devras adapter selon les résultats
selected_model <- OutputCollect$allSolutions[52]  # Premier modèle

cat("\nModèle sélectionné:", selected_model, "\n")

# Générer les outputs détaillés pour ce modèle
robyn_onepagers(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = selected_model,
  export = TRUE
)

# -----------------------------------------------------------------------------
# 9. SAUVEGARDER LE MODÈLE
# -----------------------------------------------------------------------------

# Exporter le modèle en JSON
robyn_write(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = selected_model,
  dir = "outputs/robyn"
)

cat("\n=== ENTRAÎNEMENT TERMINÉ ===\n")
cat("Résultats sauvegardés dans: outputs/robyn/\n")
cat("Modèle sélectionné:", selected_model, "\n")
cat("Prochaine étape: 05_budget_allocator.R pour l'optimisation budget\n")
