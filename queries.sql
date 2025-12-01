Этот запрос считает общее количество покупателей в таблице customers
SELECT COUNT(*) AS customers_count
FROM customers;
Топ-10 продавцов по суммарной выручке
SELECT
    CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
    COUNT(*) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales s
JOIN employees e ON s.sales_person_id = e.employee_id
JOIN products p ON s.product_id = p.product_id
GROUP BY seller
ORDER BY income DESC
LIMIT 10;
Продавцы с низкой средней выручкой за сделку
WITH per_seller AS (
    SELECT
        CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
        SUM(p.price * s.quantity) AS total_income,
        COUNT(*) AS operations,
        SUM(p.price * s.quantity) / COUNT(*) AS avg_income
    FROM sales s
    JOIN employees e ON s.sales_person_id = e.employee_id
    JOIN products p ON s.product_id = p.product_id
    GROUP BY seller
),
overall AS (
    SELECT AVG(avg_income) AS avg_all FROM per_seller
)
SELECT
    seller,
    FLOOR(avg_income) AS average_income
FROM per_seller, overall
WHERE avg_income < avg_all
ORDER BY average_income ASC;
Выручка по дням недели для каждого продавца
SELECT
    CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
    TRIM(TO_CHAR(s.sale_date, 'day')) AS day_of_week,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales s
JOIN employees e ON s.sales_person_id = e.employee_id
JOIN products p ON s.product_id = p.product_id
GROUP BY seller, day_of_week, EXTRACT(DOW FROM s.sale_date)
ORDER BY EXTRACT(DOW FROM s.sale_date), seller;
Отчёт 1 - Количество покупателей по возрастным группам 16-25, 26-40 и 40 +
Создаём категории возрастов, считаем количество людей в каждой группе
Отсортировано по возрастным группам

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

Отчёт 2 - Количество уникальных покупателей и выручка по месяцам
Группировка по дате в формате ГГГГ-ММ (YYYY-MM)
Выручка считается как SUM(price * quantity)

SELECT 
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    ROUND(SUM(p.price * s.quantity), 2) AS income
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY selling_month
ORDER BY selling_month;

Отчёт 3 - Покупатели, чья первая покупка была акционной (товар отпускался по цене 0)
Берём первую покупку каждого покупателя, затем выбираем только тех, где price = 0
special_offer.csv - Покупатели, чья первая покупка была по акции (цена = 0)
Ищем  покупателей, первая покупка которых была по нулевой цене.
Имя + фамилию покупателя.
Дату этой первой покупки.
Имя + фамилию продавца.
Сортировка по ID покупателя.

WITH first_sales AS (
    SELECT 
        s.customer_id,
        MIN(s.sale_date) AS first_sale_date
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    WHERE p.price = 0
    GROUP BY s.customer_id
)
SELECT 
    c.first_name || ' ' || c.last_name AS customer,
    fs.first_sale_date AS sale_date,
    e.first_name || ' ' || e.last_name AS seller
FROM first_sales fs
JOIN sales s ON fs.customer_id = s.customer_id AND fs.first_sale_date = s.sale_date
JOIN customers c ON fs.customer_id = c.customer_id
JOIN employees e ON s.sales_person_id = e.employee_id
ORDER BY fs.customer_id;




