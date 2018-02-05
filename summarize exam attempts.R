## load library
library(tidyverse)


## Import exam attempts
exam_attempt <- readxl::read_xlsx(path = "./../Tracker - sample exam attempts.xlsx", sheet = "SAS Clinical Trials (Sample Exa", col_names = TRUE, na = "")


## summary grade by question's profile
# myTable <- xtabs(formula = ~ Grade + Area, data = exam_attempt)
# 
# ftable(myTable)

##########################################################
## Understand questions that were answered wrongly.     ##
##########################################################
## preprocessing
resp_wrong <- exam_attempt %>%
  dplyr::filter(Grade %in% c(0)) %>%
  dplyr::select(c(3, 4,5, 6,7, 8,9, 10,11, 12,13,14))

## summarize data
