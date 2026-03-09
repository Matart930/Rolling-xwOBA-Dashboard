library(shiny)
library(dplyr)
library(ggplot2)
library(plotly)

source("rolling_xwoba_fun.R")

all_data <- readRDS("statcast_2025.rds")

ui <- fluidPage(
  titlePanel("Rolling xwOBA Dashboard"),
  
  sidebarLayout(
    sidebarPanel(
      sliderInput("pa_window",
                  "Rolling Window (PAs):",
                  min = 50,
                  max = 300,
                  value = 100,
                  step = 10),
      
      checkboxGroupInput(
        "players",
        "Select Players:",
        choices = names(players),
        selected = "Shohei Ohtani"
      )
    ),
    
    mainPanel(
      plotlyOutput("rollingPlot", width = "800px", height = "100%")
    )
  )
)

server <- function(input, output, session){
  
  output$rollingPlot <- renderPlotly({
    
    req(input$players)
    req(input$pa_window)
    
    window_size <- input$pa_window
    
    # Filter selected players
    filtered_data <- all_data %>%
      filter(player_name %in% input$players)
    
    # Compute rolling xwOBA per player
    rolling_data <- filtered_data %>%
      group_by(player_name) %>%
      arrange(game_date) %>%
      group_modify(~ rollxwOBA(.x, window_size)) %>%
      ungroup()
    
    y_breaks <- seq(0.1, 0.6, by = 0.1)
    
    # Helper for ordinal day
    ordinal_day <- function(d) {
      d_num <- as.integer(format(d, "%d"))
      suffix <- ifelse(
        d_num %% 100 %in% 11:13, "th",
        c("th","st","nd","rd","th","th","th","th","th","th")[pmin(d_num %% 10 + 1, 10)]
      )
      paste0(d_num, suffix)
    }
    
    # Add formatted date for tooltip
    rolling_data <- rolling_data %>%
      mutate(date_label = paste(format(date, "%B"), ordinal_day(date)),
             xwoba_label = sub("^0", "", sprintf("%.3f", rolling_xwoba)))
    
    # Base ggplot lines
    p <- ggplot(rolling_data,
                aes(x = pa, y = rolling_xwoba, color = player_name, group = player_name,
                    text = paste0("<b>", player_name, "</b>",
                                  "<br>xwOBA: ", xwoba_label,
                                  "<br>Last PA: ", date_label)
                )) +
      geom_line(size = 1) +
      geom_hline(yintercept = y_breaks, linetype = "dashed", color = "gray") +
      scale_y_continuous(breaks = y_breaks,
                         labels = function(x) sub("^0", "", sprintf("%.3f", x))) +
      coord_cartesian(ylim = c(0.1, 0.6)) +
      theme_minimal() +
      theme(
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank()
      ) +
      labs(x = NULL, y = NULL,
           color = "Player Key",
           title = paste0("Rolling xwOBA (", window_size, " PAs)"))
    
   
    # Convert to ggplotly with hover and dark tooltip
    ggplotly(p, tooltip = "text", source = "rolling_plot") %>%
      layout(
        hoverlabel = list(font = list(color = "white"))
      ) 
  })
  
}

shinyApp(ui, server)


