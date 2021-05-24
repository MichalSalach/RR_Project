# Loading libraries [install the libraries before if not already installed]
library(knitr)
library(rmarkdown)
library(lubridate)

# Creates the html output
render_report = function(money = 1000,
                         expected_return = 0.1,
                         adverse_return = -0.2) {
  rmarkdown::render(
    "rafal/report.Rmd",
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
