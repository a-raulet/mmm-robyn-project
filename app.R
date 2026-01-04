# =============================================================================
# app/app.R
# Projet 3 : MMM avec Robyn — Dashboard Shiny interactif
# =============================================================================

library(shiny)
library(shinydashboard)
library(data.table)
library(ggplot2)
library(plotly)
library(DT)
library(scales)

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------

# Chemin vers les résultats Robyn (à adapter après l'entraînement)
ROBYN_OUTPUT_PATH <- "../outputs/robyn"
OPTIMIZATION_PATH <- "../outputs/optimization"

# -----------------------------------------------------------------------------
# UI
# -----------------------------------------------------------------------------

ui <- dashboardPage(
  
  dashboardHeader(
    title = "MMM Budget Optimizer",
    titleWidth = 250
  ),
  
  dashboardSidebar(
    width = 250,
    sidebarMenu(
      id = "tabs",
      menuItem("Vue d'ensemble", tabName = "overview", icon = icon("dashboard")),
      menuItem("Performance des canaux", tabName = "channels", icon = icon("chart-bar")),
      menuItem("Courbes de saturation", tabName = "saturation", icon = icon("chart-line")),
      menuItem("Optimisation budget", tabName = "optimizer", icon = icon("calculator")),
      menuItem("Scénarios", tabName = "scenarios", icon = icon("lightbulb")),
      menuItem("À propos", tabName = "about", icon = icon("info-circle"))
    ),
    
    hr(),
    
    # Informations sur le modèle
    div(
      style = "padding: 10px;",
      h5("Modèle actif"),
      textOutput("model_id"),
      br(),
      h5("Période"),
      textOutput("date_range")
    )
  ),
  
  dashboardBody(
    
    # CSS personnalisé
    tags$head(
      tags$style(HTML("
        .content-wrapper { background-color: #f4f6f9; }
        .box { border-radius: 5px; }
        .info-box { border-radius: 5px; }
        .nav-tabs-custom > .tab-content { padding: 20px; }
      "))
    ),
    
    tabItems(
      
      # --- TAB: Vue d'ensemble ---
      tabItem(
        tabName = "overview",
        
        fluidRow(
          # KPIs principales
          valueBoxOutput("total_sales", width = 3),
          valueBoxOutput("total_spend", width = 3),
          valueBoxOutput("overall_roi", width = 3),
          valueBoxOutput("potential_lift", width = 3)
        ),
        
        fluidRow(
          # Graphique principal : contribution par canal
          box(
            title = "Contribution aux ventes par canal",
            status = "primary",
            solidHeader = TRUE,
            width = 8,
            plotlyOutput("contribution_plot", height = "400px")
          ),
          
          # Répartition du spend
          box(
            title = "Répartition du budget",
            status = "info",
            solidHeader = TRUE,
            width = 4,
            plotlyOutput("spend_pie", height = "400px")
          )
        ),
        
        fluidRow(
          # Évolution temporelle
          box(
            title = "Évolution des ventes et contributions",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("time_series_plot", height = "350px")
          )
        )
      ),
      
      # --- TAB: Performance des canaux ---
      tabItem(
        tabName = "channels",
        
        fluidRow(
          box(
            title = "Métriques par canal",
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
            title = "Contribution vs Spend",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("contribution_vs_spend", height = "350px")
          )
        )
      ),
      
      # --- TAB: Courbes de saturation ---
      tabItem(
        tabName = "saturation",
        
        fluidRow(
          box(
            title = "Sélection du canal",
            status = "info",
            solidHeader = TRUE,
            width = 3,
            selectInput(
              "saturation_channel",
              "Canal:",
              choices = c("Google", "Facebook", "Affiliate"),  # À dynamiser
              selected = "Google"
            ),
            hr(),
            h5("Interprétation"),
            p("La courbe de saturation montre les rendements décroissants."),
            p("Le point optimal se situe avant que la courbe ne s'aplatisse.")
          ),
          
          box(
            title = "Courbe de saturation",
            status = "primary",
            solidHeader = TRUE,
            width = 9,
            plotlyOutput("saturation_curve", height = "400px")
          )
        ),
        
        fluidRow(
          box(
            title = "Effet Adstock (carryover)",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("adstock_curve", height = "300px")
          )
        )
      ),
      
      # --- TAB: Optimisation budget ---
      tabItem(
        tabName = "optimizer",
        
        fluidRow(
          box(
            title = "Paramètres d'optimisation",
            status = "info",
            solidHeader = TRUE,
            width = 4,
            
            numericInput(
              "total_budget",
              "Budget total:",
              value = 100000,
              min = 0,
              step = 10000
            ),
            
            sliderInput(
              "constraint_low",
              "Contrainte min (% du spend actuel):",
              min = 0, max = 100, value = 50, step = 5,
              post = "%"
            ),
            
            sliderInput(
              "constraint_high",
              "Contrainte max (% du spend actuel):",
              min = 100, max = 500, value = 200, step = 10,
              post = "%"
            ),
            
            hr(),
            
            actionButton(
              "run_optimization",
              "Optimiser",
              icon = icon("play"),
              class = "btn-success btn-lg btn-block"
            )
          ),
          
          box(
            title = "Allocation recommandée",
            status = "success",
            solidHeader = TRUE,
            width = 8,
            plotlyOutput("optimization_result", height = "400px")
          )
        ),
        
        fluidRow(
          box(
            title = "Comparaison détaillée",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            DTOutput("optimization_table")
          )
        )
      ),
      
      # --- TAB: Scénarios ---
      tabItem(
        tabName = "scenarios",
        
        fluidRow(
          box(
            title = "Simulateur de scénarios",
            status = "info",
            solidHeader = TRUE,
            width = 4,
            
            h4("Ajuster le budget par canal"),
            
            sliderInput("scenario_google", "Google:", min = 0, max = 200, value = 100, post = "%"),
            sliderInput("scenario_facebook", "Facebook:", min = 0, max = 200, value = 100, post = "%"),
            sliderInput("scenario_affiliate", "Affiliate:", min = 0, max = 200, value = 100, post = "%"),
            
            hr(),
            
            actionButton(
              "run_scenario",
              "Simuler",
              icon = icon("calculator"),
              class = "btn-primary btn-lg btn-block"
            )
          ),
          
          box(
            title = "Résultat de la simulation",
            status = "success",
            solidHeader = TRUE,
            width = 8,
            
            fluidRow(
              valueBoxOutput("scenario_spend", width = 4),
              valueBoxOutput("scenario_response", width = 4),
              valueBoxOutput("scenario_lift", width = 4)
            ),
            
            plotlyOutput("scenario_comparison", height = "300px")
          )
        )
      ),
      
      # --- TAB: À propos ---
      tabItem(
        tabName = "about",
        
        fluidRow(
          box(
            title = "À propos de ce projet",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            
            h3("Marketing Mix Modeling avec Robyn"),
            
            p("Ce dashboard présente les résultats d'un modèle de Marketing Mix Modeling (MMM) 
              construit avec le package Robyn de Meta."),
            
            h4("Méthodologie"),
            tags$ul(
              tags$li("Régression Ridge pour gérer la multicolinéarité"),
              tags$li("Décomposition Prophet pour trend, saisonnalité et holidays"),
              tags$li("Optimisation Nevergrad pour les hyperparamètres"),
              tags$li("Adstock géométrique pour l'effet carryover"),
              tags$li("Saturation logistique pour les rendements décroissants")
            ),
            
            h4("Dataset"),
            p("Division-Level Marketing Spend Data (Kaggle)"),
            p("Données hebdomadaires multi-division avec impressions par canal."),
            
            h4("Auteur"),
            p("Arnaud - Data Science Portfolio Project"),
            p(tags$a(href = "https://github.com/arnaud", "GitHub", target = "_blank")),
            
            h4("Stack technique"),
            tags$ul(
              tags$li("R + Robyn (Meta)"),
              tags$li("Shiny pour le dashboard"),
              tags$li("Déployé sur shinyapps.io")
            )
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
  
  # --- Données réactives ---
  
  # Charger les résultats du modèle
  model_data <- reactive({
    # TODO: Charger depuis les fichiers Robyn
    # Pour l'instant, données de démo
    list(
      model_id = "Model_1_1",
      date_range = c("2018-01-01", "2018-12-31"),
      channels = c("Google", "Facebook", "Affiliate"),
      contributions = c(35000, 25000, 15000),
      spend = c(50000, 40000, 20000),
      roi = c(0.70, 0.63, 0.75)
    )
  })
  
  # --- Outputs sidebar ---
  
  output$model_id <- renderText({
    model_data()$model_id
  })
  
  output$date_range <- renderText({
    paste(model_data()$date_range, collapse = " → ")
  })
  
  # --- Outputs Overview ---
  
  output$total_sales <- renderValueBox({
    valueBox(
      format(sum(model_data()$contributions), big.mark = ","),
      "Ventes attribuées",
      icon = icon("dollar-sign"),
      color = "green"
    )
  })
  
  output$total_spend <- renderValueBox({
    valueBox(
      format(sum(model_data()$spend), big.mark = ","),
      "Budget total",
      icon = icon("credit-card"),
      color = "blue"
    )
  })
  
  output$overall_roi <- renderValueBox({
    roi <- sum(model_data()$contributions) / sum(model_data()$spend)
    valueBox(
      paste0(round(roi * 100, 1), "%"),
      "ROI global",
      icon = icon("chart-line"),
      color = "yellow"
    )
  })
  
  output$potential_lift <- renderValueBox({
    valueBox(
      "+12.5%",  # À calculer dynamiquement
      "Lift potentiel",
      icon = icon("arrow-up"),
      color = "purple"
    )
  })
  
  output$contribution_plot <- renderPlotly({
    data <- data.frame(
      channel = model_data()$channels,
      contribution = model_data()$contributions
    )
    
    plot_ly(data, x = ~reorder(channel, contribution), y = ~contribution, 
            type = "bar", marker = list(color = "#3498db")) %>%
      layout(
        xaxis = list(title = ""),
        yaxis = list(title = "Contribution aux ventes"),
        showlegend = FALSE
      )
  })
  
  output$spend_pie <- renderPlotly({
    data <- data.frame(
      channel = model_data()$channels,
      spend = model_data()$spend
    )
    
    plot_ly(data, labels = ~channel, values = ~spend, type = "pie",
            marker = list(colors = c("#3498db", "#e74c3c", "#2ecc71"))) %>%
      layout(showlegend = TRUE)
  })
  
  output$time_series_plot <- renderPlotly({
    # TODO: Données réelles de la série temporelle
    dates <- seq(as.Date("2018-01-01"), as.Date("2018-12-31"), by = "week")
    sales <- cumsum(rnorm(length(dates), 1000, 200))
    
    plot_ly(x = ~dates, y = ~sales, type = "scatter", mode = "lines",
            line = list(color = "#3498db", width = 2)) %>%
      layout(
        xaxis = list(title = "Date"),
        yaxis = list(title = "Ventes cumulées")
      )
  })
  
  # --- Outputs Channels ---
  
  output$channel_metrics_table <- renderDT({
    data <- data.frame(
      Canal = model_data()$channels,
      Spend = model_data()$spend,
      Contribution = model_data()$contributions,
      ROI = model_data()$roi,
      `Share of Spend` = model_data()$spend / sum(model_data()$spend),
      `Share of Contribution` = model_data()$contributions / sum(model_data()$contributions)
    )
    
    datatable(data, options = list(pageLength = 10)) %>%
      formatCurrency(c("Spend", "Contribution"), currency = "", digits = 0) %>%
      formatPercentage(c("ROI", "Share.of.Spend", "Share.of.Contribution"), digits = 1)
  })
  
  output$roi_by_channel <- renderPlotly({
    data <- data.frame(
      channel = model_data()$channels,
      roi = model_data()$roi
    )
    
    plot_ly(data, x = ~reorder(channel, roi), y = ~roi, type = "bar",
            marker = list(color = ifelse(data$roi > mean(data$roi), "#2ecc71", "#e74c3c"))) %>%
      layout(
        xaxis = list(title = ""),
        yaxis = list(title = "ROI", tickformat = ".0%")
      )
  })
  
  output$contribution_vs_spend <- renderPlotly({
    data <- data.frame(
      channel = model_data()$channels,
      spend = model_data()$spend,
      contribution = model_data()$contributions
    )
    
    plot_ly(data, x = ~spend, y = ~contribution, text = ~channel,
            type = "scatter", mode = "markers+text",
            textposition = "top center",
            marker = list(size = 15, color = "#3498db")) %>%
      layout(
        xaxis = list(title = "Spend"),
        yaxis = list(title = "Contribution")
      )
  })
  
  # --- Outputs Saturation ---
  
  output$saturation_curve <- renderPlotly({
    # Courbe de saturation simulée
    spend <- seq(0, 100000, length.out = 100)
    alpha <- 2
    gamma <- 0.5
    response <- spend^alpha / (spend^alpha + (gamma * max(spend))^alpha)
    
    plot_ly(x = ~spend, y = ~response * 50000, type = "scatter", mode = "lines",
            line = list(color = "#3498db", width = 3)) %>%
      layout(
        xaxis = list(title = "Spend"),
        yaxis = list(title = "Response"),
        shapes = list(
          list(type = "line", x0 = 50000, x1 = 50000, y0 = 0, y1 = 45000,
               line = list(dash = "dot", color = "red"))
        )
      )
  })
  
  output$adstock_curve <- renderPlotly({
    # Effet adstock simulé
    weeks <- 0:12
    theta <- 0.7
    adstock <- theta^weeks
    
    plot_ly(x = ~weeks, y = ~adstock, type = "bar",
            marker = list(color = "#9b59b6")) %>%
      layout(
        xaxis = list(title = "Semaines après exposition"),
        yaxis = list(title = "Effet résiduel", tickformat = ".0%")
      )
  })
  
  # --- Outputs Optimizer ---
  
  observeEvent(input$run_optimization, {
    # TODO: Appeler robyn_allocator() avec les paramètres
    showNotification("Optimisation en cours...", type = "message")
  })
  
  output$optimization_result <- renderPlotly({
    # Résultat simulé
    data <- data.frame(
      channel = rep(model_data()$channels, 2),
      allocation = c(model_data()$spend, model_data()$spend * c(1.2, 0.8, 1.5)),
      type = rep(c("Initial", "Optimal"), each = 3)
    )
    
    plot_ly(data, x = ~channel, y = ~allocation, color = ~type, type = "bar") %>%
      layout(barmode = "group")
  })
  
  output$optimization_table <- renderDT({
    data <- data.frame(
      Canal = model_data()$channels,
      `Spend Initial` = model_data()$spend,
      `Spend Optimal` = model_data()$spend * c(1.2, 0.8, 1.5),
      `Changement` = c("+20%", "-20%", "+50%")
    )
    
    datatable(data)
  })
  
  # --- Outputs Scenarios ---
  
  output$scenario_spend <- renderValueBox({
    total <- sum(model_data()$spend) * 
      (input$scenario_google + input$scenario_facebook + input$scenario_affiliate) / 300
    
    valueBox(
      format(round(total), big.mark = ","),
      "Budget scénario",
      icon = icon("wallet"),
      color = "blue"
    )
  })
  
  output$scenario_response <- renderValueBox({
    valueBox(
      format(85000, big.mark = ","),  # À calculer
      "Réponse attendue",
      icon = icon("chart-bar"),
      color = "green"
    )
  })
  
  output$scenario_lift <- renderValueBox({
    valueBox(
      "+8.5%",  # À calculer
      "vs. actuel",
      icon = icon("arrow-trend-up"),
      color = "purple"
    )
  })
  
  output$scenario_comparison <- renderPlotly({
    plot_ly() %>%
      add_trace(
        x = c("Actuel", "Scénario"),
        y = c(75000, 85000),
        type = "bar",
        marker = list(color = c("#95a5a6", "#2ecc71"))
      ) %>%
      layout(yaxis = list(title = "Réponse attendue"))
  })
}

# -----------------------------------------------------------------------------
# RUN APP
# -----------------------------------------------------------------------------

shinyApp(ui = ui, server = server)
