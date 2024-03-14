# DM_group23

Steps to play around:
1. In the terminal, run the command: sqlite3 zara.db < zara_script.sql

2. Import data: run the file load_data.Rmd

3. Print referential integrity: run the file referential_integrity.Rmd 

4. run the plots.rmd

5. if want to try retrieving data, you can either do it by creating an sql script then use the command: sqlite3 zara.db < the script

or 

in terminal: sqlite3 zara.db
then type the SQL statements

Example
For entry(email) in new_data NOT in data
	Entry.append
	Customer_id(Entry) = Customer_id(Total) + 1
