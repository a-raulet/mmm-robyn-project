# =============================================================================
# MMM Robyn Dashboard - Version deployable
# =============================================================================

library(shiny)
library(shinydashboard)
library(ggplot2)
library(plotly)
library(DT)
library(scales)

# -----------------------------------------------------------------------------
# CHARGEMENT DES DONNEES
# -----------------------------------------------------------------------------

# Modele selectionne
SELECTED_MODEL <- "1_119_7"

# Charger les donnees
pareto_data <- read.csv("data/pareto_aggregated.csv", stringsAsFactors = FALSE)
clusters_data <- read.csv("data/pareto_clusters.csv", stringsAsFactors = FALSE)
raw_data <- read.csv("data/raw_data.csv", stringsAsFactors = FALSE)
allocation_data <- read.csv("data/allocation_results.csv", stringsAsFactors = FALSE)
scenarios_data <- read.csv("data/budget_scenarios_summary.csv", stringsAsFactors = FALSE)

# Filtrer pour le modele selectionne
model_data <- pareto_data[pareto_data$solID == SELECTED_MODEL, ]

# Extraire les metriques des canaux media (exclure intercept, trend, season, holiday)
media_channels <- c("Google_Impressions", "Facebook_Impressions", "Affiliate_Impressions",
                    "Organic_Views", "Email_Impressions")
channel_data <- model_data[model_data$rn %in% media_channels, ]

# Metriques du modele
model_metrics <- clusters_data[clusters_data$solID == SELECTED_MODEL, ]

# -----------------------------------------------------------------------------
# UI
# -----------------------------------------------------------------------------

ui <- dashboardPage(
  skin = "blue",

  dashboardHeader(
    title = "MMM Budget Optimizer",
    titleWidth = 280
  ),

  dashboardSidebar(
    width = 280,
    sidebarMenu(
      id = "tabs",
      menuItem("Vue d'ensemble", tabName = "overview", icon = icon("dashboard")),
      menuItem("Performance des canaux", tabName = "channels", icon = icon("chart-bar")),
      menuItem("Optimisation budget", tabName = "optimizer", icon = icon("calculator")),
      menuItem("A propos", tabName = "about", icon = icon("info-circle"))
    ),

    hr(),

    div(
      style = "padding: 15px;",
      h5("Modele actif"),
      p(style = "font-weight: bold; color: #3498db;", SELECTED_MODEL),
      br(),
      h5("Periode"),
      p("2018-01-06 a 2020-02-29"),
      br(),
      h5("Metriques"),
      p(paste("NRMSE:", round(model_metrics$nrmse, 3))),
      p(paste("RSSD:", round(model_metrics$decomp.rssd, 3)))
    )
  ),

  dashboardBody(

    tags$head(
      tags$style(HTML("
        .content-wrapper { background-color: #f4f6f9; }
        .box { border-radius: 5px; }
        .info-box { border-radius: 5px; }
        .small-box { border-radius: 5px; }
      "))
    ),

    tabItems(

      # --- TAB: Vue d'ensemble ---
      tabItem(
        tabName = "overview",

        fluidRow(
          valueBoxOutput("total_sales", width = 3),
          valueBoxOutput("total_spend", width = 3),
          valueBoxOutput("overall_roi", width = 3),
          valueBoxOutput("potential_lift", width = 3)
        ),

        fluidRow(
          box(
            title = "Contribution aux ventes par canal",
            status = "primary",
            solidHeader = TRUE,
            width = 8,
            plotlyOutput("contribution_plot", height = "400px")
          ),

          box(
            title = "Repartition des impressions",
            status = "info",
            solidHeader = TRUE,
            width = 4,
            plotlyOutput("spend_pie", height = "400px")
          )
        ),

        fluidRow(
          box(
            title = "Decomposition des effets",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("decomp_plot", height = "350px")
          )
        )
      ),

      # --- TAB: Performance des canaux ---
      tabItem(
        tabName = "channels",

        fluidRow(
          box(
            title = "Metriques par canal",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            DTOutput("channel_metrics_table")
          )
        ),

        fluidRow(
          box(
            title = "ROI par canal",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("roi_by_channel", height = "350px")
          ),

          box(
            title = "Part de contribution vs Part de budget",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("efficiency_plot", height = "350px")
          )
        )
      ),

      # --- TAB: Optimisation budget ---
      tabItem(
        tabName = "optimizer",

        fluidRow(
          box(
            title = "Scenarios budgetaires",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            DTOutput("scenarios_table")
          )
        ),

        fluidRow(
          box(
            title = "Allocation recommandee",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("allocation_plot", height = "400px")
          ),

          box(
            title = "Impact de l'optimisation",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("lift_plot", height = "400px")
          )
        ),

        fluidRow(
          box(
            title = "Details de l'allocation optimale",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            DTOutput("allocation_table")
          )
        )
      ),

      # --- TAB: A propos ---
      tabItem(
        tabName = "about",

        fluidRow(
          box(
            title = "A propos de ce projet",
            status = "primary",
            solidHeader = TRUE,
            width = 12,

            h3("Marketing Mix Modeling avec Robyn"),

            p("Ce dashboard presente les resultats d'un modele de Marketing Mix Modeling (MMM)
              construit avec le package Robyn de Meta."),

            h4("Methodologie"),
            tags$ul(
              tags$li("Regression Ridge pour gerer la multicolinearite"),
              tags$li("Decomposition Prophet pour trend, saisonnalite et holidays"),
              tags$li("Optimisation Nevergrad pour les hyperparametres"),
              tags$li("Adstock geometrique pour l'effet carryover"),
              tags$li("Saturation logistique pour les rendements decroissants")
            ),

            h4("Dataset"),
            p("Division-Level Marketing Spend Data (Kaggle)"),
            p("Donnees hebdomadaires multi-division avec impressions par canal."),

            h4("Stack technique"),
            tags$ul(
              tags$li("R + Robyn (Meta)"),
              tags$li("Shiny pour le dashboard"),
              tags$li("Deploye sur shinyapps.io")
            ),

            hr(),

            h4("Auteur"),
            p("Arnaud - Data Science Portfolio Project")
          )
        )
      )
    )
  )
)

# -----------------------------------------------------------------------------
# SERVER
# -----------------------------------------------------------------------------

server <- function(input, output, session) {

  # --- Outputs Overview ---

  output$total_sales <- renderValueBox({
    total <- sum(abs(channel_data$xDecompAgg), na.rm = TRUE)
    valueBox(
      format(round(total), big.mark = " "),
      "Contribution Media",
      icon = icon("dollar-sign"),
      color = "green"
    )
  })

  output$total_spend <- renderValueBox({
    total <- sum(channel_data$total_spend, na.rm = TRUE)
    valueBox(
      format(round(total), big.mark = " "),
      "Impressions totales",
      icon = icon("eye"),
      color = "blue"
    )
  })

  output$overall_roi <- renderValueBox({
    valueBox(
      round(model_metrics$nrmse, 3),
      "NRMSE (erreur)",
      icon = icon("chart-line"),
      color = "yellow"
    )
  })

  output$potential_lift <- renderValueBox({
    lift <- scenarios_data$lift_vs_current[2]  # Optimise scenario
    valueBox(
      paste0("+", round(lift, 1), "%"),
      "Lift potentiel",
      icon = icon("arrow-up"),
      color = "purple"
    )
  })

  output$contribution_plot <- renderPlotly({
    df <- channel_data[, c("rn", "xDecompAgg")]
    df$xDecompAgg <- abs(df$xDecompAgg)
    df <- df[order(-df$xDecompAgg), ]

    plot_ly(df, x = ~reorder(rn, xDecompAgg), y = ~xDecompAgg,
            type = "bar",
            marker = list(color = "#3498db")) %>%
      layout(
        xaxis = list(title = ""),
        yaxis = list(title = "Contribution aux ventes"),
        showlegend = FALSE
      )
  })

  output$spend_pie <- renderPlotly({
    df <- channel_data[, c("rn", "total_spend")]
    df <- df[!is.na(df$total_spend) & df$total_spend > 0, ]

    colors <- c("#3498db", "#e74c3c", "#2ecc71", "#9b59b6", "#f39c12")

    plot_ly(df, labels = ~rn, values = ~total_spend, type = "pie",
            marker = list(colors = colors)) %>%
      layout(showlegend = TRUE)
  })

  output$decomp_plot <- renderPlotly({
    # Toutes les composantes du modele
    df <- model_data[, c("rn", "xDecompPerc")]
    df$xDecompPerc <- abs(df$xDecompPerc) * 100
    df <- df[df$xDecompPerc > 0.1, ]
    df <- df[order(-df$xDecompPerc), ]

    plot_ly(df, x = ~reorder(rn, xDecompPerc), y = ~xDecompPerc,
            type = "bar",
            marker = list(color = ifelse(df$rn %in% media_channels, "#3498db", "#95a5a6"))) %>%
      layout(
        xaxis = list(title = ""),
        yaxis = list(title = "Part de contribution (%)")
      )
  })

  # --- Outputs Channels ---

  output$channel_metrics_table <- renderDT({
    df <- channel_data[, c("rn", "total_spend", "xDecompAgg", "xDecompPerc", "roi_mean")]
    df$xDecompAgg <- abs(df$xDecompAgg)
    df$xDecompPerc <- abs(df$xDecompPerc) * 100

    colnames(df) <- c("Canal", "Impressions", "Contribution", "Part (%)", "ROI")

    datatable(df,
              options = list(pageLength = 10, dom = 't'),
              rownames = FALSE) %>%
      formatRound(c("Impressions", "Contribution"), digits = 0) %>%
      formatRound(c("Part (%)", "ROI"), digits = 2)
  })

  output$roi_by_channel <- renderPlotly({
    df <- channel_data[, c("rn", "roi_mean")]
    df <- df[!is.na(df$roi_mean), ]

    avg_roi <- mean(df$roi_mean, na.rm = TRUE)

    plot_ly(df, x = ~reorder(rn, roi_mean), y = ~roi_mean, type = "bar",
            marker = list(color = ifelse(df$roi_mean > avg_roi, "#2ecc71", "#e74c3c"))) %>%
      layout(
        xaxis = list(title = ""),
        yaxis = list(title = "ROI")
      )
  })

  output$efficiency_plot <- renderPlotly({
    df <- channel_data[, c("rn", "spend_share", "effect_share")]
    df <- df[!is.na(df$spend_share) & !is.na(df$effect_share), ]
    df$spend_share <- df$spend_share * 100
    df$effect_share <- df$effect_share * 100

    plot_ly(df, x = ~spend_share, y = ~effect_share, text = ~rn,
            type = "scatter", mode = "markers+text",
            textposition = "top center",
            marker = list(size = 15, color = "#3498db")) %>%
      add_trace(x = c(0, 100), y = c(0, 100), mode = "lines",
                line = list(dash = "dot", color = "gray"),
                showlegend = FALSE) %>%
      layout(
        xaxis = list(title = "Part de budget (%)", range = c(0, max(df$spend_share) * 1.2)),
        yaxis = list(title = "Part de contribution (%)", range = c(0, max(df$effect_share) * 1.2))
      )
  })

  # --- Outputs Optimizer ---

  output$scenarios_table <- renderDT({
    df <- scenarios_data
    colnames(df) <- c("Scenario", "Budget Total", "Reponse", "ROI", "Lift vs Actuel (%)")

    datatable(df,
              options = list(pageLength = 5, dom = 't'),
              rownames = FALSE) %>%
      formatRound(c("Budget Total", "Reponse"), digits = 0) %>%
      formatRound(c("ROI", "Lift vs Actuel (%)"), digits = 2)
  })

  output$allocation_plot <- renderPlotly({
    df <- allocation_data[, c("channels", "initSpendShare", "optmSpendShareUnit")]
    df$initSpendShare <- df$initSpendShare * 100
    df$optmSpendShareUnit <- df$optmSpendShareUnit * 100

    plot_ly(df, x = ~channels, y = ~initSpendShare, name = "Initial",
            type = "bar", marker = list(color = "#95a5a6")) %>%
      add_trace(y = ~optmSpendShareUnit, name = "Optimal",
                marker = list(color = "#2ecc71")) %>%
      layout(
        barmode = "group",
        xaxis = list(title = ""),
        yaxis = list(title = "Part du budget (%)")
      )
  })

  output$lift_plot <- renderPlotly({
    df <- scenarios_data[1:2, c("scenario", "expected_response")]

    plot_ly(df, x = ~scenario, y = ~expected_response, type = "bar",
            marker = list(color = c("#95a5a6", "#2ecc71"))) %>%
      layout(
        xaxis = list(title = ""),
        yaxis = list(title = "Reponse attendue")
      )
  })

  output$allocation_table <- renderDT({
    df <- allocation_data[, c("channels", "initSpendUnit", "optmSpendUnit",
                               "initResponseUnit", "optmResponseUnit")]

    colnames(df) <- c("Canal", "Budget Initial", "Budget Optimal",
                      "Reponse Initiale", "Reponse Optimale")

    datatable(df,
              options = list(pageLength = 5, dom = 't'),
              rownames = FALSE) %>%
      formatRound(c("Budget Initial", "Budget Optimal",
                    "Reponse Initiale", "Reponse Optimale"), digits = 0)
  })
}

# -----------------------------------------------------------------------------
# RUN APP
# -----------------------------------------------------------------------------

shinyApp(ui = ui, server = server)
