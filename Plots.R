library(readr)
library(RSQLite)
library(dplyr)
library(ggplot2)

database_connection <- RSQLite::dbConnect(RSQLite::SQLite(), "database.db")

# Prepare data for plotting the time series data
sales_data <- RSQLite::dbGetQuery(database_connection, 
                                  "SELECT DISTINCT I.InvoiceNumber, I.InvoiceDate, P.ProductID,PR.ProductName, P.Quantity, R.RefundQuantity,R.Reason, PC.CategoryName, SUP.SupplierName, PR.Price AS OriginalPrice, PY.PaymentMethod,PY.PaymentStatus,
    CASE 
        WHEN I.InvoiceDate >= S.StartDate AND I.InvoiceDate <= S.EndDate THEN (1 - S.DiscountPercentage) * PR.Price
        ELSE PR.Price
    END AS SellPrice
FROM Invoice AS I
INNER JOIN Purchase AS P ON I.InvoiceNumber = P.InvoiceNumber
LEFT  JOIN Refund AS R ON P.RefundID = R.RefundID
INNER JOIN Product AS PR ON P.ProductID = PR.ProductID
LEFT JOIN SupplierProduct AS SP ON SP.ProductID = PR.ProductID
LEFT JOIN Supplier AS SUP ON SUP.SupplierID = SP.SupplierID
INNER JOIN ProductCategory AS PC ON PC.CategoryID = PR.CategoryID
INNER JOIN Payment AS PY ON PY.InvoiceNumber = I.InvoiceNumber
LEFT JOIN ProductSale AS PS ON PR.ProductID = PS.ProductID
LEFT JOIN Sale AS S ON PS.SaleID = S.SaleID
WHERE I.Status != 'Cancelled'  
GROUP BY I.InvoiceNumber, P.ProductID
ORDER BY I.InvoiceNumber
;")

discount_record <- RSQLite::dbGetQuery(database_connection, 
                                       "SELECT I.InvoiceNumber, I.InvoiceDate, P.ProductID, P.Quantity, PR.Price, ROUND(PR.Price * (1 - S.DiscountPercentage),2) AS SellPrice
FROM Invoice AS I
INNER JOIN Purchase AS P ON I.InvoiceNumber = P.InvoiceNumber
INNER JOIN Product AS PR ON P.ProductID = PR.ProductID
LEFT JOIN ProductSale AS PS ON PR.ProductID = PS.ProductID
LEFT JOIN Sale AS S ON PS.SaleID = S.SaleID
WHERE I.Status != 'Cancelled'  AND I.InvoiceDate >= S.StartDate AND I.InvoiceDate <= S.EndDate  
GROUP BY I.InvoiceNumber, PR.ProductID;")

for (i in 1:nrow(discount_record)) {
  # Find rows in sales_data where InvoiceNumber and ProductID match
  matching_rows <- sales_data$InvoiceNumber == discount_record[i,]$InvoiceNumber &
    sales_data$ProductID == discount_record[i,]$ProductID
  
  # Replace matching rows in sales_data with current row from discount_record
  sales_data[matching_rows, "SellPrice"] <- discount_record[i,"SellPrice"]
}

sales_data$InvoiceDate <- as.Date(sales_data$InvoiceDate)


# Daily Sales and Sales Volume

# Extract daily sales
daily_sales <- sales_data %>% group_by(InvoiceDate) %>% summarise(quantity = sum(Quantity), sale = sum(Quantity * SellPrice)) 
daily_sales <- daily_sales[order(daily_sales$InvoiceDate, decreasing = T),]

# Generate forecast prediction
set.seed(10)
prediction_length <- 90
predicted_sale <- numeric(prediction_length)
predicted_sale[1] <- daily_sales$sale[1]
random_sale <- rnorm(prediction_length, mean = 0, sd = sd(diff(daily_sales$sale)))
for (i in 2:prediction_length) {
  predicted_value <- predicted_sale[[i-1]] + random_sale[i]
  if (predicted_value <= 0) {
    predicted_value <- mean(daily_sales$sale)
  } 
  predicted_sale[i] <- predicted_value
}
predicted_sale <- as.data.frame(predicted_sale)
predicted_sale$InvoiceDate <- seq.Date(from = daily_sales$InvoiceDate[1], by = "day", length.out = 90)

combined_sale <- rbind(data.frame(date = daily_sales$InvoiceDate, value = daily_sales$sale, type = "Actual"),
                       data.frame(date = predicted_sale$InvoiceDate, value = predicted_sale$predicted_sale, type = "Forecast"))


# Extract time periods when products are on sale
sale_date <- RSQLite::dbGetQuery(database_connection, "SELECT StartDate, EndDate FROM Sale;")
sale_date$StartDate <-  as.Date(sale_date$StartDate)
sale_date$EndDate <-  as.Date(sale_date$EndDate)
sale.shade <- data.frame(first = sale_date$StartDate,second = sale_date$EndDate, min = -Inf, max = Inf)

legend_order <- c("Sales Amount", "Products On Sale")

# Plot Daily Sales Amount
ggplot(combined_sale, aes(x = date, y = value)) + 
  geom_line(aes(col = type)) + 
  scale_color_manual(name = "Sales Amount", values = c("black", "coral3")) +
  geom_smooth(method = "lm",se = T, col = "blue") +
  geom_rect(data = sale.shade, aes(x = NULL, y = NULL, xmin = first, xmax = second, ymin = min, ymax = max, fill = "darkseagreen"), alpha = 0.4) + 
  scale_fill_manual(name = "Products On Sale", values = "darkseagreen", labels = "Sale Period") +
  labs(fill = "Sale Period")  + 
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),axis.ticks.x = element_line(size = 0.5)) +
  scale_x_date(limits = c(min(combined_sale$date), max(combined_sale$date)),breaks = '3 months') +
  labs(title = "Time Series Plot for Daily Sales Amount", x = "Invoice Date", y = "Sales Amount") +
  guides(color = guide_legend(order = 1),fill = guide_legend(order = 2))

set.seed(10)
predicted_quantity <- numeric(prediction_length)
predicted_quantity[1] <- daily_sales$quantity[1]
random_quantity <- rnorm(prediction_length, mean = 0, sd = sd(diff(daily_sales$quantity)))

for (i in 2:prediction_length) {
  predicted_value <- predicted_quantity[[i-1]] + random_quantity[i]
  if (predicted_value <= 0) {
    predicted_value <- mean(daily_sales$quantity)
  } 
  predicted_quantity[i] <- predicted_value
}

predicted_quantity <- as.data.frame(predicted_quantity)
predicted_quantity$InvoiceDate <- seq.Date(from = daily_sales$InvoiceDate[1], by = "day", length.out = 90)

combined_quantity <- rbind(data.frame(date = daily_sales$InvoiceDate, value = daily_sales$quantity, type = "Actual"),
                           data.frame(date = predicted_quantity$InvoiceDate, value = predicted_quantity$predicted_quantity, type = "Forecast"))

ggplot(combined_quantity, aes(x = date, y = value)) + 
  geom_line(aes(col = type)) + 
  scale_color_manual(name = "Sales Quantity", values = c("black", "coral2")) +
  geom_smooth(method = "lm",se = T, col = "red") +
  geom_rect(data = sale.shade, aes(x = NULL, y = NULL, xmin = first, xmax = second, ymin = min, ymax = max, fill = "darkseagreen"), alpha = 0.4) + 
  scale_fill_manual(name = "Products On Sale", values = "darkseagreen", labels = "Sale Period") +
  labs(fill = "Sale Period")  + 
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),axis.ticks.x = element_line(size = 0.5)) +
  scale_x_date(limits = c(min(combined_quantity$date), max(combined_quantity$date)),breaks = '3 months') +
  labs(title = "Time Series Plot for Daily Sales Quantity", x = "Invoice Date", y = "Quantity") + 
  guides(color = guide_legend(order = 1),fill = guide_legend(order = 2))


# Fill missing values with 0 before merging
sales_data$Quantity[is.na(sales_data$Quantity)] <- 0
sales_data$RefundQuantity[is.na(sales_data$RefundQuantity)] <- 0

#Reason
# sum up RefundQuantity by Reason
refundR_summary <- aggregate(RefundQuantity ~ Reason, data = sales_data, FUN = sum)

# arrange them in order
refundR_summary <- refundR_summary[order(-refundR_summary$RefundQuantity), ]

# create bar chart to count the number of refund reason
ggplot(refundR_summary, aes(x = reorder(Reason, -RefundQuantity), y = RefundQuantity)) +
  geom_bar(stat = "identity", fill = "pink", color = "black") +
  geom_text(aes(label = RefundQuantity), vjust = -0.5, color = "black", size = 3.5) +  
  labs(title = "Return Reason Summary",
       x = "Reason",
       y = "Total Return Quantity") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


# Top 10 Bestselling Products
# sum up Quantity by ProductName
quantity_summary <- aggregate(Quantity ~ ProductName, data = sales_data, FUN = sum)

# arrange them in order
quantity_summary <- quantity_summary[order(-quantity_summary$Quantity), ]

# Keep only top 10 products
quantity_summary <- quantity_summary[1:10,]

# create bar chart to count the number of refund ProductName
ggplot(quantity_summary, aes(x = reorder(ProductName, -Quantity), y = Quantity, fill = "Quantity")) +
  geom_bar(stat = "identity", color = "black", position = "stack") +
  geom_text(aes(label = Quantity), vjust = -0.5, color = "black", size = 3.5) + 
  labs(title = "Top 10 Bestselling Products",
       x = "Product Name",
       y = "Sales Quantity") +
  scale_fill_manual(values = c("Quantity" = "skyblue"),
                    labels = c("Quantity" = "Sales Quantity")) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 5.5))



# Refund by Product
# sum up RefundQuantity by ProductName
refundP_summary <- aggregate(RefundQuantity ~ ProductName, data = sales_data, FUN = sum)

# Keep only top 10 products
refundP_summary <- refundP_summary[order(-refundP_summary$RefundQuantity), ][1:10,]

# create bar chart to count the number of refund ProductName
ggplot(refundP_summary, aes(x = reorder(ProductName, -RefundQuantity), y = RefundQuantity, fill = "RefundQuantity")) +
  geom_bar(stat = "identity", color = "black", position = "stack") +
  geom_text(aes(label = RefundQuantity), vjust = -0.5, color = "black", size = 3.5) +  
  labs(title = "Top 10 Highest Return Products",
       x = "Product Name",
       y = "Return Quantity") +
  scale_fill_manual(values = c("RefundQuantity" = "pink"),
                    labels = c("RefundQuantity" = "Return Quantity")) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 5.5))



# Sales by product category
# sum up sell price by Product Category Name
PCsales_summary <- aggregate(SellPrice * Quantity ~ CategoryName, data = sales_data, FUN = sum)

# sum up refund price by Product Category Name
refund_summary <- aggregate(SellPrice * RefundQuantity ~ CategoryName, data = sales_data, FUN = sum)

# merge the two summaries
PCsales_summary <- merge(PCsales_summary, refund_summary, by = "CategoryName", all = TRUE)

# arrange them in order
PCsales_summary <- PCsales_summary[order(-PCsales_summary$`SellPrice * Quantity`), ]

# plot
ggplot(PCsales_summary, aes(x = reorder(CategoryName, -`SellPrice * Quantity`))) +
  geom_bar(aes(y = `SellPrice * Quantity`, fill = "RemainingQuantity"), stat = "identity") +
  geom_text(aes(y = `SellPrice * Quantity`, label = `SellPrice * Quantity`), vjust = -0.5, color = "black", size = 1.8) +  
  geom_bar(aes(y = `SellPrice * RefundQuantity`, fill = "RefundQuantity"), stat = "identity") +
  geom_text(aes(y = `SellPrice * RefundQuantity`, label = `SellPrice * RefundQuantity`), vjust = -0.5, color = "black", size = 1.8) +  
  labs(title = "Total Sales (with Refund) by Product Category",
       x = "Product Category",
       y = "Total Sales",
       fill = "") +
  scale_fill_manual(values = c("RemainingQuantity" = "skyblue", "RefundQuantity" = "pink"),
                    labels = c("RemainingQuantity" = "Remaining Sales", "RefundQuantity" = "Refund Sales")) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Quantity by Product Category
# sum up Quantity by Product Category Name
PCquantity <- aggregate( Quantity ~ CategoryName, data = sales_data, FUN = sum)

# sum up Refund Quantity by Product Category Name
refund_quantity <- aggregate(RefundQuantity ~ CategoryName, data = sales_data, FUN = sum)

# merge the two summaries
PCquantity <- merge(PCquantity, refund_quantity, by = "CategoryName", all = TRUE)

#arrange order
PCquantity <- PCquantity[order(-PCquantity$Quantity, -PCquantity$RefundQuantity), ]

# stacked bar plot for quantity(with return) by category name
ggplot(PCquantity, aes(x = reorder(CategoryName, -Quantity), y = Quantity)) +
  geom_bar(aes(fill = "RemainingQuantity"), stat = "identity") +
  geom_text(aes(label = Quantity), vjust = -0.5, color = "black", size = 3.5) +  
  geom_bar(aes(y = RefundQuantity, fill = "RefundQuantity"), stat = "identity") +
  labs(title = "Quantity (vs RefundQuantity) by CategoryName",
       x = "Category Name",
       y = "Total Quantity") +
  scale_fill_manual(values = c("RemainingQuantity" = "skyblue", "RefundQuantity" = "pink"), 
                    name = "Type") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  guides(fill = guide_legend(title = "Type"))

# Quantity by Suppliers
# sum up Quantity by Supplier Name
SUPquantity <- aggregate(Quantity ~ SupplierName, data = sales_data, FUN = sum)

# sum up Refund Quantity by Supplier Name
SUPrefund_quantity <- aggregate(RefundQuantity ~ SupplierName, data = sales_data, FUN = sum)

# merge the two summaries
SUPquantity <- merge(SUPquantity, SUPrefund_quantity, by = "SupplierName", all = TRUE)

#arrange order
SUPquantity <- SUPquantity[order(-SUPquantity$Quantity, -SUPquantity$RefundQuantity), ]

# Keep only top 5 suppliers
SUPquantity <- SUPquantity[1:5,]

# stacked bar plot for quantity(with return) by Supplier name
ggplot(SUPquantity, aes(x = reorder(SupplierName, -Quantity), y = Quantity)) +
  geom_bar(aes(fill = "RemainingQuantity"), stat = "identity") +
  geom_text(aes(label = Quantity), vjust = -0.5, color = "black", size = 3.5) +  
  geom_bar(aes(y = RefundQuantity, fill = "RefundQuantity"), stat = "identity") +
  labs(title = "Top 5 Suppliers: Quantity (with Return Quantity)",
       x = "Supplier Name",
       y = "Total Quantity") +
  scale_fill_manual(values = c("RemainingQuantity" = "skyblue", "RefundQuantity" = "pink"), 
                    name = "Type") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  guides(fill = guide_legend(title = "Type"))



# transaction summary
# computing transaction amount in each payment Method
py_method_summary <- aggregate(SellPrice * Quantity ~ PaymentMethod, data = sales_data, FUN = sum)

# in order
py_method_summary <- py_method_summary[order(-py_method_summary$`SellPrice * Quantity`), ]

# plot
ggplot(py_method_summary, aes(x = reorder(PaymentMethod, -`SellPrice * Quantity`), y = `SellPrice * Quantity`)) +
  geom_bar(stat = "identity", fill = "lavender", color = "black") + 
  geom_text(aes(label = `SellPrice * Quantity`), vjust = -0.5, color = "black", size = 3.5) +  
  labs(title = "Total Sales by Payment Method",
       x = "Payment Method",
       y = "Total Sales") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


