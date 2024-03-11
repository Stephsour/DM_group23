# Check email format
SELECT "Invalid email for customer with ID: "||CustomerID
FROM Customer
WHERE Email NOT LIKE ('%_@%.%');

SELECT "Invalid DOB for customer with ID: "||CustomerID
FROM Customer
WHERE DOB NOT LIKE ('____-__-__') ;

SELECT "Invalid email for supplier with ID: "||SupplierID
FROM Supplier
WHERE ContactEmail NOT LIKE ('%_@%.%');

SELECT "Invalid date format for event with ID: "|| SaleID
FROM Sale
WHERE StartDate NOT LIKE ('____-__-__') 
  OR EndDate NOT LIKE ('____-__-__');
  
SELECT "Invalid date format for invoice: "||InvoiceNumber
FROM Invoice
WHERE InvoiceDate NOT LIKE ('____-__-__') ;

SELECT "Invalid date format for payment: "||PaymentID
FROM Payment
WHERE PaymentDate NOT LIKE ('____-__-__') ;

SELECT "Invalid date format for refund: "||RefundID
FROM Refund
WHERE RefundDate NOT LIKE ('____-__-__') ;
