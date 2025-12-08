-- Этот запрос считает общее количество покупателей в таблице customers
SELECT COUNT(*) AS customers_count
FROM customers;

-- Топ-10 продавцов по суммарной выручке
SELECT
    CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
    COUNT(*) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
JOIN employees AS e ON s.sales_person_id = e.employee_id
JOIN products AS p ON s.product_id = p.product_id
GROUP BY seller
ORDER BY income DESC
LIMIT 10;

-- Продавцы с низкой средней выручкой за сделку
WITH per_seller AS (
    SELECT
        CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
        SUM(p.price * s.quantity) AS total_income,
        COUNT(*) AS operations,
        SUM(p.price * s.quantity) / COUNT(*) AS avg_income
    FROM sales AS s
    JOIN employees AS e ON s.sales_person_id = e.employee_id
    JOIN products AS p ON s.product_id = p.product_id
    GROUP BY seller
),

overall AS (
    SELECT AVG(avg_income) AS avg_all
    FROM per_seller
)

SELECT
    seller,
    FLOOR(avg_income) AS average_income
FROM per_seller
JOIN overall ON TRUE
WHERE avg_income < avg_all
ORDER BY average_income ASC;

-- Выручка по дням недели для каждого продавца
SELECT
    CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
    RTRIM(TO_CHAR(s.sale_date, 'day')) AS day_of_week,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
JOIN employees AS e ON s.sales_person_id = e.employee_id
JOIN products AS p ON s.product_id = p.product_id
GROUP BY
    seller,
    day_of_week,
    EXTRACT(ISODOW FROM s.sale_date)
ORDER BY
    EXTRACT(ISODOW FROM s.sale_date),
    seller;

-- Отчёт 1 — Количество покупателей по возрастным группам 16–25, 26–40 и 40+
-- Создаём категории возрастов, считаем количество людей в каждой группе
-- Отсортировано по возрастным группам

SELECT *
FROM (
    SELECT 
        CASE
            WHEN age BETWEEN 16 AND 25 THEN '16-25'
            WHEN age BETWEEN 26 AND 40 THEN '26-40'
            WHEN age >= 41 THEN '40+'
        END AS age_category,
        COUNT(*) AS age_count
    FROM customers
    GROUP BY age_category
) AS t
ORDER BY 
    CASE t.age_category
        WHEN '16-25' THEN 1
        WHEN '26-40' THEN 2
        WHEN '40+' THEN 3
    END;

-- Отчёт 2 — Количество уникальных покупателей и выручка по месяцам
-- Группировка по дате в формате YYYY-MM
-- Выручка считается как SUM(price * quantity)

SELECT 
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
JOIN products AS p ON s.product_id = p.product_id
GROUP BY selling_month
ORDER BY selling_month;

-- Отчёт 3 — Покупатели, чья первая покупка была акционной (price = 0)
-- Берём первую покупку каждого покупателя
-- Оставляем только тех, у кого price = 0
-- Выводим покупателя, дату покупки и продавца

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
    c.first_name || ' ' || c.last_name AS customer,
    fs.sale_date,
    e.first_name || ' ' || e.last_name AS seller
FROM first_sale AS fs
JOIN products AS p ON fs.product_id = p.product_id
JOIN customers AS c ON fs.customer_id = c.customer_id
JOIN employees AS e ON fs.sales_person_id = e.employee_id
WHERE p.price = 0
ORDER BY fs.customer_id;
