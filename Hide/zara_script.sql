CREATE TABLE IF NOT EXISTS `Customer` (
  `CustomerID` VARCHAR(10) PRIMARY KEY,
  `Title` VARCHAR(50) NOT NULL,
  `FirstName` VARCHAR(255) NOT NULL,
  `LastName` VARCHAR(255) NOT NULL,
  `PhoneNumber` VARCHAR(20),
  `Email` VARCHAR(255) NOT NULL,
  `Password` VARCHAR(255) NOT NULL,
  `DOB` DATE 
);

CREATE TABLE IF NOT EXISTS `Invoice` (
  `InvoiceNumber` VARCHAR(10) PRIMARY KEY,
  `InvoiceDate` DATE NOT NULL,
  `CustomerID` VARCHAR(10) NOT NULL,
  `AddressLine` VARCHAR(255) NOT NULL,
  `Town` VARCHAR(255) NOT NULL,
  `Postcode` VARCHAR(50) NOT NULL,
  `Status` VARCHAR(255) NOT NULL,
  `TrackingID` VARCHAR(255),
  FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
  CONSTRAINT Status_Check CHECK (Status IN ("Completed", "Shipped", "Preparing for Shipment", "Processing", "Cancelled", "Pending for Payment"))
);

CREATE TABLE IF NOT EXISTS `Payment` (
  `PaymentID` VARCHAR(10) PRIMARY KEY,
  `InvoiceNumber` VARCHAR(10) NOT NULL,
  `PaymentDate` DATE NOT NULL,
  `PaymentMethod` VARCHAR(255) NOT NULL,
  `AddressLine` VARCHAR(255) NOT NULL,
  `Town` VARCHAR(255) NOT NULL,
  `Postcode` VARCHAR(50) NOT NULL,
  `PaymentStatus` VARCHAR(255) NOT NULL,
  FOREIGN KEY (InvoiceNumber) REFERENCES Invoice(InvoiceNumber),
  CONSTRAINT Status_Check CHECK (PaymentStatus IN ("Payment Successful", "Payment Declined"))
);

CREATE TABLE IF NOT EXISTS `ProductCategory` (
  `CategoryID` VARCHAR(10) PRIMARY KEY,
  `CategoryName` VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS `Sale` (
  `SaleID` VARCHAR(10) PRIMARY KEY,
  `EventName` VARCHAR(255) NOT NULL,
  `DiscountPercentage` DECIMAL(10,2) NOT NULL,
  `StartDate` DATE NOT NULL,
  `EndDate` DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS `Supplier` (
  `SupplierID` VARCHAR(10) PRIMARY KEY,
  `SupplierName` VARCHAR(255) NOT NULL,
  `Location` VARCHAR(255) NOT NULL,
  `ContactPerson` VARCHAR(255) NOT NULL,
  `ContactNumber` VARCHAR(20) NOT NULL,
  `ContactEmail` VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS `Product` (
  `ProductID` VARCHAR(10) PRIMARY KEY,
  `CategoryID` VARCHAR(10) NOT NULL,
  `ProductName` VARCHAR(255) NOT NULL,
  `Colour` VARCHAR(50),
  `Size` VARCHAR(50),
  `Description` TEXT,
  `Composition` TEXT,
  `Care` TEXT,
  `Price` DECIMAL(10,2) NOT NULL,
  `Inventory` INT NOT NULL,
  FOREIGN KEY(CategoryID) REFERENCES Category(CategoryID)
);

CREATE TABLE IF NOT EXISTS `ProductSale` (
  `ProductID` VARCHAR(10),
  `SaleID` VARCHAR(10),
  FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
  FOREIGN KEY (SaleID) REFERENCES Sale(SaleID),
  PRIMARY KEY (ProductID, SaleID)
);

CREATE TABLE IF NOT EXISTS `SupplierProduct` (
  `SupplierID` VARCHAR(10),
  `ProductID` VARCHAR(10),
  FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID),
  FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
  PRIMARY KEY (SupplierID, ProductID)

);

CREATE TABLE IF NOT EXISTS `Refund` (
  `RefundID` VARCHAR(10) PRIMARY KEY,
  `RefundQuantity` INT NOT NULL,
  `Reason` TEXT NOT NULL,
  `Status` VARCHAR(255) NOT NULL,
  `RefundDate` DATE NOT NULL,
  `TransactionRef` VARCHAR(255),
  CONSTRAINT Status_Check CHECK (Status IN ("Pending", "Completed", "Rejected", "Processing", "Approved", "Cancelled", "Waiting for Approval", "On Hold"))
);

CREATE TABLE IF NOT EXISTS `Purchase` (
  `ProductID` VARCHAR(10),
  `InvoiceNumber` VARCHAR(10),
  `RefundID` VARCHAR(10),
  `Quantity` INT NOT NULL,
  FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
  FOREIGN KEY (InvoiceNumber) REFERENCES Invoice(InvoiceNumber),
  FOREIGN KEY (RefundID) REFERENCES Refund(RefundID),
  PRIMARY KEY (ProductID, InvoiceNumber)
);