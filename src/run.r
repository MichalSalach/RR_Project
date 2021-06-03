# Creates the html output
library(lubridate)
library(markdown)

render_report = function(money = 1000,
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




render_report(
  money = 1000,
  expected_return = 0.1,
  adverse_return = -0.2
)
#=========================================================================================================
