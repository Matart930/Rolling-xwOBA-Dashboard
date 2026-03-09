# Rolling xwOBA Dashboard Comparison

This dashboard was made using R Shiny and data pulled from statcast to compare the Rolling xwOBA (moving average) of various MLB players from the 2025 season (regular and postseason included).
xwOBA stands for expected weighted on base average and it encompasses all aspects of batting that a hitter can control at the plate (AB + BB - IBB + SF + HBP), and weighs each outcome based on it's
run-scoring value. The "expected" part of this statistic means that rather than looking at the actual outcome of the batted ball (ex: single, double), statcast assigns an expected woba-value of the 
batted ball based on it's exit velocity, launch angle, and in the case of some batted balls, the hitter's sprint speed. The dashboard allows you to adjust the PA (plate appearance) window of the rolling xwOBA
for each hitter, $n$, and see how that moving average has changed over their last $n$ PAs.

## Installation

To install and run this dashboard, create a folder on your desktop and download all files included to that folder (pull_data.R, roll_xwoba_compare.R, rolling_xwoba_fun.R, statcast_2025.rds). statcast_2025.rds
contains the MLB data for the five-hitters that are pre-loaded onto this dashboard: Aaron Judge, Juan Soto, Shohei Ohtani, George Springer, and Kyle Schwarber. If you wish to look at the rolling xwOBA for different
players, feel free to alter the names and respective playerid values in the pull_data.R file (lookup statcast playerid for whichever player you would like) (Note: you may also need to change the "selected" player
in the roll_xwoba_compare.R ui before running the app in RStudio. To run the dashboard, open the roll_xwoba_compare.R file in RStudio and click the "Run App" button in the top right. Be sure that all the necessary 
libraries are installed (shiny, dplyr, ggplot2, baseballr). If you chose to change the players in the pull_data.R file, make sure to run the entirety of that script before running the shiny app. (this will update the statcast_2025.rds file).

### Troubleshooting

If the statcast_search function fails to run in the pull_data.R file with an error along the lines of: (Error in setnames(x, value) : 
Can't assign 92 names to a 118-column data.table). Run the following lines of code in your console to ensure you are using the most up
to date version of the baseballr package:
- install.packages("baseballr")
- remotes::install_github("BillPetti/baseballr")

## Usage

Once the dashboard is loaded, select players from the checkboxes to add their rolling xwOBA to the plot and use the slider to adjust the number of PA's that are included in the moving average calculation.

## File descriptions

- pull_data.R: this file is used to pull the data for the respective MLB players you would like to look at and store that into a dataframe, all_data.
- roll_xwoba_compare.R: this file contains the ui and server code for running the dashboard using R shiny. If there is anything you wish to edit about the plot, you can change it here.
- rolling_xwoba_fun.R: this file contains the function used to convert the raw PA data pulled for each player and calculate their respective rolling xwOBA.
- statcast_2025.rds: this file contains the data for each respective MLB player used for comparison in the dashboard. This updates every time pull_data.R is ran.
