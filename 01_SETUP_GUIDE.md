# Projet 3 : MMM avec Robyn — Guide d'Installation

## Prérequis

- R ≥ 4.0 (RStudio Server sur WSL ou Positron/RStudio sur Windows)
- Python ≥ 3.8 (déjà présent via ton setup WSL)
- Connexion internet pour télécharger les packages

---

## Étape 1 : Vérifier ton environnement

Ouvre RStudio et exécute :

```r
# Vérifier la version de R
R.version$version.string

# Vérifier que Python est accessible
Sys.which("python3")
```

---

## Étape 2 : Installer les dépendances R

```r
# Packages de base
install.packages(c(
  "remotes",
  "reticulate",
  "data.table",
  "ggplot2",
  "prophet",    # Pour la décomposition temporelle
  "nloptr",     # Pour l'optimisation
  "renv"        # Pour la reproductibilité
))

# Installer Robyn depuis CRAN (version stable)
install.packages("Robyn")

# OU depuis GitHub (version dev, plus récente)
# remotes::install_github("facebookexperimental/Robyn/R")
```

---

## Étape 3 : Configurer Nevergrad (Python)

C'est l'étape la plus délicate. Robyn utilise Nevergrad (librairie Python de Meta) via `reticulate`.

### Option A : Via virtualenv (recommandée pour WSL)

```r
library(reticulate)

# Créer un environnement virtuel dédié
virtualenv_create("r-reticulate", python = Sys.which("python3"))

# Activer l'environnement
use_virtualenv("r-reticulate", required = TRUE)

# Installer nevergrad
py_install("nevergrad", pip = TRUE)

# Vérifier l'installation
py_module_available("nevergrad")  # Doit retourner TRUE
```

### Option B : Via conda (si tu as Miniconda/Anaconda)

```r
library(reticulate)

# Créer un environnement conda
conda_create("r-reticulate")

# Installer nevergrad
conda_install("r-reticulate", "nevergrad", pip = TRUE)

# Activer l'environnement
use_condaenv("r-reticulate", required = TRUE)

# Vérifier
py_module_available("nevergrad")
```

### Configuration permanente (évite de répéter à chaque session)

Pour que R utilise toujours le bon Python, ajoute cette ligne dans ton fichier `.Renviron` :

```r
# Ouvre l'éditeur .Renviron
usethis::edit_r_environ()
```

Ajoute cette ligne (adapte le chemin si nécessaire) :

```
RETICULATE_PYTHON="~/.virtualenvs/r-reticulate/bin/python"
```

Redémarre R après modification.

---

## Étape 4 : Vérifier l'installation complète

```r
library(Robyn)
library(reticulate)

# Vérifier nevergrad
py_module_available("nevergrad")

# Charger le dataset de démo pour tester
data("dt_simulated_weekly")
head(dt_simulated_weekly)

# Si tout fonctionne, tu devrais voir les données !
```

---

## Étape 5 : Initialiser renv pour la reproductibilité

```r
# Dans le dossier de ton projet
setwd("~/mmm-robyn-project")  # Adapte le chemin

# Initialiser renv
renv::init()

# Snapshot des packages
renv::snapshot()
```

---

## Troubleshooting courant

### Erreur "nevergrad not found"

```r
# Vérifier quel Python est utilisé
py_config()

# Forcer le bon chemin
use_python("~/.virtualenvs/r-reticulate/bin/python", required = TRUE)
```

### Erreur SSL sur Windows

Si tu utilises RStudio sur Windows (pas WSL), tu peux avoir des erreurs SSL.
Voir : https://slproweb.com/products/Win32OpenSSL.html

### Prophet ne s'installe pas

```r
# Sur Ubuntu/WSL, installer les dépendances système d'abord
# Dans le terminal :
# sudo apt-get install -y libcurl4-openssl-dev libssl-dev

install.packages("prophet")
```

---

## Structure du projet

```
mmm-robyn-project/
├── 01_SETUP_GUIDE.md          # Ce fichier
├── 02_data_exploration.R      # Exploration des données
├── 03_model_training.R        # Entraînement Robyn
├── 04_model_selection.R       # Sélection du meilleur modèle
├── 05_budget_allocator.R      # Optimisation budget
├── app/                       # Dashboard Shiny
│   ├── app.R
│   └── ...
├── data/                      # Données brutes et transformées
├── outputs/                   # Résultats Robyn (plots, JSON)
├── renv/                      # Environnement reproductible
└── renv.lock                  # Lockfile des versions
```

---

## Prochaine étape

Une fois l'installation validée, passe au script `02_data_exploration.R` pour explorer le dataset Division-Level Marketing Spend.
