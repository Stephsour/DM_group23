# DM_group23

Steps to play around:
1. In the terminal, run the command: sqlite3 zara.db < zara_script.sql

2. Import data: run the file load_data.Rmd

3. Print referential integrity: run the file referential_integrity.Rmd 

4. Check for duplicate entries in the database: in terminal, run sqlite3 zara.db < duplicate_entries.sql (should show nth since there are no duplicate entries)

5. Check for any entry error (e.g. start date after end date etc.) in the database: in terminal, run sqlite3 zara.db < entryerror.sql

6. if want to try retrieving data, you can either do it by creating an sql script then use the command: sqlite3 zara.db < the script

or 

in terminal: sqlite3 zara.db
then type the SQL statements