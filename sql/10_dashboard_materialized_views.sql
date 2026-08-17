SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

SELECT
    table_name,
    column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN (
      'customers',
      'customer_rfm',
      'customer_clusters'
  )
ORDER BY table_name, ordinal_position;

-- DROP MATERIALIZED VIEW IF EXISTS mv_customer_intelligence;
-- REFRESH MATERIALIZED VIEW mv_customer_intelligence;

CREATE MATERIALIZED VIEW mv_customer_intelligence AS
SELECT
    -- Customer information
    c.customer_id,
    c.country,
    c.age,
    c.gender,
    c.membership_tier,
    c.registration_date,
    c.preferred_category,
    c.preferred_device,
    c.preferred_payment_method,
    c.acquisition_channel,
    c.newsletter_subscribed,
    c.churned,

    -- Customer metrics
    c.total_orders,
    c.total_spend_usd,
    c.avg_order_value_usd,
    c.days_since_last_purchase,
    c.reviews_given,
    c.avg_review_score,
    c.returns_made,
    c.wishlist_items,

    -- RFM
    r."Recency",
    r."Frequency",
    r."Monetary",
    r."R",
    r."F",
    r."M",
    r."RFM_Score",
    r."RFM_Segment",
    r."Segment_Name",

    -- K-Means
    cl.cluster,
    cl.cluster_name,
    cl."PC1",
    cl."PC2"

FROM customers c

LEFT JOIN customer_rfm r
    ON c.customer_id = r.customer_id

LEFT JOIN customer_clusters cl
    ON c.customer_id = cl.customer_id;


SELECT *
FROM mv_customer_intelligence
LIMIT 10;

SELECT COUNT(*)
FROM mv_customer_intelligence;

SELECT COUNT(DISTINCT customer_id)
FROM mv_customer_intelligence;

-- DROP MATERIALIZED VIEW IF EXISTS mv_sales_dashboard;

CREATE MATERIALIZED VIEW mv_sales_dashboard AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.year,
    o.month,
    o.quarter,
    o.day_of_week,

    o.product_name,
    o.category,
    o.unit_price_usd,
    o.quantity,
    o.subtotal_usd,
    o.discount_pct,
    o.discount_amount_usd,
    o.shipping_fee_usd,
    o.tax_pct,
    o.tax_amount_usd,
    o.total_amount_usd,

    o.payment_method,
    o.device_used,
    o.order_status,
    o.returned,
    o.customer_rating,
    o.is_repeat_customer,

    c.country,
    c.gender,
    c.age,
    c.membership_tier,
    c.acquisition_channel

FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id;

SELECT * FROM orders
LIMIT 0;

SELECT COUNT(*) FROM orders;

SELECT COUNT(*) FROM mv_sales_dashboard;


-- DROP MATERIALIZED VIEW IF EXISTS mv_cohort_retention;

CREATE MATERIALIZED VIEW mv_cohort_retention AS
WITH customer_orders AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', order_date)::date AS order_month,

        MIN(DATE_TRUNC('month', order_date)::date)
            OVER (PARTITION BY customer_id) AS cohort_month

    FROM orders
    WHERE order_status = 'Delivered'
),

cohort_data AS (
    SELECT
        cohort_month,
        (
            EXTRACT(YEAR FROM order_month) * 12
            + EXTRACT(MONTH FROM order_month)
            -
            EXTRACT(YEAR FROM cohort_month) * 12
            - EXTRACT(MONTH FROM cohort_month)
        )::int AS cohort_index,

        COUNT(DISTINCT customer_id) AS customers

    FROM customer_orders
    GROUP BY cohort_month, cohort_index
),

cohort_sizes AS (
    SELECT
        cohort_month,
        customers AS cohort_size
    FROM cohort_data
    WHERE cohort_index = 0
)

SELECT
    cd.cohort_month,
    cd.cohort_index,
    cd.customers,
    cs.cohort_size,

    ROUND(
        cd.customers::numeric / cs.cohort_size * 100,
        2
    ) AS retention_rate

FROM cohort_data cd

JOIN cohort_sizes cs
    ON cd.cohort_month = cs.cohort_month;

SELECT *
FROM mv_cohort_retention
ORDER BY cohort_month, cohort_index
LIMIT 20;

-- Customer view
CREATE UNIQUE INDEX idx_mv_customer_intelligence_customer_id
ON mv_customer_intelligence(customer_id);

-- Sales view
CREATE UNIQUE INDEX idx_mv_sales_dashboard_order_id
ON mv_sales_dashboard(order_id);

-- Cohort view
CREATE UNIQUE INDEX idx_mv_cohort_retention
ON mv_cohort_retention(cohort_month, cohort_index);