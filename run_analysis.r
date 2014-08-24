library(knitr)
library(markdown)

knit("run_analysis.Rmd")
markdownToHTML("run_analysis.md", "run_analysis.html")