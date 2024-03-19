library(dplyr)
library(readr)
library(RSQLite)

file_path <- "New Data/"
all_files <- list.files(file_path)


database_connection <- RSQLite::dbConnect(RSQLite::SQLite(), "database.db")

check_email_format <- function(email_string) {
  pattern <- "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
  return(grepl(pattern, email_string))
}
check_date_format <- function(date) {
  pattern <- "^^(0?[1-9]|[12][0-9]|3[01])/(0?[1-9]|1[0-2])/(\\d{4})$"
  return(grepl(pattern, date))
}


# Insert Customer Data
if ("Customer.csv" %in% all_files) {
  this_file_path <- paste0(file_path,"Customer.csv")
  file_content <- readr::read_csv(this_file_path)
  
  # bypass rows with na values in not null columns
  no_na_cust <- c("CustomerID", "Title", "FirstName", "LastName", "Email", "Password")
  valid_customer <- file_content[complete.cases(file_content[,no_na_cust]),]

  # bypass rows that has repeated primary key
  cust_pk <- RSQLite::dbGetQuery(database_connection, "SELECT CustomerID FROM Customer;")
  valid_customer <- valid_customer %>% filter(!(CustomerID %in% cust_pk$CustomerID)) 
  
  # save and remove invalid customer data
  invalid_cemail <- !sapply(valid_customer$Email, check_email_format)
  valid_customer <- valid_customer[!invalid_cemail,]
  
  invalid_DOB <- !sapply(valid_customer$DOB, check_date_format)
  valid_customer <- valid_customer[!invalid_DOB,]
  
  # remove duplicated rows
  valid_customer <- valid_customer[!duplicated(valid_customer),]
  
  # adjust format
  valid_customer$DOB <- as.character(as.Date(valid_customer$DOB,format = "%d/%m/%Y"))
  valid_customer$PhoneNumber <- as.character(paste0("+",valid_customer$PhoneNumber))
  
  RSQLite::dbWriteTable(database_connection, "Customer", valid_customer, overwrite = F,append = T)
}

#Validate Invoice
if ("Invoice.csv" %in% all_files) {
  this_file_path <- paste0(file_path,"Invoice.csv")
  file_content <- readr::read_csv(this_file_path)

  # bypass rows with na values in not null columns
  no_na_invoice <- c("InvoiceNumber", "InvoiceDate", "CustomerID", "AddressLine", "Town", "Postcode", "Status")
  valid_invoice <- file_content[complete.cases(file_content[,no_na_invoice]),]
  
  # bypass rows that has repeated primary key
  invoice_pk <- RSQLite::dbGetQuery(database_connection, "SELECT InvoiceNumber FROM Invoice;")
  valid_invoice <- valid_invoice %>% filter(!(InvoiceNumber %in% invoice_pk$InvoiceNumber)) 
  
  # save and remove invalid customer data
  invalid_invoicedate <- !sapply(valid_invoice$InvoiceDate, check_date_format)
  valid_invoice <- valid_invoice[!invalid_invoicedate,]
  
  # check if invoice status is within allowable value
  valid_invoice <- valid_invoice[valid_invoice$Status %in% c("Completed", "Shipped", "Preparing for Shipment", "Processing", "Cancelled", "Pending for Payment"),]
  
  # remove duplicated
  valid_invoice <- valid_invoice[!duplicated(valid_invoice),]
  
  # adjust format of data
  valid_invoice$InvoiceDate <- as.character(as.Date(valid_invoice$InvoiceDate,format = "%d/%m/%Y"))
  
  RSQLite::dbWriteTable(database_connection, "Invoice", valid_invoice, overwrite = F, append = T)
  
}

# Validate Payment
if ("Payment.csv" %in% all_files){
  this_file_path <- paste0(file_path,"Payment.csv")
  file_content <- readr::read_csv(this_file_path)
  
  # bypass rows with na values in not null columns
  valid_payment <- file_content[complete.cases(file_content),]
  
  # bypass rows that has repeated primary key
  payment_pk <- RSQLite::dbGetQuery(database_connection, "SELECT PaymentID FROM Payment;")
  valid_payment <- valid_payment %>% filter(!(PaymentID %in% payment_pk$PaymentID)) 
  
  # save and remove invalid payment records
  invalid_paydate <- !sapply(valid_payment$PaymentDate, check_date_format)
  valid_payment <- valid_payment[!invalid_paydate,]
  
  # check if payment status in allowable value
  valid_payment <- valid_payment[valid_payment$PaymentStatus %in% c("Payment Declined", "Payment Successful"),]
  
  # remove duplicated rows
  valid_payment <- valid_payment[!duplicated(valid_payment),]
  
  # adjust format
  valid_payment$PaymentDate <- as.character(as.Date(valid_payment$PaymentDate,format = "%d/%m/%Y"))
  
  RSQLite::dbWriteTable(database_connection, "Payment", valid_payment, overwrite = F, append = T)

}

# Validate Sale
if ("Sale.csv" %in% all_files) {
  this_file_path <- paste0(file_path,"Sale.csv")
  file_content <- readr::read_csv(this_file_path)

  # bypass rows with na values in not null columns
  valid_sale <- file_content[complete.cases(file_content),]  
  
  # bypass rows that has repeated primary key
  sale_pk <- RSQLite::dbGetQuery(database_connection, "SELECT SaleID FROM Sale;")
  valid_sale <- valid_sale %>% filter(!(SaleID %in% sale_pk$SaleID)) 
  
  # check sale dates format
  invalid_start <- !sapply(valid_sale$StartDate, check_date_format)
  valid_sale <- valid_sale[!invalid_start,]
  
  invalid_end <- !sapply(valid_sale$EndDate, check_date_format)
  valid_sale <- valid_sale[!invalid_end,]
  
  # check discount percentage data type
  valid_sale <- valid_sale[is.numeric(valid_sale$DiscountPercentage),]
  
  # remove duplicated
  valid_sale <- valid_sale[!duplicated(valid_sale),]
  
  # adjust format
  valid_sale$StartDate <- as.character(as.Date(valid_sale$StartDate,format = "%d/%m/%Y"))
  valid_sale$EndDate <- as.character(as.Date(valid_sale$EndDate,format = "%d/%m/%Y"))
  
  RSQLite::dbWriteTable(database_connection, "Sale", valid_sale, overwrite = F, append = T)
  

}

# Validate Refund
if ("Refund.csv" %in% all_files) {
  this_file_path <- paste0(file_path,"Refund.csv")
  file_content <- readr::read_csv(this_file_path)
  
  # bypass rows with na values in not null columns
  no_na_refund <- c("RefundID", "RefundQuantity", "Reason", "Status", "RefundDate")
  valid_refund <- file_content[complete.cases(file_content[,no_na_refund]),]
  
  # bypass rows that has repeated primary key
  refund_pk <- RSQLite::dbGetQuery(database_connection, "SELECT RefundID FROM Refund;")
  valid_refund <- valid_refund %>% filter(!(RefundID %in% refund_pk$RefundID))
  
  # check date format
  invalid_refdate <- !sapply(valid_refund$RefundDate, check_date_format)
  valid_refund <- valid_refund[!invalid_refdate,]
  
  # check data type of refund quantity
  valid_refund <- valid_refund[is.numeric(valid_refund$RefundQuantity),]
  
  # remove duplicated
  valid_refund <- valid_refund[!duplicated(valid_refund),]
  
  # adjust format
  valid_refund$RefundDate <- as.character(as.Date(valid_refund$RefundDate,format = "%d/%m/%Y"))
  
  RSQLite::dbWriteTable(database_connection, "Refund", valid_refund, overwrite = F, append = T)

}

# Validate Supplier
if ("Supplier.csv" %in% all_files) {
  this_file_path <- paste0(file_path,"Supplier.csv")
  file_content <- readr::read_csv(this_file_path)
  
  # bypass rows with na values in not null columns
  valid_supplier <- file_content[complete.cases(file_content),]
  
  # bypass rows that has repeated primary key
  supplier_pk <- RSQLite::dbGetQuery(database_connection, "SELECT SupplierID FROM Supplier;")
  valid_supplier <- valid_supplier %>% filter(!(SupplierID %in% supplier_pk$SupplierID))
  
  # save and remove invalid supplier data
  invalid_supemail <- !sapply(valid_supplier$ContactEmail, check_email_format)
  valid_supplier <- valid_supplier[!invalid_supemail,]
  
  #remove duplicated
  valid_supplier <- valid_supplier[!duplicated(valid_supplier),]
  
  RSQLite::dbWriteTable(database_connection, "Supplier", valid_supplier, overwrite = F, append = T)
  
}

# Insert the remaining
remaining <- all_files[!(all_files %in% c("Customer.csv", "Invoice.csv", "Payment.csv", "Sale.csv", "Refund.csv", "Supplier.csv"))]
for (file in remaining) {
  this_file_path <- paste0(file_path,file)
  file_content <- readr::read_csv(this_file_path)
  
  file_content <- file_content[!duplicated(file_content),]
  
  entity <- gsub(".csv","",file)
  
  if (entity %in% c("Product", "ProductCategory")) {
    results <- RSQLite::dbGetQuery(database_connection, paste0("SELECT * FROM ",entity,";"))
    primary_key <- as_tibble(results[,1])
    valid_record <- file_content %>% filter(!(file_content[,1] %in% primary_key))
    if (entity == "Product" & nrow(valid_record) != 0) {
      valid_record <- valid_record[is.numeric(valid_record$Price),]
      no_na_prod <- c("ProductID", "CategoryID", "ProductName", "Price", "Inventory")
      valid_record <- valid_record[complete.cases(valid_record[,no_na_prod]),]
    } else {
      valid_record <- valid_record[complete.cases(valid_record),]
    }
  } else if (entity %in% c("ProductSale", "SupplierProduct", "Purchase")) {
    results <- RSQLite::dbGetQuery(database_connection, paste0("SELECT * FROM ", entity, ";"))
    primary_key <- results[,1:2]
    file_content <- as.data.frame(file_content)
    primary_key_combined <- paste(primary_key[,1], primary_key[,2])
    file_content_combined <- paste(file_content[,1], file_content[,2])
    repeated <- sapply(file_content_combined, function(x) any(x == primary_key_combined))
    valid_record <- file_content[!repeated,]
    if (entity == "Purchase" & nrow(valid_record != 0)) {
      valid_record <- valid_record[is.numeric(valid_record$Quantity),]
      no_na_purchase <- c("ProductID", "InvoiceNumber", "Quantity")
      valid_record <- valid_record[complete.cases(valid_record[,no_na_purchase]),]
    } else {
      valid_record <- valid_record[complete.cases(valid_record),]
    }
  }
  
  RSQLite::dbWriteTable(database_connection, entity, valid_record, overwrite = F, append = T)

  
}

# post insert check for duplicated entries
duplicated_custemail <- RSQLite::dbGetQuery(database_connection, 'SELECT "Customer email "||Email||" is repeated."
FROM Customer
GROUP BY Email
HAVING COUNT(*) > 1;')
if (nrow(duplicated_custemail) == 0) {
  print("There are no duplicated customer email.")
} else {
  for (i in 1:nrow(duplicated_custemail)){
    print(duplicated_custemail[i,])
  }
}

duplicated_category <- RSQLite::dbGetQuery(database_connection,
                                           'SELECT "Category name "||CategoryName||" is repeated."
FROM ProductCategory
GROUP BY CategoryName
HAVING COUNT(*) > 1;')
if (nrow(duplicated_category) == 0) {
  print("There are no duplicated category name.")
} else {
  for (i in 1:nrow(duplicated_category)){
    print(duplicated_category[i,])
  }
}

duplicated_supplier <- RSQLite::dbGetQuery(database_connection, 
                                           'SELECT SupplierName, ContactPerson, ContactNumber, ContactEmail||" is repeated."
FROM Supplier
GROUP BY SupplierName, ContactPerson, ContactNumber, ContactEmail
HAVING COUNT(*) > 1;')
if (nrow(duplicated_supplier) == 0) {
  print("There are no duplicated suppliers.")
} else {
  for (i in 1:nrow(duplicated_supplier)){
    print(duplicated_supplier[i,])
  }
}

duplicated_saleevent <- RSQLite::dbGetQuery(database_connection, 
                                            'SELECT EventName, DiscountPercentage, StartDate, EndDate||" is repeated."
FROM Sale
GROUP BY EventName, DiscountPercentage, StartDate, EndDate
HAVING COUNT(*) > 1;')
if (nrow(duplicated_saleevent) == 0) {
  print("There are no duplicated sale events.")
} else {
  for (i in 1:nrow(duplicated_saleevent)){
    print(duplicated_saleevent[i,])
  }
}

duplicated_transref <- RSQLite::dbGetQuery(database_connection, 
                                           'SELECT TransactionRef||" is repeated."
FROM Refund
WHERE TransactionRef NOT NULL
GROUP BY TransactionRef
HAVING COUNT(*) > 1;')
if (nrow(duplicated_transref) == 0) {
  print("There are no duplicated refund transaction reference.")
} else {
  for (i in 1:nrow(duplicated_transref)){
    print(duplicated_transref[i,])
  }
}

duplicated_trackingid <- RSQLite::dbGetQuery(database_connection, 
                                             'SELECT TrackingID||" is repeated."
FROM Invoice
WHERE TrackingID NOT NULL
GROUP BY TrackingID
HAVING COUNT(*) > 1;')
if (nrow(duplicated_trackingid) == 0) {
  print("There are no duplicated tracking IDs.")
} else {
  for (i in 1:nrow(duplicated_trackingid)){
    print(duplicated_trackingid[i,])
  }
}

# post insertion check for entry error
incorrect_sale <- RSQLite::dbGetQuery(database_connection, 
                                      'SELECT SaleID || " has end date before start date."
FROM Sale
WHERE StartDate > EndDate;')
if (nrow(incorrect_sale) == 0) {
  print("There are no entry errors in sale event dates.")
} else {
  for (i in 1:nrow(incorrect_sale)){
    print(incorrect_sale[i,])
  }
}

incorrect_refdate <- RSQLite::dbGetQuery(database_connection, 
                                         'SELECT R.RefundID || " should not be approved as refund is not requested within 30 days."
FROM Refund AS R INNER JOIN Purchase AS P
  ON R.RefundID = P.RefundID INNER JOIN Invoice AS I
  ON P.InvoiceNumber = I.InvoiceNumber
WHERE R.RefundDate > DATE(I.InvoiceDate, "+30 days");')
if (nrow(incorrect_refdate) == 0) {
  print("There are no entry errors in refund date.")
} else {
  for (i in 1:nrow(incorrect_refdate)){
    print(incorrect_refdate[i,])
  }
}

incorrect_refquantity <- RSQLite::dbGetQuery(database_connection,
                                             'SELECT R.RefundID || " has entry error as refund quantity should be less than or equal to purchase quantity."
FROM Refund AS R INNER JOIN Purchase as P
  ON R.RefundID = P.RefundID
WHERE R.RefundQuantity > P.Quantity;')
if (nrow(incorrect_refquantity) == 0) {
  print("There are no entry errors in refund quantity.")
} else {
  for (i in 1:nrow(incorrect_refquantity)){
    print(incorrect_refquantity[i,])
  }
}

incorrect_refund <- RSQLite::dbGetQuery(database_connection, 
                                        'SELECT "Refund should not be available for "|| P.ProductID ||" in invoice "||P.InvoiceNumber||"."
FROM Purchase as P INNER JOIN Invoice as I
  ON P.InvoiceNumber = I.InvoiceNumber
WHERE I.Status != "Completed" AND P.RefundID NOT NULL;')
if (nrow(incorrect_refund) == 0) {
  print("There are no invalid refunds.")
} else {
  for (i in 1:nrow(incorrect_refund)){
    print(incorrect_refund[i,])
  }
}

incorrect_invpstatus <- RSQLite::dbGetQuery(database_connection,
                                            'SELECT I.InvoiceNumber || " should be cancelled as payment is not settled within two days."
FROM Invoice AS I INNER JOIN Payment as P
  ON I.InvoiceNumber = P.InvoiceNumber
WHERE DATE(I.InvoiceDate, "+2 days") < P.PaymentDate;')
if (nrow(incorrect_invpstatus) == 0) {
  print("There are no entry errors in invoice status.")
} else {
  for (i in 1:nrow(incorrect_invpstatus)){
    print(incorrect_invpstatus[i,])
  }
}

incorrect_invstatus <- RSQLite::dbGetQuery(database_connection, 
                                           'SELECT I.InvoiceNumber||" should be cancelled or pending for payment as payment is declined."
FROM Invoice AS I INNER JOIN Payment AS P
  ON I.InvoiceNumber = P.InvoiceNumber
WHERE (I.Status != "Cancelled" AND I.Status != "Pending for Payment") 
  AND P.PaymentStatus = "Payment Declined";')
if (nrow(incorrect_invstatus) == 0) {
  print("There are no entry errors in invoice status.")
} else {
  for (i in 1:nrow(incorrect_invstatus)){
    print(incorrect_invstatus[i,])
  }
}

RSQLite::dbDisconnect(database_connection)
