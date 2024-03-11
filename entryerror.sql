# Check if there are any entry error
# Start date should be before end date
SELECT SaleID
FROM Sale
WHERE StartDate > EndDate;

# Products can only be refunded within 30 days
SELECT R.RefundID
FROM Refund AS R INNER JOIN Purchase AS P
  ON R.RefundID = P.RefundID INNER JOIN Invoice AS I
  ON P.InvoiceNumber = I.InvoiceNumber
WHERE R.RefundDate > DATE(I.InvoiceDate, '+30 days');

# Invoice payment should be settled within 2 days, cancelled otherwise
SELECT I.InvoiceNumber
FROM Invoice AS I INNER JOIN Payment as P
  ON I.InvoiceNumber = P.InvoiceNumber
WHERE DATE(I.InvoiceDate, '+2 days') < P.PaymentDate;

# Refund quantity should be less than or equal to purchase quantity
SELECT R.RefundID
FROM Refund AS R INNER JOIN Purchase as P
  ON R.RefundID = P.RefundID
WHERE R.RefundQuantity > P.Quantity;

# Refund can only be done on invoice with status "Completed"
SELECT P.InvoiceNumber, P.ProductID
FROM Purchase as P INNER JOIN Invoice as I
  ON P.InvoiceNumber = I.InvoiceNumber
WHERE I.Status != "Completed" AND P.RefundID NOT NULL;

# If payment is declined, the invoice is either pending for payment or cancelled
SELECT I.InvoiceNumber
FROM Invoice AS I INNER JOIN Payment AS P
  ON I.InvoiceNumber = P.InvoiceNumber
WHERE (I.Status != "Cancelled" AND I.Status != "Pending for Payment") 
  AND P.PaymentStatus = "Payment Declined";
  

  