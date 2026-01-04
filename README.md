# Marketing Mix Modeling avec Robyn

[![Shiny](https://img.shields.io/badge/Shiny-Dashboard-blue)](https://your-app.shinyapps.io/mmm-robyn)
[![R](https://img.shields.io/badge/R-4.0+-276DC3?logo=r)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 🎯 Objectif business

**Comment un CMO devrait-il réallouer son budget marketing pour maximiser les ventes ?**

Ce projet répond à cette question en utilisant le Marketing Mix Modeling (MMM), une technique statistique qui mesure l'impact de chaque canal marketing sur les ventes et permet d'optimiser l'allocation budgétaire.

## 📊 Dashboard interactif

👉 **[Accéder au dashboard](https://your-app.shinyapps.io/mmm-robyn)** *(lien à mettre à jour après déploiement)*

Le dashboard permet de :
- Visualiser la contribution de chaque canal aux ventes
- Analyser les courbes de saturation (rendements décroissants)
- Simuler différents scénarios budgétaires
- Obtenir des recommandations d'allocation optimale

## 🔬 Méthodologie

### Framework : Robyn (Meta)

[Robyn](https://facebookexperimental.github.io/Robyn/) est le package open-source de Meta pour le MMM. Il combine :

| Composant | Technique | Rôle |
|-----------|-----------|------|
| Régression | Ridge | Gère la multicolinéarité entre canaux |
| Décomposition temporelle | Prophet | Capture trend, saisonnalité, holidays |
| Optimisation | Nevergrad | Trouve les hyperparamètres optimaux |
| Adstock | Géométrique | Modélise l'effet carryover |
| Saturation | Logistique | Capture les rendements décroissants |

### Processus de modélisation

```
1. Data Collection     → Données marketing hebdomadaires
2. Feature Engineering → Adstock + Saturation transforms
3. Model Training      → Multi-objective optimization (NRMSE + DECOMP.RSSD)
4. Model Selection     → Front de Pareto + clustering
5. Budget Allocation   → Optimisation sous contraintes
```

## 📁 Structure du projet

```
mmm-robyn-project/
├── 01_SETUP_GUIDE.md          # Guide d'installation
├── 02_data_exploration.R      # Exploration des données
├── 03_model_training.R        # Entraînement Robyn
├── 04_model_selection.R       # Sélection du modèle
├── 05_budget_allocator.R      # Optimisation budget
├── app/                       
│   └── app.R                  # Dashboard Shiny
├── data/                      # Données (non versionnées)
├── outputs/                   
│   ├── exploration/           # Visualisations EDA
│   ├── robyn/                 # Résultats modèle
│   └── optimization/          # Scénarios budget
├── renv/                      # Environnement R
├── renv.lock                  # Lockfile
└── README.md
```

## 📈 Dataset

**Source** : [Sample Media Spends Data](https://www.kaggle.com/datasets/yugagrawal95/sample-media-spends-data) (Kaggle)

| Caractéristique | Valeur |
|-----------------|--------|
| Granularité | Hebdomadaire |
| Période | ~2 ans |
| Divisions | Multiple (A, B, C...) |
| Canaux | Google, Facebook, Affiliate, Email, Organic |
| Variable cible | Sales |

## 🚀 Résultats clés

*(À compléter après l'entraînement)*

| Métrique | Valeur |
|----------|--------|
| NRMSE (erreur prédiction) | X.XX |
| DECOMP.RSSD (erreur business) | X.XX |
| R² | X.XX |
| Lift potentiel (optimisation) | +XX% |

### Contributions par canal

```
Canal           | Share of Spend | Share of Effect | ROI
----------------|----------------|-----------------|------
Google          | XX%            | XX%             | X.XX
Facebook        | XX%            | XX%             | X.XX
Affiliate       | XX%            | XX%             | X.XX
```

## 🛠️ Installation

### Prérequis

- R ≥ 4.0
- Python ≥ 3.8 (pour Nevergrad)
- RStudio (recommandé)

### Setup

```r
# 1. Cloner le repo
git clone https://github.com/your-username/mmm-robyn-project.git
cd mmm-robyn-project

# 2. Installer les dépendances R
renv::restore()

# 3. Configurer Nevergrad (Python)
library(reticulate)
virtualenv_create("r-reticulate")
py_install("nevergrad", pip = TRUE)

# 4. Télécharger les données depuis Kaggle
# Placer le CSV dans data/

# 5. Exécuter les scripts dans l'ordre
source("02_data_exploration.R")
source("03_model_training.R")
source("05_budget_allocator.R")

# 6. Lancer le dashboard
shiny::runApp("app")
```

## 📚 Références

- [Robyn Documentation](https://facebookexperimental.github.io/Robyn/)
- [An Analyst's Guide to MMM](https://facebookexperimental.github.io/Robyn/docs/analysts-guide-to-MMM/)
- Jin et al. (2017). "Bayesian methods for media mix modeling with carryover and shape effects"
- [Robyn GitHub](https://github.com/facebookexperimental/Robyn)

## 👤 Auteur

**Arnaud** - Data Science Portfolio

- 🌐 [Portfolio](https://your-portfolio.com)
- 💼 [LinkedIn](https://linkedin.com/in/your-profile)
- 🐙 [GitHub](https://github.com/your-username)

---

*Ce projet fait partie d'un portfolio démontrant des compétences en data science appliquée au marketing analytics.*

## 📄 License

MIT License - voir [LICENSE](LICENSE) pour plus de détails.
