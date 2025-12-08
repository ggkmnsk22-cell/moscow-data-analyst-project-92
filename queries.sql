-- Количество покупателей
SELECT COUNT(*) AS customers_count
FROM customers;

-- Топ-10 продавцов по суммарной выручке
SELECT
    CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
    COUNT(*) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
INNER JOIN products AS p ON s.product_id = p.product_id
GROUP BY
    CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name))
ORDER BY income DESC
LIMIT 10;

-- Продавцы с низкой средней выручкой
WITH per_seller AS (
    SELECT
        CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
        SUM(p.price * s.quantity) AS total_income,
        COUNT(*) AS operations,
        SUM(p.price * s.quantity) / COUNT(*) AS avg_income
    FROM sales AS s
    INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
    INNER JOIN products AS p ON s.product_id = p.product_id
    GROUP BY CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name))
),

overall AS (
    SELECT AVG(per.avg_income) AS avg_all
    FROM per_seller AS per
)

SELECT
    per.seller,
    FLOOR(per.avg_income) AS average_income
FROM per_seller AS per
INNER JOIN overall ON TRUE
WHERE per.avg_income < overall.avg_all
ORDER BY average_income ASC;

-- Выручка по дням недели для каждого продавца
SELECT
    CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
    RTRIM(TO_CHAR(s.sale_date, 'day')) AS day_of_week,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
INNER JOIN products AS p ON s.product_id = p.product_id
GROUP BY
    CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)),
    RTRIM(TO_CHAR(s.sale_date, 'day')),
    EXTRACT(ISODOW FROM s.sale_date)
ORDER BY
    EXTRACT(ISODOW FROM s.sale_date),
    seller;

-- Отчёт 1 — Количество покупателей по возрастным группам
SELECT
    CASE
        WHEN c.age BETWEEN 16 AND 25 THEN '16-25'
        WHEN c.age BETWEEN 26 AND 40 THEN '26-40'
        WHEN c.age >= 41 THEN '40+'
    END AS age_category,
    COUNT(*) AS age_count
FROM customers AS c
GROUP BY
    CASE
        WHEN c.age BETWEEN 16 AND 25 THEN '16-25'
        WHEN c.age BETWEEN 26 AND 40 THEN '26-40'
        WHEN c.age >= 41 THEN '40+'
    END
ORDER BY
    CASE
        WHEN c.age BETWEEN 16 AND 25 THEN 1
        WHEN c.age BETWEEN 26 AND 40 THEN 2
        WHEN c.age >= 41 THEN 3
    END;

-- Отчёт 2 — Уникальные покупатели и выручка по месяцам
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN products AS p ON s.product_id = p.product_id
GROUP BY TO_CHAR(s.sale_date, 'YYYY-MM')
ORDER BY TO_CHAR(s.sale_date, 'YYYY-MM');

-- Отчёт 3 — Покупатели, чья первая покупка была акционной
WITH ordered_sales AS (
    SELECT
        s.customer_id,
        s.sale_date,
        s.product_id,
        s.sales_person_id,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id
            ORDER BY s.sale_date
        ) AS rn
    FROM sales AS s
),

first_sale AS (
    SELECT
        os.customer_id,
        os.sale_date,
        os.product_id,
        os.sales_person_id
    FROM ordered_sales AS os
    WHERE os.rn = 1
)

SELECT
    fs.sale_date,
    CONCAT(TRIM(c.first_name), ' ', TRIM(c.last_name)) AS customer,
    CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller
FROM first_sale AS fs
INNER JOIN products AS p ON fs.product_id = p.product_id
INNER JOIN customers AS c ON fs.customer_id = c.customer_id
INNER JOIN employees AS e ON fs.sales_person_id = e.employee_id
WHERE p.price = 0
ORDER BY fs.customer_id;