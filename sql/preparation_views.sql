-- fix invoice date format
ALTER TABLE sales ADD COLUMN invoicedate_ TIMESTAMP;
UPDATE sales SET invoicedate_ = TO_TIMESTAMP(invoiceDate, 'MM/DD/YYYY HH24:MI');
ALTER TABLE sales DROP COLUMN invoicedate;
ALTER TABLE sales RENAME COLUMN invoicedate_ TO invoicedate;

-- preview
SELECT * FROM sales LIMIT 10;

-- views


-- Orders by country
CREATE OR REPLACE VIEW orders_by_country AS
SELECT country, COUNT(customerid) AS total_orders
FROM sales
GROUP BY country
ORDER BY total_orders DESC;

-- Unique clients
CREATE OR REPLACE VIEW unique_clients_by_country AS
SELECT country, COUNT(DISTINCT customerid) AS unique_clients
FROM sales
GROUP BY country
ORDER BY unique_clients DESC;

-- Top products
CREATE OR REPLACE VIEW top_selling_products AS
SELECT description, COUNT(invoiceno) AS total_sold
FROM sales
GROUP BY description
ORDER BY total_sold DESC
LIMIT 50;

-- Monthly revenue
CREATE OR REPLACE VIEW revenue_by_month AS
SELECT DATE_TRUNC('month', invoicedate) AS month, SUM(quantity * unitPrice) AS revenue
FROM sales
GROUP BY month
ORDER BY month;

-- Orders by weekday/hour
CREATE OR REPLACE VIEW sales_by_weekday_hour AS
SELECT TO_CHAR(invoicedate, 'DY') AS weekday, 
       EXTRACT(HOUR FROM invoicedate) AS hour, 
       COUNT(*) AS total_orders
FROM sales
GROUP BY weekday, hour
ORDER BY weekday, hour;

-- Avg spend per client
CREATE OR REPLACE VIEW avg_spend_per_client AS
SELECT customerid, ROUND(AVG(invoice_value), 2) AS avg_order_value
FROM (
    SELECT customerid, invoiceno, 
           SUM(CASE 
               WHEN quantity * unitprice > 0 THEN quantity * unitprice 
               ELSE 0 END) AS invoice_value
    FROM sales
    WHERE description NOT LIKE '%Adjust bad debt%'  
    GROUP BY customerid, invoiceno
) AS invoice_totals
GROUP BY customerid;
