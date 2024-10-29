#### Helper Functions ####### 

# 1.   converts to correct timezone and formats as date ----

convert_tz_date <- function(data, col_name, include_month = FALSE, 
                            make_date = TRUE) {
  data[[col_name]] <- with_tz(data[[col_name]], tzone = "")
  data[[col_name]] <- force_tz(data[[col_name]], tzone = "UTC")
  if (make_date) {
    data[[col_name]] <- as.Date(data[[col_name]])
  }
  if (include_month) {
    month_col_name <- paste0("month_", col_name)
    data[[month_col_name]] <- format(data[[col_name]], "%Y-%m")
  }
  return(data)
}

# example usage:
# data <- convert_tz_date(data, "created_at")

# 2.   gets nomenclatures ----
# returns a dataframe with nomenclature id and label

get_nomenclature <- function(nomenclature_name, country = "ro", 
                             type = "label") {
  
  setwd("\\\\192.168.2.30\\Analyses\\Shared\\Nomenclatures\\")
  file_path <- switch(country,
                      "ro" = "nomenclatures_ro.xlsx",
                      "sp" = "nomenclatures_sp.xlsx",
                      "nomenclatures_Bulgaria.xlsx") # Default to "bg"
  
  nomenclatures <- readxl::read_xlsx(file_path)
  if(country == "bg" & type == "label_en") {
    subset_nomenclatures <- subset(nomenclatures, type == nomenclature_name, 
                                   select = c(1, 3))
  } else if(country == "bg" & type == "label_bg") {
    subset_nomenclatures <- subset(nomenclatures, type == nomenclature_name, 
                                   select = c(1, 4))
  } else {subset_nomenclatures <- subset(nomenclatures, 
                                         type == nomenclature_name, select = c(1:2))
  }
  colnames(subset_nomenclatures) <- c("id", "label")
  if (nrow(subset_nomenclatures) == 0) {
    warning(paste("No matching nomenclature found for", nomenclature_name))
    return(NULL)
  } else {
    return(subset_nomenclatures)
  }
}
# example usage:
# dim_status <- get_nomenclature("credits_applications.status")
# dim_status_en <- get_nomenclature("credits_applications.status", type = "label_en")
# dim_status_bg <- get_nomenclature("credits_applications.status", type = "label_bg")

# 3.   format and write xlsx file ----

format_write_xlsx <- function(df, sheet_name, file_name){
  library(openxlsx)
  widths <- unname(sapply(df, function(x, colname) {
    char_lengths <- nchar(as.character(x))
    max_val_length <- if (all(is.na(x))) NA else min(max(char_lengths, 
                                                         na.rm = TRUE), 45)
    colname_length <- nchar(colname)
    max_length <- max(max_val_length, colname_length)
    return(min(max_length + 5, 50))
  }, colnames(df)))
  
  wb <- createWorkbook()
  header_st <- createStyle(textDecoration = "Bold", halign = "center", 
                           borderStyle = "thin")
  addWorksheet(wb, sheet_name)
  writeData(wb, sheet_name, df, headerStyle = header_st)
  setColWidths(wb, sheet_name, cols = 1:ncol(df), widths = widths)
  freezePane(wb, sheet_name, firstActiveRow = 2)
  saveWorkbook(wb, file_name, overwrite = TRUE)
}

# example usage:
# format_write_xlsx(my_df, "My Sheet", "test_file.xlsx")

# 3.5. format and write xlsx file with multiple sheets ----
format_write_xlsx_multiple_sheets <- function(df_list, sheet_names, file_name) {
  library(openxlsx)
  
  if(length(df_list) != length(sheet_names)) {
    stop("The number of dataframes and sheet names must be the same")
  }
  
  wb <- createWorkbook()
  header_st <- createStyle(textDecoration = "Bold", halign = "center", 
                           borderStyle = "thin")
  
  for (i in seq_along(df_list)) {
    df <- df_list[[i]]
    # Ensure each sheet name is a single string
    sheet_name <- as.character(sheet_names[i])
    
    # Calculate column widths
    widths <- unname(sapply(df, function(x) {
      char_lengths <- nchar(as.character(x))
      max_val_length <- if (all(is.na(x))) NA else min(max(char_lengths, 
                                                           na.rm = TRUE), 45)
      max_length <- max(max_val_length, nchar(names(df)))
      # change the cell width to max_length + 3 & max 50
      return(min(max_length + 3, 50))
    }))
    
    # Add worksheet and write data
    addWorksheet(wb, sheet_name)
    writeData(wb, sheet_name, df, headerStyle = header_st)
    setColWidths(wb, sheet_name, cols = 1:ncol(df), widths = widths)
    freezePane(wb, sheet_name, firstActiveRow = 2)
  }
  
  # Save workbook
  saveWorkbook(wb, file_name, overwrite = TRUE)
}

# Example usage:
# format_write_xlsx_multiple_sheets(list(df1, df2), c("Sheet1", "Sheet2"), 
# "test_file.xlsx")


# 4.   get preferred phone for client_id ----

get_preferred_phones <- function(df, con) {
  library(dplyr)
  query <- sprintf(
    "SELECT client_id, number, preferred, updated_at, brand_id
     FROM citycash.clients_phones WHERE deleted_at IS NULL
     AND client_id IN (%s);", 
    paste(df$client_id, collapse = ","))
  
  phones <- suppressWarnings(dbFetch(dbSendQuery(con, query)))
  
  phones <- phones %>% arrange(desc(updated_at)) %>%
    merge(df[, c("client_id", "brand")], by = "client_id", 
          all.x = TRUE) %>% arrange(desc(preferred), desc(brand_id == brand))
  
  df$preferred_phone <- phones$number[match(df$client_id, 
                                            phones$client_id)]
  print("Git feature 1!! ")
  
  return(df)
}


# Example usage:
# data <- get_preferred_phones(data, con)

# 5. Make changes to branch 2 and leave it for PR

# 6. Make changes to branch 2.1. and leave it for PR