rollxwOBA <- function(df, window_size) {
  n <- nrow(df)
  rolling_xwoba <- numeric(n - window_size + 1)
  
  for(i in 1:(n - window_size + 1)) {
    
    total_xwoba <- 0
    total_iBB <- 0
    
    for(j in i:(i + window_size - 1)) {
      
      xwoba_val <- df$estimated_woba_using_speedangle[j]
      
      if(length(xwoba_val) == 0 || is.na(xwoba_val)) {
        xwoba_val <- 0
      }
      total_iBB <- total_iBB + (df$events[j] == "intent_walk")
      
      total_xwoba <- total_xwoba + xwoba_val
    }
    
   rolling_xwoba[i] <- total_xwoba / (window_size - total_iBB)
  }
  
  xwoba_tail <- tail(rolling_xwoba, window_size)
  n_tail <- 1:window_size
  
  rolling_xwoba_df <- data.frame(
    rolling_xwoba = xwoba_tail,
    pa = n_tail,
    date = tail(df$game_date[1:n], window_size)
  )
  return(rolling_xwoba_df)
}