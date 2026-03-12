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
      
      actionButton("animate_windows", "Animate 50–200 PA"),
      
      checkboxGroupInput(
        "players",
        "Select Players:",
        choices = names(players),
        selected = "Shohei Ohtani"
      ),
      conditionalPanel(
        
        condition = "input.players.length == 1",
        
        sliderInput("forecast_n",
                    "Forecast Future Plate Appearances:",
                    value = 20,
                    min = 5,
                    max = 100,
                    step = 5),
        checkboxInput("show_forecast",
                      "Show Forecast",
                      value = TRUE)
      )
    ),
    
    mainPanel(
      plotlyOutput("rollingPlot", width = "800px", height = "100%")
    )
  )
)


server <- function(input, output, session){
  
  
  observe({
    if(length(input$players) != 1) {
      updateCheckboxInput(session, "show_forecast", value = FALSE)
    }
  })
  
  animating <- reactiveVal(FALSE)
  current_window <- reactiveVal(40)
  
  observeEvent(input$animate_windows, {
    
    if (!is.null(input$show_forecast) && isTRUE(input$show_forecast)) {
      showNotification(
        "Turn off forecast to animate rolling xwOBA windows.",
        type = "warning"
      )
      return()
    }
    
    current_window(40)
    updateSliderInput(session, "pa_window", value = 40)
    animating(TRUE)
  })
  
  
  observe({
    req(animating())
    
    invalidateLater(800, session)
    
    isolate({
      w <- current_window()
      
      if (w < 200) {
        w_next <- w + 10
        current_window(w_next)
        updateSliderInput(session, "pa_window", value = w_next)
      } else {
        animating(FALSE)
      }
    })
  })
  
  output$rollingPlot <- renderPlotly({
    
    if (isTRUE(input$show_forecast) && length(input$players) != 1) {
      showNotification("Select exactly one player to display a forecast.", type = "warning")
    }
    
    req(input$players)
    req(input$pa_window)
    
    window_size <- input$pa_window
    
    # Filter selected players
    filtered_data <- all_data %>%
      filter(player_name %in% input$players)
    
    # Compute rolling xwOBA per player
    rolling_data <- filtered_data %>%
      group_by(player_name) %>%
      arrange(game_date, game_pk, at_bat_number) %>%
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
      mutate(
        date_label = paste(format(date, "%B"), ordinal_day(date)),
        xwoba_label = sub("^0", "", sprintf("%.3f", rolling_xwoba))
      )
    
    # Base ggplot lines
    p <- ggplot(
      rolling_data,
      aes(
        x = pa,
        y = rolling_xwoba,
        color = player_name,
        group = player_name,
        text = paste0(
          "<b>", player_name, "</b>",
          "<br>xwOBA: ", xwoba_label,
          "<br>Last PA: ", date_label
        )
      )
    ) +
      geom_line(linewidth = 1) +
      geom_hline(yintercept = y_breaks, linetype = "dashed", color = "gray") +
      scale_y_continuous(
        breaks = y_breaks,
        labels = function(x) sub("^0", "", sprintf("%.3f", x))
      ) +
      coord_cartesian(ylim = c(0.1, 0.6)) +
      theme_minimal() +
      theme(
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank()
      ) +
      labs(
        x = NULL,
        y = NULL,
        color = "Player Key",
        title = paste0("Rolling xwOBA (", window_size, " PAs)")
      )
    
    # Forecast only if exactly one player is selected
    if (isTRUE(input$show_forecast) && length(input$players) == 1) {
      
      player_df <- rolling_data %>%
        filter(player_name == input$players[1]) %>%
        arrange(pa)
      
      req(nrow(player_df) > 10)
      
      fc <- forecast_xwoba(
        xwoba_series = player_df$rolling_xwoba,
        last_pa = max(player_df$pa),
        n_future = input$forecast_n
      )
      
      fc <- fc %>%
        mutate(
          future_pa = row_number(),
          forecast_label = sub("^0", "", sprintf("%.3f", forecast)),
          text = paste0(
            "Projected xwOBA: ", forecast_label,
            "<br>after ", future_pa, " future PAs"
          )
        )
      
      p <- p +
        geom_line(
          data = fc,
          aes(x = pa, y = forecast, text = text),
          inherit.aes = FALSE,
          color = "red",
          linetype = "dashed",
          linewidth = 1
        ) +
        geom_point(
          data = fc,
          aes(x = pa, y = forecast, text = text),
          inherit.aes = FALSE,
          color = "red",
          size = 1.8,
          alpha = 0.8
        ) +
        geom_ribbon(
          data = fc,
          aes(x = pa, ymin = lower, ymax = upper),
          inherit.aes = FALSE,
          alpha = 0.2,
          fill = "red"
        )
    }
    
    ggplotly(p, tooltip = "text", source = "rolling_plot") %>%
      layout(
        hoverlabel = list(font = list(color = "white"))
      ) 
    
  })
  

  
}

shinyApp(ui, server)



