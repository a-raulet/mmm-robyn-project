# =============================================================================
# 02_data_exploration.R
# Projet 3 : MMM avec Robyn — Exploration des données
# =============================================================================

# -----------------------------------------------------------------------------
# 1. SETUP
# -----------------------------------------------------------------------------

# Charger les packages nécessaires
library(data.table)
library(ggplot2)
library(dplyr)
library(tidyr)
library(lubridate)
library(scales)
library(corrplot)

# Créer les dossiers de travail
dir.create("data", showWarnings = FALSE)
dir.create("outputs", showWarnings = FALSE)
dir.create("outputs/exploration", showWarnings = FALSE)

# -----------------------------------------------------------------------------
# 2. TÉLÉCHARGER LES DONNÉES
# -----------------------------------------------------------------------------

# Dataset : Sample Media Spends Data (Kaggle)
# https://www.kaggle.com/datasets/yugagrawal95/sample-media-spends-data
# 
# Tu dois télécharger le fichier manuellement depuis Kaggle :
# 1. Va sur https://www.kaggle.com/datasets/yugagrawal95/sample-media-spends-data
# 2. Clique sur "Download" 
# 3. Place le fichier CSV dans le dossier "data/"
#
# Alternative : utiliser l'API Kaggle (si configurée)
# system("kaggle datasets download -d yugagrawal95/sample-media-spends-data -p data/ --unzip")

# Chemin vers les données
DATA_PATH <- "data/Sample Media Spend Data.csv"

# Vérifier que le fichier existe
if (!file.exists(DATA_PATH)) {
  stop(paste(
    "Le fichier de données n'existe pas à :", DATA_PATH, "\n",
    "Télécharge-le depuis Kaggle et place-le dans le dossier 'data/'"
  ))
}

# -----------------------------------------------------------------------------
# 3. CHARGER ET INSPECTER LES DONNÉES
# -----------------------------------------------------------------------------

# Charger les données
df <- fread(DATA_PATH)

# Aperçu initial
cat("=== APERÇU DES DONNÉES ===\n")
cat("Dimensions:", nrow(df), "lignes x", ncol(df), "colonnes\n\n")

cat("Colonnes:\n")
print(names(df))

cat("\nTypes de données:\n")
print(sapply(df, class))

cat("\nPremières lignes:\n")
print(head(df, 10))

cat("\nDernières lignes:\n")
print(tail(df, 10))

# -----------------------------------------------------------------------------
# 4. COMPRENDRE LA STRUCTURE DES DONNÉES
# -----------------------------------------------------------------------------

cat("\n=== STRUCTURE DES DONNÉES ===\n")

# Statistiques descriptives
cat("\nStatistiques descriptives:\n")
print(summary(df))

# Vérifier les valeurs manquantes
cat("\nValeurs manquantes par colonne:\n")
print(colSums(is.na(df)))

# Identifier les colonnes clés attendues pour un MMM :
# - Date/Time : pour la dimension temporelle
# - Division/Segment : pour segmenter si multi-division
# - Media channels : impressions, views, spend
# - Sales : variable cible (KPI)

# -----------------------------------------------------------------------------
# 5. ANALYSE TEMPORELLE
# -----------------------------------------------------------------------------

cat("\n=== ANALYSE TEMPORELLE ===\n")

# Identifier la colonne de date (adapter selon le nom réel)
date_col <- "Calendar_Week"  # À adapter si différent

if (date_col %in% names(df)) {
  # Convertir en date
  df[, date := as.Date(get(date_col), format = "%m/%d/%Y")]
  
  cat("Plage temporelle:\n")
  cat("  Début:", as.character(min(df$date, na.rm = TRUE)), "\n")
  cat("  Fin:", as.character(max(df$date, na.rm = TRUE)), "\n")
  cat("  Durée:", difftime(max(df$date), min(df$date), units = "weeks"), "semaines\n")
  
  # Nombre d'observations par période
  cat("\nNombre d'observations par période:\n")
  print(df[, .N, by = .(year = year(date), month = month(date))][order(year, month)])
}

# -----------------------------------------------------------------------------
# 6. ANALYSE PAR DIVISION (si applicable)
# -----------------------------------------------------------------------------

cat("\n=== ANALYSE PAR DIVISION ===\n")

division_col <- "Division"  # À adapter si différent

if (division_col %in% names(df)) {
  cat("Divisions présentes:\n")
  print(unique(df[[division_col]]))
  
  cat("\nNombre d'observations par division:\n")
  print(df[, .N, by = Division])
  
  cat("\nVentes totales par division:\n")
  print(df[, .(total_sales = sum(Sales, na.rm = TRUE)), by = Division][order(-total_sales)])
}

# -----------------------------------------------------------------------------
# 7. ANALYSE DES CANAUX MÉDIA
# -----------------------------------------------------------------------------

cat("\n=== ANALYSE DES CANAUX MÉDIA ===\n")

# Identifier les colonnes média (typiquement contiennent "Impressions", "Views", "Spend")
media_patterns <- c("Impressions", "Views", "Paid", "Organic", "Email", "Facebook", 
                    "Google", "Affiliate", "YouTube")

media_cols <- names(df)[grepl(paste(media_patterns, collapse = "|"), names(df), ignore.case = TRUE)]
cat("Colonnes média identifiées:\n")
print(media_cols)

# Statistiques par canal
if (length(media_cols) > 0) {
  cat("\nStatistiques des canaux média:\n")
  media_stats <- df[, lapply(.SD, function(x) {
    c(min = min(x, na.rm = TRUE),
      mean = mean(x, na.rm = TRUE),
      median = median(x, na.rm = TRUE),
      max = max(x, na.rm = TRUE),
      sum = sum(x, na.rm = TRUE))
  }), .SDcols = media_cols]
  print(media_stats)
}

# -----------------------------------------------------------------------------
# 8. VISUALISATIONS EXPLORATOIRES
# -----------------------------------------------------------------------------

cat("\n=== GÉNÉRATION DES VISUALISATIONS ===\n")

# 8.1 Distribution des ventes
if ("Sales" %in% names(df)) {
  p1 <- ggplot(df, aes(x = Sales)) +
    geom_histogram(bins = 30, fill = "steelblue", color = "white") +
    labs(title = "Distribution des ventes", x = "Ventes", y = "Fréquence") +
    theme_minimal()
  ggsave("outputs/exploration/01_sales_distribution.png", p1, width = 10, height = 6)
  cat("Sauvegardé: 01_sales_distribution.png\n")
}

# 8.2 Évolution des ventes dans le temps
if (all(c("Sales", "date") %in% names(df))) {
  # Agrégé si multi-division
  sales_time <- df[, .(total_sales = sum(Sales, na.rm = TRUE)), by = date]
  
  p2 <- ggplot(sales_time, aes(x = date, y = total_sales)) +
    geom_line(color = "steelblue", linewidth = 1) +
    geom_smooth(method = "loess", se = TRUE, alpha = 0.2) +
    labs(title = "Évolution des ventes dans le temps", 
         x = "Date", y = "Ventes totales") +
    scale_y_continuous(labels = comma) +
    theme_minimal()
  ggsave("outputs/exploration/02_sales_over_time.png", p2, width = 12, height = 6)
  cat("Sauvegardé: 02_sales_over_time.png\n")
}

# 8.3 Corrélation entre canaux et ventes
if (length(media_cols) > 0 && "Sales" %in% names(df)) {
  # Matrice de corrélation
  cor_cols <- c(media_cols, "Sales")
  cor_matrix <- cor(df[, ..cor_cols], use = "complete.obs")
  
  png("outputs/exploration/03_correlation_matrix.png", width = 1200, height = 1000)
  corrplot(cor_matrix, method = "color", type = "upper", 
           addCoef.col = "black", number.cex = 0.7,
           tl.col = "black", tl.srt = 45,
           title = "Matrice de corrélation : Canaux média vs Ventes",
           mar = c(0, 0, 2, 0))
  dev.off()
  cat("Sauvegardé: 03_correlation_matrix.png\n")
}

# 8.4 Box plots par division (si applicable)
if (all(c("Sales", division_col) %in% names(df))) {
  p4 <- ggplot(df, aes(x = get(division_col), y = Sales, fill = get(division_col))) +
    geom_boxplot() +
    labs(title = "Distribution des ventes par division",
         x = "Division", y = "Ventes") +
    scale_y_continuous(labels = comma) +
    theme_minimal() +
    theme(legend.position = "none")
  ggsave("outputs/exploration/04_sales_by_division.png", p4, width = 10, height = 6)
  cat("Sauvegardé: 04_sales_by_division.png\n")
}

# 8.5 Heatmap temporelle
if (all(c("Sales", "date") %in% names(df))) {
  df[, `:=`(week = week(date), year = year(date))]
  
  heatmap_data <- df[, .(avg_sales = mean(Sales, na.rm = TRUE)), by = .(year, week)]
  
  p5 <- ggplot(heatmap_data, aes(x = week, y = factor(year), fill = avg_sales)) +
    geom_tile() +
    scale_fill_gradient(low = "white", high = "steelblue", labels = comma) +
    labs(title = "Heatmap des ventes par semaine et année",
         x = "Semaine", y = "Année", fill = "Ventes moyennes") +
    theme_minimal()
  ggsave("outputs/exploration/05_sales_heatmap.png", p5, width = 14, height = 4)
  cat("Sauvegardé: 05_sales_heatmap.png\n")
}

# -----------------------------------------------------------------------------
# 9. PRÉPARER LES DONNÉES POUR ROBYN
# -----------------------------------------------------------------------------

cat("\n=== PRÉPARATION POUR ROBYN ===\n")

# Robyn attend un format spécifique :
# - Une colonne date (format Date)
# - Une colonne de variable dépendante (ex: Sales, revenue)
# - Des colonnes de média spend/impressions
# - Optionnel : colonnes de contrôle (prix, promotions, etc.)

# Vérifier si on doit agréger par date (si multi-division)
cat("\nRecommandations pour Robyn:\n")

if (division_col %in% names(df)) {
  cat("- Dataset multi-division détecté\n")
  cat("- Option 1 : Modéliser chaque division séparément\n")
  cat("- Option 2 : Agréger toutes les divisions\n")
  cat("- Recommandation : Commencer par une division pour comprendre le modèle\n")
}

# Sauvegarder un résumé des données
summary_file <- "outputs/exploration/data_summary.txt"
sink(summary_file)
cat("=== RÉSUMÉ DU DATASET ===\n\n")
cat("Dimensions:", nrow(df), "x", ncol(df), "\n")
cat("Période:", as.character(min(df$date)), "à", as.character(max(df$date)), "\n\n")
cat("Colonnes:\n")
print(names(df))
cat("\n\nStatistiques:\n")
print(summary(df))
sink()
cat("Résumé sauvegardé:", summary_file, "\n")

cat("\n=== EXPLORATION TERMINÉE ===\n")
cat("Visualisations disponibles dans : outputs/exploration/\n")
cat("Prochaine étape : 03_model_training.R\n")
