CREATE DATABASE QuickKart_DB;

USE QuickKart_DB;

SELECT TOP 10 * FROM customers;

SELECT TOP 10 * FROM delivery;

SELECT TOP 10 * FROM order_items;

SELECT TOP 10 * FROM orders;

SELECT TOP 10 * FROM products;

SELECT COUNT(*) as Total_count FROM customers;  -- 3000

SELECT COUNT(*) as Total_count FROM delivery;   --20000

SELECT COUNT(*) as Total_count FROM order_items;  --49700

SELECT COUNT(*) as Total_count FROM orders;  --20000

SELECT COUNT(*) as Total_count FROM products;   --96

-- CHECKING MISSING VALUES

SELECT * FROM customers 
	WHERE city_name IS NULL 
	OR customer_segment IS NULL; 


SELECT * FROM delivery 
	WHERE  delivery_status IS NULL;


SELECT * FROM orders
	WHERE payment_method IS NULL
	OR order_status IS NULL;


SELECT * FROM products
	WHERE product_category IS NULL;


-- CHECKING DUPLICATES

SELECT customer_id , COUNT(*) as Total_Count 
FROM customers
	GROUP BY customer_id
	HAVING COUNT(*) > 1;


SELECT order_id, COUNT(*) as Total_orders
FROM orders
	GROUP BY order_id
	HAVING COUNT(*) > 1;


-- CITY DISTRIBUTION 

SELECT city_name, COUNT(*) as Total_customers
FROM customers
	GROUP BY city_name
	ORDER BY Total_customers DESC;

-- ORDER STATUS

SELECT order_status , COUNT(*) as Total_orders
FROM orders	
	GROUP BY order_status
	ORDER BY Total_orders desc; 

-- CATEGORY DISTRIBUTION

SELECT product_category,  COUNT(*) as Total_products
FROM  products
	GROUP BY product_category
	ORDER BY  Total_products;


-- Total Revenue + Orders +  AOV

SELECT COUNT(DISTINCT order_id) as total_orders,
ROUND(SUM(final_amount_paid),2) as total_revenue ,
ROUND((SUM(final_amount_paid) * 1 /COUNT(DISTINCT order_id)),2) as avg_order_value
FROM orders
	WHERE order_status = 'delivered';

-- Revenue by City

SELECT c.city_name ,
COUNT(DISTINCT o.order_id) as total_orders,
ROUND(SUM(o.final_amount_paid),2) as Revenue,
    ROUND(
        AVG(o.final_amount_paid),2
    ) AS avg_order_value
FROM orders as o
JOIN customers as c
ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.city_name
ORDER BY Revenue DESC;

-- Payment Method

SELECT payment_method , 
COUNT(DISTINCT order_id) as total_orders
FROM orders
GROUP BY payment_method
ORDER BY total_orders DESC;

-- Customer Segment Distribution

SELECT 
    customer_segment,
    COUNT(*) AS total_customers
FROM customers
GROUP BY customer_segment
ORDER BY total_customers DESC;


-- REPEAT PURCHASE ANALYSIS

SELECT 
    repeat_purchase_flag,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 
        / SUM(COUNT(*)) OVER(),2
    ) AS percentage
FROM orders
GROUP BY repeat_purchase_flag;

-- REPEAT PURCHASE BY CITY 

SELECT 
    c.city_name,
	o.repeat_purchase_flag,
	ROUND(
        COUNT(*) * 100.0 
        / SUM(COUNT(*)) OVER(),2
    ) AS percentage,
    COUNT(*) AS total_orders
FROM orders  o
JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY o.repeat_purchase_flag, c.city_name
ORDER BY city_name;

-- DELIVERY IMPACT ON RATING

SELECT TOP 20
    customer_rating,
    delivery_status
FROM orders o
JOIN delivery d
ON o.order_id = d.order_id;

SELECT 
	d.delivery_status,
	ROUND(
		AVG(o.customer_rating * 1.0),2
	) AS avg_rating,
	COUNT(*) as total_orders
FROM delivery as d
JOIN orders as o
ON d.order_id = o.order_id
GROUP BY d.delivery_status
ORDER BY avg_rating DESC;

-- DELIVERY DELAY VS RETENTION

SELECT 
	d.delivery_status,
	o.repeat_purchase_flag,
	COUNT(*) as total_orders
FROM delivery as d
JOIN orders as o
ON d.order_id = o.order_id
GROUP BY d.delivery_status, o.repeat_purchase_flag
ORDER BY delivery_status;


-- RETENTION PERCENTAGE BY CITY
SELECT
    c.city_name,
    ROUND(
        SUM(
            CASE 
                WHEN o.repeat_purchase_flag = 1
                THEN 1 ELSE 0
            END
        ) * 100.0 / COUNT(*),2
    ) AS retention_rate
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY c.city_name
ORDER BY retention_rate DESC;


-- DISCOUNT VS REPEAT PURCHASE

SELECT
    CASE
        WHEN discount_amount <= 50 THEN 'Low Discount'
        WHEN discount_amount <= 100 THEN 'Medium Discount'
        ELSE 'High Discount'
    END AS discount_level,
    repeat_purchase_flag,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER
        (
            PARTITION BY
            CASE
                WHEN discount_amount <= 50 THEN 'Low Discount'
                WHEN discount_amount <= 100 THEN 'Medium Discount'
                ELSE 'High Discount'
            END
        ),2
    ) AS percentage
FROM orders
GROUP BY
    CASE
        WHEN discount_amount <= 50 THEN 'Low Discount'
        WHEN discount_amount <= 100 THEN 'Medium Discount'
        ELSE 'High Discount'
    END,
    repeat_purchase_flag
ORDER BY discount_level;

-- CATEGORY RETENTION ANALYSIS

SELECT
    p.product_category,
    ROUND(
        SUM(
            CASE
                WHEN o.repeat_purchase_flag = 1
                THEN 1 ELSE 0
            END
        ) * 100.0 / COUNT(*),2
    ) AS retention_rate,
    COUNT(*) AS total_orders
FROM order_items oi
JOIN products p
ON oi.product_id = p.product_id
JOIN orders o
ON oi.order_id = o.order_id
GROUP BY p.product_category
ORDER BY retention_rate DESC;

-- CUSTOMER SEGMENT ANALYSIS
SELECT
    c.customer_segment,
    COUNT(DISTINCT o.customer_id) AS customers,
    COUNT(o.order_id) AS total_orders,
    ROUND(
        SUM(o.final_amount_paid),2
    ) AS revenue,
    ROUND(
        AVG(o.final_amount_paid),2
    ) AS avg_order_value
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.customer_segment
ORDER BY revenue DESC;


-- CUSTOMER SEGMENTATION BASED ON DISCOUNTS

SELECT
    c.customer_segment,
    ROUND(AVG(o.discount_amount),2) AS avg_discount,
    ROUND(AVG(o.final_amount_paid),2 ) AS avg_order_value,
    ROUND(
        SUM(
            CASE
                WHEN o.repeat_purchase_flag = 1
                THEN 1 ELSE 0
            END
        ) * 100.0 / COUNT(*),2
    ) AS retention_rate
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.customer_segment
ORDER BY avg_discount DESC;

-- PEAK ORDER HOURS

SELECT 
    DATEPART(HOUR , order_time) AS order_hour,
    COUNT(*) AS total_orders,
    ROUND(AVG (final_amount_paid),2) AS avg_order_value
FROM orders
WHERE order_status = 'Delivered'
GROUP BY DATEPART(HOUR, order_time)
ORDER BY total_orders DESC;

-- BEST DAYS

SELECT
    DATENAME(WEEKDAY, order_date) AS day_name,
    COUNT(*) AS total_orders,
    ROUND(SUM(final_amount_paid),2 ) AS revenue,
    ROUND(AVG(final_amount_paid),2 ) AS avg_order_value
FROM orders
WHERE order_status = 'Delivered'
GROUP BY DATENAME(WEEKDAY, order_date)
ORDER BY total_orders DESC;

-- CUSTOMER CHURN ANALYSIS

WITH customer_orders AS
(
    SELECT
        customer_id,
        MAX(order_date) AS last_order_date
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),

churn_data AS
(
    SELECT
        customer_id,
        CASE
            WHEN DATEDIFF
            ( DAY, last_order_date,
                (SELECT MAX(order_date) FROM orders)
            ) > 60 THEN 'High Risk'
            WHEN DATEDIFF
            ( DAY, last_order_date,
                (SELECT MAX(order_date) FROM orders)
            ) >= 30 THEN 'Medium Risk'

            ELSE 'Low Risk'
        END AS churn_risk
    FROM customer_orders
)

SELECT
    churn_risk,
    COUNT(*) AS customer_count,
    ROUND
    (COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(),2
    ) AS percentage
FROM churn_data
GROUP BY churn_risk
ORDER BY customer_count DESC;

-- CHURN VS DELIVERY STATUS

WITH customer_orders AS
(
    SELECT
        customer_id,
        MAX(order_date) AS last_order_date
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),

churn_data AS
(
    SELECT
        customer_id,
        CASE
            WHEN DATEDIFF
            ( DAY, last_order_date,
                (SELECT MAX(order_date) FROM orders)) > 60 THEN 'High Risk'
            WHEN DATEDIFF
            ( DAY, last_order_date,
                (SELECT MAX(order_date) FROM orders)) >= 30 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS churn_risk
    FROM customer_orders
)

SELECT
    cd.churn_risk, d.delivery_status,
    COUNT(DISTINCT o.customer_id) AS unique_customers
FROM churn_data cd
JOIN orders o
ON cd.customer_id = o.customer_id
JOIN delivery d
ON o.order_id = d.order_id
WHERE o.order_status = 'Delivered'
GROUP BY cd.churn_risk, d.delivery_status
ORDER BY cd.churn_risk, unique_customers DESC;

-- CHURN VS FREQUENCY BUYERS

WITH customer_orders AS
(
    SELECT
        customer_id,
        MAX(order_date) AS last_order_date
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),

churn_data AS
(
    SELECT
        customer_id,
        CASE
            WHEN DATEDIFF
            ( DAY, last_order_date,
                (SELECT MAX(order_date) FROM orders)) > 60 THEN 'High Risk'
            WHEN DATEDIFF
            ( DAY, last_order_date,
                (SELECT MAX(order_date) FROM orders)) >= 30 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS churn_risk
    FROM customer_orders
)

SELECT
    cd.churn_risk,
    CASE
        WHEN o.days_between_orders BETWEEN 0 AND 15
        THEN 'Frequent Buyer'
        WHEN o.days_between_orders BETWEEN 16 AND 30
        THEN 'Moderate Buyer'
        ELSE 'Infrequent Buyer'
    END AS buyer_type,
    COUNT(DISTINCT o.customer_id)
    AS unique_customers
FROM churn_data cd
JOIN orders o
ON cd.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY cd.churn_risk,
    CASE
        WHEN o.days_between_orders BETWEEN 0 AND 15
        THEN 'Frequent Buyer'
        WHEN o.days_between_orders BETWEEN 16 AND 30
        THEN 'Moderate Buyer'
        ELSE 'Infrequent Buyer'
    END
ORDER BY churn_risk, unique_customers DESC;

-- CHURN VS CUSTOMER RATING

WITH customer_orders AS
(
    SELECT
        customer_id,
        MAX(order_date) AS last_order_date
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),

churn_data AS
(
    SELECT
        customer_id,
        CASE
            WHEN DATEDIFF
            ( DAY, last_order_date,
                (SELECT MAX(order_date) FROM orders)) > 60 THEN 'High Risk'
            WHEN DATEDIFF
            ( DAY, last_order_date,
                (SELECT MAX(order_date) FROM orders)) >= 30 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS churn_risk
    FROM customer_orders
)

SELECT
    cd.churn_risk,
    CASE
        WHEN o.customer_rating BETWEEN 1 AND 2
        THEN 'Low Rating'
        WHEN o.customer_rating = 3
        THEN 'Medium Rating'
        ELSE 'High Rating'
    END AS rating_category,
    COUNT(DISTINCT o.customer_id)
    AS unique_customers
FROM churn_data cd
JOIN orders o
ON cd.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY cd.churn_risk,
    CASE
        WHEN o.customer_rating BETWEEN 1 AND 2
        THEN 'Low Rating'
        WHEN o.customer_rating = 3
        THEN 'Medium Rating'
        ELSE 'High Rating'
    END
ORDER BY churn_risk, unique_customers DESC;

-- CHURN VS ORDER STATUS

WITH customer_orders AS
(
    SELECT
        customer_id,
        MAX(order_date) AS last_order_date
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),

churn_data AS
(
    SELECT
        customer_id,
        CASE
            WHEN DATEDIFF
            ( DAY, last_order_date,
                (SELECT MAX(order_date) FROM orders)) > 60 THEN 'High Risk'
            WHEN DATEDIFF
            ( DAY, last_order_date,
                (SELECT MAX(order_date) FROM orders)) >= 30 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS churn_risk
    FROM customer_orders
)

SELECT
    cd.churn_risk, o.order_status,
    COUNT(DISTINCT o.customer_id)
    AS unique_customers
FROM churn_data cd
JOIN orders o
ON cd.customer_id = o.customer_id
WHERE o.order_status IN
('Delivered', 'Failed', 'Returned')
GROUP BY cd.churn_risk, o.order_status
ORDER BY cd.churn_risk, unique_customers DESC;

WITH customer_orders AS
(
    SELECT customer_id,
        MAX(order_date) AS last_order_date
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),

churn_data AS
(
    SELECT customer_id,
        CASE
            WHEN DATEDIFF
            ( DAY, last_order_date,
                (SELECT MAX(order_date) FROM orders)) > 60 THEN 'High Risk'
            WHEN DATEDIFF
            ( DAY, last_order_date,
                (SELECT MAX(order_date) FROM orders)) >= 30 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS churn_risk
    FROM customer_orders
)

SELECT
    cd.churn_risk,
    ROUND(AVG(o.customer_rating * 1.0),2) AS avg_rating,
    ROUND(AVG(o.discount_amount),2) AS avg_discount,
    ROUND(AVG(o.days_between_orders),2) AS avg_days_between_orders,
    ROUND(AVG(o.final_amount_paid),2) AS avg_order_value
FROM churn_data cd
INNER JOIN orders o
ON cd.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY cd.churn_risk
ORDER BY avg_days_between_orders DESC;

SELECT TOP 10 customer_id,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND (SUM(final_amount_paid),2 ) AS total_revenue,
    ROUND (AVG(final_amount_paid),2 ) AS avg_order_value,
    RANK() OVER
    (
        ORDER BY SUM(final_amount_paid) DESC
    ) AS customer_rank
FROM orders
WHERE order_status = 'Delivered'
GROUP BY customer_id
ORDER BY total_revenue DESC;

-- Monthly Revenue Trend Analysis

SELECT
    DATENAME(MONTH, order_date) AS month_name,
    MONTH(order_date) AS month_number,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND (SUM(final_amount_paid),2) AS revenue,
    LAG (SUM(final_amount_paid))
    OVER
    (ORDER BY MONTH(order_date)) AS previous_month_revenue
FROM orders
WHERE order_status = 'Delivered'
GROUP BY MONTH(order_date), DATENAME(MONTH, order_date)
ORDER BY month_number;

-- Cohort-style Retention Analysis

SELECT
    DATENAME( MONTH, c.customer_join_date) AS join_month,
    MONTH( c.customer_join_date) AS month_number,
    COUNT( DISTINCT c.customer_id) AS total_customers,
    ROUND(SUM(
            CASE
                WHEN o.repeat_purchase_flag = 1
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),2
    ) AS retention_rate
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY DATENAME( MONTH, c.customer_join_date),
    MONTH(c.customer_join_date)
ORDER BY month_number;