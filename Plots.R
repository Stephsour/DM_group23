library(readr)
library(RSQLite)
library(dplyr)
library(ggplot2)

database_connection <- RSQLite::dbConnect(RSQLite::SQLite(), "zara.db")

# Prepare data for plotting the time series data
sales_data <- RSQLite::dbGetQuery(database_connection, 
                                  "SELECT DISTINCT I.InvoiceNumber, I.InvoiceDate, P.ProductID, P.Quantity, PR.Price AS OriginalPrice,
    CASE 
        WHEN I.InvoiceDate >= S.StartDate AND I.InvoiceDate <= S.EndDate THEN (1 - S.DiscountPercentage) * PR.Price
        ELSE PR.Price
    END AS SellPrice
FROM Invoice AS I
INNER JOIN Purchase AS P ON I.InvoiceNumber = P.InvoiceNumber
LEFT  JOIN Refund AS R ON P.RefundID = R.RefundID
INNER JOIN Product AS PR ON P.ProductID = PR.ProductID
LEFT JOIN ProductSale AS PS ON PR.ProductID = PS.ProductID
LEFT JOIN Sale AS S ON PS.SaleID = S.SaleID
WHERE I.Status != 'Cancelled'  AND OriginalPrice = SellPrice
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
  sales_data[matching_rows, ] <- discount_record[i,]
}

sales_data$InvoiceDate <- as.Date(sales_data$InvoiceDate)
daily_sales <- sales_data %>% group_by(InvoiceDate) %>% summarise(quantity = sum(Quantity), sale = sum(Quantity * SellPrice)) 

daily_sales <- daily_sales[order(daily_sales$InvoiceDate, decreasing = T),]



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



sale_date <- RSQLite::dbGetQuery(database_connection, "SELECT StartDate, EndDate FROM Sale;")
sale_date$StartDate <-  as.Date(sale_date$StartDate)
sale_date$EndDate <-  as.Date(sale_date$EndDate)
sale.shade <- data.frame(first = sale_date$StartDate,second = sale_date$EndDate, min = -Inf, max = Inf)

legend_order <- c("Sales Amount", "Products On Sale")

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

RSQLite::dbDisconnect(database_connection)