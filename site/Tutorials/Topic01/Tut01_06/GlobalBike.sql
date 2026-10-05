-- (1) For how long has Global Bikes been in business?

SELECT 
    MIN(date) AS first_sales_order,
    MAX(date) AS last_sales_order
FROM sales_orders
;


-- (2) How many customers has Global Bike done business with?

SELECT DISTINCT custdescr AS customer_name
FROM sales_orders
;


-- (3) How many sales orders have been placed by customers in 2016?

SELECT 
    DATEPART(YEAR, date) AS Year,
    COUNT(DISTINCT ordernumber) AS Sales_Order_Count
FROM sales_orders
GROUP BY DATEPART(YEAR, date)
ORDER BY Year DESC
;


-- (4) Which was the best-selling product (sales volume) in 2016?

SELECT
    product,
    proddescr AS product_name,
    SUM(salesquantity) AS units_sold_in_2016
FROM sales_orders
WHERE DATEPART(YEAR, date) = 2016
GROUP BY product, proddescr
ORDER BY units_sold_in_2016 DESC
;


-- (5) Which was the best-selling item (revenue) in 2016?

SELECT
    product AS Product,
    proddescr AS Product_Name,
    SUM(revenue_usd - discount_usd) AS 'Revenue (2016, USD Equivalent)'
FROM sales_orders
WHERE DATEPART(YEAR, date) = 2016
GROUP BY product, proddescr
ORDER BY 'Revenue (2016, USD Equivalent)' DESC
;


-- (6) Which product category had the most profitable year, and in which year was that?

SELECT
    prodcat AS Category,
    catdescr AS 'Category Name',
    DATEPART(YEAR, date) AS 'Sales Year',
    SUM(revenue_usd - discount_usd - costs_in_usd) AS 'Contribution Margin (USD)'
FROM sales_orders
GROUP BY prodcat, catdescr, DATEPART(YEAR, date)
ORDER BY 'Contribution Margin (USD)' DESC
;


-- (7) Which customers have been lost since opening?

SELECT
    custdescr AS customer_name,
    MIN(date) AS first_order,
    MAX(date) AS last_order
FROM sales_orders
GROUP BY custdescr
ORDER BY last_order ASC
;


-- (8) What is Global Bikes' discounting policy? Per product (diff. disc. for each sales order line item), or per order (same discount applied to all sales order line items)?

WITH order_discount AS (
    SELECT
        ordernumber,
        MIN(discount / revenue) AS min_discount_pct_temp,
        MAX(discount / revenue) AS max_discount_pct_temp,
        MAX(discount / revenue) - MIN(discount / revenue) AS diff_discount_pct_temp
    FROM sales_orders
    GROUP BY ordernumber
    HAVING COUNT(*) > 1
)
SELECT TOP 15
    ordernumber,
    ROUND(min_discount_pct_temp, 4)  AS min_discount_pct,
    ROUND(max_discount_pct_temp, 4)  AS max_discount_pct,
    ROUND(diff_discount_pct_temp, 4) AS diff_discount_pct
FROM order_discount
ORDER BY diff_discount_pct_temp DESC
;
