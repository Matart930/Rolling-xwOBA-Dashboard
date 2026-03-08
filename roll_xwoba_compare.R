library(shiny)
library(dplyr)
library(ggplot2)

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
                  value = 50,
                  step = 10),
      
      checkboxGroupInput(
        "players",
        "Select Players:",
        choices = names(players),
        selected = "Jose Altuve"
      )
    ),
    
    mainPanel(
      plotOutput("rollingPlot")
    )
  )
)

server <- function(input, output, session){
  
  output$rollingPlot <- renderPlot({
    
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
    
    ggplot(rolling_data,
           aes(x = pa,
               y = rolling_xwoba,
               color = player_name)) +
      
      geom_line(size = 1) +
      geom_hline(yintercept = y_breaks,
                 linetype = "dashed",
                 color = "gray") +
      scale_y_continuous(breaks = y_breaks) +
      theme_minimal() +
      labs(
        x = "PA Number",
        y = "Rolling xwOBA",
        color = "Player Key",
        title = paste0("Rolling xwOBA (", window_size, " PAs)")
      ) +
      ylim(0.1, 0.6)
  })
  
}

shinyApp(ui, server)