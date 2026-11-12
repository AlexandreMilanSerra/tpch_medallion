-- Validation set: 10 business questions, answered two ways.
-- Reference route: hand-written SQL on the Gold tables.
-- Semantic route: SEMANTIC_VIEW() on SV_SALES_FULFILMENT.
-- Pass = rows_with_difference is 0 and rows_in_semantic_view is above 0.

WITH
ref_base AS (
  SELECT f.net_revenue, f.gross_margin, f.discount_rate, f.is_late_delivery,
         f.order_id, f.ship_mode, f.order_priority,
         c.customer_name, c.market_segment,
         c.region_name AS customer_region, c.nation_name AS customer_nation,
         s.nation_name AS supplier_nation, p.brand, p.manufacturer,
         d.year AS order_year, d.year_month AS order_month
  FROM TPCH_DEMO.GOLD.FCT_ORDER_LINES f
  JOIN TPCH_DEMO.GOLD.DIM_CUSTOMER c ON f.customer_id = c.customer_id
  JOIN TPCH_DEMO.GOLD.DIM_SUPPLIER s ON f.supplier_id = s.supplier_id
  JOIN TPCH_DEMO.GOLD.DIM_PART p     ON f.part_id     = p.part_id
  JOIN TPCH_DEMO.GOLD.DIM_DATE d     ON f.order_date  = d.date_day
),

-- Q1: What was total revenue by region in 1995?
q1_sv AS (
  SELECT customer_region, ROUND(total_revenue, 2) AS v
  FROM SEMANTIC_VIEW(TPCH_DEMO.SEMANTIC.SV_SALES_FULFILMENT
    DIMENSIONS customers.customer_region, dates.order_year
    METRICS order_lines.total_revenue)
  WHERE order_year = 1995),
q1_ref AS (
  SELECT customer_region, ROUND(SUM(net_revenue), 2) AS v
  FROM ref_base WHERE order_year = 1995 GROUP BY 1),

-- Q2: Which five customer nations generate the most revenue?
q2_sv AS (
  SELECT customer_nation, ROUND(total_revenue, 2) AS v
  FROM SEMANTIC_VIEW(TPCH_DEMO.SEMANTIC.SV_SALES_FULFILMENT
    DIMENSIONS customers.customer_nation
    METRICS order_lines.total_revenue)
  ORDER BY v DESC LIMIT 5),
q2_ref AS (
  SELECT customer_nation, ROUND(SUM(net_revenue), 2) AS v
  FROM ref_base GROUP BY 1 ORDER BY v DESC LIMIT 5),

-- Q3: Which five supplier nations have the highest late delivery rate?
q3_sv AS (
  SELECT supplier_nation, ROUND(late_delivery_rate, 6) AS v
  FROM SEMANTIC_VIEW(TPCH_DEMO.SEMANTIC.SV_SALES_FULFILMENT
    DIMENSIONS suppliers.supplier_nation
    METRICS order_lines.late_delivery_rate)
  ORDER BY v DESC LIMIT 5),
q3_ref AS (
  SELECT supplier_nation, ROUND(AVG(IFF(is_late_delivery, 1, 0)), 6) AS v
  FROM ref_base GROUP BY 1 ORDER BY v DESC LIMIT 5),

-- Q4: What is the average discount rate by customer segment?
q4_sv AS (
  SELECT market_segment, ROUND(average_discount_rate, 6) AS v
  FROM SEMANTIC_VIEW(TPCH_DEMO.SEMANTIC.SV_SALES_FULFILMENT
    DIMENSIONS customers.market_segment
    METRICS order_lines.average_discount_rate)),
q4_ref AS (
  SELECT market_segment, ROUND(AVG(discount_rate), 6) AS v
  FROM ref_base GROUP BY 1),

-- Q5: How has monthly revenue changed in Europe?
q5_sv AS (
  SELECT order_month, ROUND(total_revenue, 2) AS v
  FROM SEMANTIC_VIEW(TPCH_DEMO.SEMANTIC.SV_SALES_FULFILMENT
    DIMENSIONS customers.customer_region, dates.order_month
    METRICS order_lines.total_revenue)
  WHERE customer_region = 'EUROPE'),
q5_ref AS (
  SELECT order_month, ROUND(SUM(net_revenue), 2) AS v
  FROM ref_base WHERE customer_region = 'EUROPE' GROUP BY 1),

-- Q6: Which ten brands have the highest gross margin?
q6_sv AS (
  SELECT brand, ROUND(total_gross_margin, 2) AS v
  FROM SEMANTIC_VIEW(TPCH_DEMO.SEMANTIC.SV_SALES_FULFILMENT
    DIMENSIONS parts.brand
    METRICS order_lines.total_gross_margin)
  ORDER BY v DESC LIMIT 10),
q6_ref AS (
  SELECT brand, ROUND(SUM(gross_margin), 2) AS v
  FROM ref_base GROUP BY 1 ORDER BY v DESC LIMIT 10),

-- Q7: How many urgent-priority orders were there each year?
q7_sv AS (
  SELECT order_year, order_count AS v
  FROM SEMANTIC_VIEW(TPCH_DEMO.SEMANTIC.SV_SALES_FULFILMENT
    DIMENSIONS dates.order_year, order_lines.order_priority
    METRICS order_lines.order_count)
  WHERE order_priority = 'Urgent'),
q7_ref AS (
  SELECT order_year, COUNT(DISTINCT order_id) AS v
  FROM ref_base WHERE order_priority = 'Urgent' GROUP BY 1),

-- Q8: Which ship mode has the most late deliveries?
q8_sv AS (
  SELECT ship_mode, late_line_count AS v
  FROM SEMANTIC_VIEW(TPCH_DEMO.SEMANTIC.SV_SALES_FULFILMENT
    DIMENSIONS order_lines.ship_mode
    METRICS order_lines.late_line_count)
  ORDER BY v DESC LIMIT 1),
q8_ref AS (
  SELECT ship_mode, SUM(IFF(is_late_delivery, 1, 0)) AS v
  FROM ref_base GROUP BY 1 ORDER BY v DESC LIMIT 1),

-- Q9: Who are the five customers with the most revenue?
q9_sv AS (
  SELECT customer_name, ROUND(total_revenue, 2) AS v
  FROM SEMANTIC_VIEW(TPCH_DEMO.SEMANTIC.SV_SALES_FULFILMENT
    DIMENSIONS customers.customer_name
    METRICS order_lines.total_revenue)
  ORDER BY v DESC LIMIT 5),
q9_ref AS (
  SELECT customer_name, ROUND(SUM(net_revenue), 2) AS v
  FROM ref_base GROUP BY 1 ORDER BY v DESC LIMIT 5),

-- Q10: What is the gross margin by manufacturer?
q10_sv AS (
  SELECT manufacturer, ROUND(total_gross_margin, 2) AS v
  FROM SEMANTIC_VIEW(TPCH_DEMO.SEMANTIC.SV_SALES_FULFILMENT
    DIMENSIONS parts.manufacturer
    METRICS order_lines.total_gross_margin)),
q10_ref AS (
  SELECT manufacturer, ROUND(SUM(gross_margin), 2) AS v
  FROM ref_base GROUP BY 1)

SELECT 1 AS q, 'Revenue by region, 1995' AS question,
  (SELECT COUNT(*) FROM q1_sv) AS rows_in_semantic_view,
  (SELECT COUNT(*) FROM (SELECT * FROM q1_sv MINUS SELECT * FROM q1_ref))
+ (SELECT COUNT(*) FROM (SELECT * FROM q1_ref MINUS SELECT * FROM q1_sv)) AS rows_with_difference
UNION ALL SELECT 2, 'Top 5 customer nations by revenue',
  (SELECT COUNT(*) FROM q2_sv),
  (SELECT COUNT(*) FROM (SELECT * FROM q2_sv MINUS SELECT * FROM q2_ref))
+ (SELECT COUNT(*) FROM (SELECT * FROM q2_ref MINUS SELECT * FROM q2_sv))
UNION ALL SELECT 3, 'Top 5 supplier nations by late rate',
  (SELECT COUNT(*) FROM q3_sv),
  (SELECT COUNT(*) FROM (SELECT * FROM q3_sv MINUS SELECT * FROM q3_ref))
+ (SELECT COUNT(*) FROM (SELECT * FROM q3_ref MINUS SELECT * FROM q3_sv))
UNION ALL SELECT 4, 'Average discount by segment',
  (SELECT COUNT(*) FROM q4_sv),
  (SELECT COUNT(*) FROM (SELECT * FROM q4_sv MINUS SELECT * FROM q4_ref))
+ (SELECT COUNT(*) FROM (SELECT * FROM q4_ref MINUS SELECT * FROM q4_sv))
UNION ALL SELECT 5, 'Monthly revenue in Europe',
  (SELECT COUNT(*) FROM q5_sv),
  (SELECT COUNT(*) FROM (SELECT * FROM q5_sv MINUS SELECT * FROM q5_ref))
+ (SELECT COUNT(*) FROM (SELECT * FROM q5_ref MINUS SELECT * FROM q5_sv))
UNION ALL SELECT 6, 'Top 10 brands by gross margin',
  (SELECT COUNT(*) FROM q6_sv),
  (SELECT COUNT(*) FROM (SELECT * FROM q6_sv MINUS SELECT * FROM q6_ref))
+ (SELECT COUNT(*) FROM (SELECT * FROM q6_ref MINUS SELECT * FROM q6_sv))
UNION ALL SELECT 7, 'Urgent orders per year',
  (SELECT COUNT(*) FROM q7_sv),
  (SELECT COUNT(*) FROM (SELECT * FROM q7_sv MINUS SELECT * FROM q7_ref))
+ (SELECT COUNT(*) FROM (SELECT * FROM q7_ref MINUS SELECT * FROM q7_sv))
UNION ALL SELECT 8, 'Ship mode with most late lines',
  (SELECT COUNT(*) FROM q8_sv),
  (SELECT COUNT(*) FROM (SELECT * FROM q8_sv MINUS SELECT * FROM q8_ref))
+ (SELECT COUNT(*) FROM (SELECT * FROM q8_ref MINUS SELECT * FROM q8_sv))
UNION ALL SELECT 9, 'Top 5 customers by revenue',
  (SELECT COUNT(*) FROM q9_sv),
  (SELECT COUNT(*) FROM (SELECT * FROM q9_sv MINUS SELECT * FROM q9_ref))
+ (SELECT COUNT(*) FROM (SELECT * FROM q9_ref MINUS SELECT * FROM q9_sv))
UNION ALL SELECT 10, 'Gross margin by manufacturer',
  (SELECT COUNT(*) FROM q10_sv),
  (SELECT COUNT(*) FROM (SELECT * FROM q10_sv MINUS SELECT * FROM q10_ref))
+ (SELECT COUNT(*) FROM (SELECT * FROM q10_ref MINUS SELECT * FROM q10_sv))
ORDER BY 1