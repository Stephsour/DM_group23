library(readr)
library(RSQLite)

database_connection <- RSQLite::dbConnect(RSQLite::SQLite(), "zara.db")

zara_tables <- RSQLite::dbGetQuery(database_connection, "SELECT name FROM sqlite_master WHERE type='table'")$name

fk_constraints_list = list()
for (table_name in zara_tables) {
  fk_constraints <- dbGetQuery(database_connection, paste("PRAGMA foreign_key_list(", table_name, ")"))
  fk_constraints_list[[table_name]] <- fk_constraints
}

for (table_name in zara_tables) {
  if (nrow(fk_constraints_list[[table_name]]) > 0) {
    cat("Foreign key constraints for table", table_name, ":\n")
    print(fk_constraints_list[[table_name]])
    cat("\n")
    cat("\n")
  }
}

RSQLite::dbDisconnect(database_connection)