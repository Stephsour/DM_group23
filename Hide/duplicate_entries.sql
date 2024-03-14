## Customers
# Email of each customer should be unique
SELECT "Customer email "||Email||" is repeated."
FROM Customer
GROUP BY Email
HAVING COUNT(*) > 1;

##Category
# Category name is unique
SELECT "Category name "||CategoryName||" is repeated."
FROM ProductCategory
GROUP BY CategoryName
HAVING COUNT(*) > 1;

##Supplier
SELECT SupplierName, ContactPerson, ContactNumber, ContactEmail||" is repeated."
FROM Supplier
GROUP BY SupplierName, ContactPerson, ContactNumber, ContactEmail
HAVING COUNT(*) > 1;

##ProductSale
SELECT EventName, DiscountPercentage, StartDate, EndDate||" is repeated."
FROM Sale
GROUP BY EventName, DiscountPercentage, StartDate, EndDate
HAVING COUNT(*) > 1;

#Refund
SELECT TransactionRef
FROM Refund
WHERE TransactionRef NOT NULL
GROUP BY TransactionRef
HAVING COUNT(*) > 1;

#Invoice
SELECT TrackingID
FROM Invoice
WHERE TrackingID NOT NULL
GROUP BY TrackingID
HAVING COUNT(*) > 1;


