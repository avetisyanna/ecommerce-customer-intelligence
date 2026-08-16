-- Dataset / order-status overview

SELECT COUNT(*) AS total_orders,
       COUNT(DISTINCT customer_id) AS unique_customers,
       COUNT(DISTINCT product_name) AS unique_products,
       COUNT(DISTINCT category) AS unique_categories
FROM orders;

SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date
FROM orders;

SELECT
    order_status,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(SUM(total_amount_usd)::numeric, 2) AS total_amount_usd
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

SELECT
    order_status,
    returned,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_status, returned;

SELECT
    COUNT(*) delivered_orders,
    COUNT(DISTINCT customer_id) AS purchasing_customers,
    ROUND(SUM(total_amount_usd)::numeric,2) AS realized_revenue_usd,
    ROUND(AVG(total_amount_usd)::numeric,2) AS avg_order_value_usd
FROM orders
WHERE order_status = 'Delivered';

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(SUM(total_amount_usd)::numeric, 2) AS order_value_usd,
    ROUND(
    100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2
    ) AS order_share_pct
FROM orders
GROUP BY order_status
ORDER BY order_share_pct DESC;

-- Of all submitted orders, 81.99% were successfully delivered, while returned, cancelled and processing
-- orders represented the remaining share. Realized revenue is therefore calculated using delivered
-- orders only.

-- Revenue
SELECT
    year,
    COUNT(*) AS delivered_orders,
    ROUND(SUM(total_amount_usd)::numeric, 2) AS revenue_usd,
    ROUND(AVG(total_amount_usd)::numeric, 2) AS avg_order_value_usd
FROM orders
WHERE order_status = 'Delivered'
GROUP BY year
ORDER BY year;

-- Year-over-Year growth
WITH yearly_revenue AS (
    SELECT
        year,
        SUM(total_amount_usd) AS revenue_usd
    FROM orders
    WHERE order_status = 'Delivered'
        AND year < 2026
    GROUP BY year
)
SELECT
    year,
    ROUND(revenue_usd::numeric, 2) AS revenue_usd,
    ROUND(
        ( (
    revenue_usd - LAG(revenue_usd) OVER(ORDER BY year)
    ) / LAG(revenue_usd) OVER(ORDER BY year) * 100 ) ::numeric, 2) AS yoy_growth_pct
FROM yearly_revenue;

SELECT
    year,
    ROUND(SUM(total_amount_usd)::numeric, 2) AS revenue_usd
FROM orders
WHERE order_status = 'Delivered'
  AND year IN (2025, 2026)
  AND month <= 3
GROUP BY year
ORDER BY year;

-- Monthly revenue
SELECT
    year,
    month,
    COUNT(*) AS delivered_orders,
    ROUND(SUM(total_amount_usd)::numeric, 2) AS revenue_usd,
    ROUND(AVG(total_amount_usd)::numeric, 2) AS avg_order_value_usd
FROM orders
WHERE order_status= 'Delivered'
GROUP BY year, month
ORDER BY year, month;

-- Revenue by category

WITH category_revenue AS (
    SELECT
        category,
        COUNT(*) AS delivered_orders,
        SUM(total_amount_usd) AS revenue_usd
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY category
)
SELECT
    category,
    delivered_orders,
    ROUND(revenue_usd::numeric, 2) AS revenue_usd,
    ROUND(
        (100.0 * revenue_usd / SUM(revenue_usd) OVER ())::numeric,
        2
    ) AS revenue_share_pct
FROM category_revenue
ORDER BY revenue_usd DESC;

-- Top 10 products by revenue
SELECT
    product_name,
    category,
    COUNT(*) AS delivered_orders,
    ROUND(SUM(total_amount_usd)::numeric, 2) AS revenue_usd,
    ROUND(AVG(total_amount_usd)::numeric, 2) AS avg_order_value_usd
FROM orders
WHERE order_status = 'Delivered'
GROUP BY product_name, category
ORDER BY revenue_usd DESC
LIMIT 10;

-- Return rate by category
SELECT
    category,

    SUM(
        CASE
            WHEN order_status = 'Returned' THEN 1
            ELSE 0
        END
    ) AS returned_orders,

    SUM(
        CASE
            WHEN order_status IN ('Delivered', 'Returned') THEN 1
            ELSE 0
        END
    ) AS completed_orders,

    ROUND(
        (
            100.0 *
            SUM(
                CASE
                    WHEN order_status = 'Returned' THEN 1
                    ELSE 0
                END
            )
            /
            SUM(
                CASE
                    WHEN order_status IN ('Delivered', 'Returned') THEN 1
                    ELSE 0
                END
            )
        )::numeric,
        2
    ) AS return_rate_pct

FROM orders
WHERE order_status IN ('Delivered', 'Returned')
GROUP BY category
ORDER BY return_rate_pct DESC;

-- Top 10 customers by realized revenue

SELECT
    customer_id,
    COUNT(*) AS delivered_orders,
    ROUND(SUM(total_amount_usd)::numeric, 2) AS revenue_usd,
    ROUND(AVG(total_amount_usd)::numeric, 2) AS avg_order_value_usd
FROM orders
WHERE order_status = 'Delivered'
GROUP BY customer_id
ORDER BY revenue_usd DESC
LIMIT 10;

-- Repeat vs non-repeat customers
SELECT
    is_repeat_customer,
    COUNT(*) AS delivered_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(SUM(total_amount_usd)::numeric, 2) AS revenue_usd,
    ROUND(AVG(total_amount_usd)::numeric, 2) AS avg_order_value_usd
FROM orders
WHERE order_status = 'Delivered'
GROUP BY is_repeat_customer
ORDER BY revenue_usd DESC;

-- Revenue by country
SELECT
    c.country,
    COUNT(*) AS delivered_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    ROUND(SUM(o.total_amount_usd)::numeric, 2) AS revenue_usd
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.country
ORDER BY revenue_usd DESC;

-- Revenue by payment method
SELECT
    payment_method,
    COUNT(*) AS delivered_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(SUM(total_amount_usd)::numeric, 2) AS revenue_usd,
    ROUND(AVG(total_amount_usd)::numeric, 2) AS avg_order_value_usd
FROM orders
WHERE order_status = 'Delivered'
GROUP BY payment_method
ORDER BY revenue_usd DESC;

-- Revenue by device
SELECT
    device_used,
    COUNT(*) AS delivered_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(SUM(total_amount_usd)::numeric, 2) AS revenue_usd,
    ROUND(AVG(total_amount_usd)::numeric, 2) AS avg_order_value_usd
FROM orders
WHERE order_status = 'Delivered'
GROUP BY device_used
ORDER BY revenue_usd DESC;

-- rank products inside each category
WITH product_revenue AS (
    SELECT
        category,
        product_name,
        SUM(total_amount_usd) AS revenue_usd
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY category, product_name
),

ranked_products AS (
    SELECT
        category,
        product_name,
        revenue_usd,

        RANK() OVER (
            PARTITION BY category
            ORDER BY revenue_usd DESC
        ) AS revenue_rank

    FROM product_revenue
)

SELECT
    category,
    product_name,
    ROUND(revenue_usd::numeric, 2) AS revenue_usd,
    revenue_rank
FROM ranked_products
WHERE revenue_rank <= 3
ORDER BY category, revenue_rank;