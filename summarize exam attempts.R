## load library
library(tidyverse)


## Import exam attempts
exam_attempt <- readxl::read_xlsx(path = "./Tracker - sample exam attempts.xlsx", sheet = "SAS Clinical Trials (Sample Exa", col_names = TRUE, na = "")

## remove space from column names
names(exam_attempt) <- names(exam_attempt) %>%
  stringr::str_replace_all(pattern = "\\s+", replacement = "")

## Few columns
exam_attempt_flt <- exam_attempt %>%
  dplyr::select(c(1,2, 3, 4,5, 6,7, 8,9, 10,11, 12,13,14,16))
  

## summary grade by question's profile
# myTable <- xtabs(formula = ~ Grade + Area, data = exam_attempt)
# 
# ftable(myTable)

##########################################################
## PROC TRANSPOSE + ARRAY, chap 4 in Shostak (2014).    ##
##########################################################
chap4_areaTranspArray <- exam_attempt_flt[which(stringr::str_detect(string = exam_attempt_flt$Area, regex("(transpose)|(array)", ignore_case = TRUE))),]
chap4_subareaTranspArray <- exam_attempt_flt[which(stringr::str_detect(string = exam_attempt_flt$Subarea, regex("(transpose)|(array)", ignore_case = TRUE))),]

# chap4_transpArray <- data.frame(chap4_areaTranspArray, chap4_subareaTranspArray)
chap4_transpArray <- dplyr::bind_rows(chap4_areaTranspArray, chap4_subareaTranspArray)
chap4_transpArray_flt <- chap4_transpArray %>%
  dplyr::filter(!duplicated(QuestionNo.))

## save
readr::write_csv(x = chap4_transpArray_flt, path = "./summarized questions/chap4_transpArray.csv", col_names = TRUE)

##########################################################
## Understand questions that were answered wrongly.     ##
##########################################################
## preprocessing
resp_wrong <- exam_attempt_flt %>%
  dplyr::filter(Grade %in% c(0)) 

## summarize data
resp_wrong_func <- resp_wrong %>%
  dplyr::filter(SASFunction %in% c(1))
