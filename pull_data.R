library(baseballr)
library(dplyr)

players <- c(
  "Shohei Ohtani" = 660271,
  "Aaron Judge" = 592450,
  "Jose Altuve" = 514888,
  "Juan Soto" = 665742,
  "Kyle Schwarber" = 656941
)

all_data <- lapply(names(players), function(name) {
  
  message(paste("Pulling data for", name))
  
  statcast_search(
    start_date = "2025-03-27",
    end_date = "2025-11-01",
    playerid = players[name]
  ) %>%
    filter(events != "" & !is.na(events)) %>%
    arrange(game_date, game_pk, at_bat_number) %>%
    mutate(player_name = name)
  
}) %>%
  bind_rows()

saveRDS(all_data,
        file = file.path(dirname(rstudioapi::getActiveDocumentContext()$path),
                         "statcast_2025.rds"))