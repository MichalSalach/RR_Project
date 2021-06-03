# Creates the html output
library(lubridate)
library(markdown)

# Create a function for rendering the report
render_report <- function(money = 1000,
                         expected_return = 0.1,
                         adverse_return = -0.2) {
  # Package names
  packages <-
    c(
      "lubridate",
      "markdown",
      "tidyverse"
    )
  
  # Install packages not yet installed
  installed_packages <- packages %in% rownames(installed.packages())
  if (any(installed_packages == FALSE)) {
    install.packages(packages[!installed_packages])
  }
  
  # Packages loading
  invisible(lapply(packages, library, character.only = TRUE))

  # Render report
  rmarkdown::render(
    "report/report.Rmd",
    params = list(
      money = money,
      expected_return = expected_return,
      adverse_return = adverse_return
    ),
    output_file = paste0('report_', format(now(), '%d%m%y_%H%M%S'), '.html')
  )
}

# Use this function to render the report and assign you parameters
render_report(
  money = 1000,
  expected_return = 0.1,
  adverse_return = -0.2
)

# Please note: warnings usually signify that there are matches for which there is no offer (NAs for all
# bookmakers). It may happen that a future match has currently no betting odds, or that all 
# are crossed out by the bookmakers. We are not worried by that. The values of 
# `player_1_odds_max`, `player_1_odds_max`, `player_1_odds_max` and `player_1_odds_max` (in report.Rmd) 
# will be then Inf/-Inf, and we filter them out.
