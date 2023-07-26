CREATE DATABASE IF NOT EXISTS yandex_practicum;

/*
1.
Напишите запрос, который проранжирует расходы на привлечение пользователей за каждый день по убыванию. 
Выгрузите три поля: 
    - дата, которую нужно привести к типу date;
    - расходы на привлечение;
    - ранг строки.
*/
SELECT 
    CAST(created_at AS DATE),
    costs,
    ROW_NUMBER() OVER (ORDER BY costs DESC)
FROM tools_shop.costs;

/*
2.
Измените предыдущий запрос: записям с одинаковыми значениями расходов назначьте одинаковый ранг. Ранги не должны прерываться.
*/
SELECT 
    CAST(created_at AS DATE),
    costs,
    DENSE_RANK() OVER (ORDER BY costs DESC)
FROM tools_shop.costs;

/*
3.
Используя оконную функцию, выведите список уникальных user_id пользователей, которые совершили три заказа и более.
*/
WITH get_id AS (
	SELECT
	    user_id,
	    COUNT(*) OVER (PARTITION BY user_id) AS couns_orders
	FROM tools_shop.orders
)

SELECT DISTINCT
    user_id
FROM get_id
WHERE couns_orders >= 3;

/*
4.
Используя оконную функцию, выведите количество заказов, в которых было четыре товара и более.
 */
WITH count_orders AS (
	SELECT DISTINCT
	    items_cnt,
	    COUNT(*) OVER (PARTITION BY items_cnt)
	FROM tools_shop.orders
	ORDER BY items_cnt DESC
)

SELECT
    count
FROM count_orders
WHERE items_cnt = 4;

/*
5.
Рассчитайте количество зарегистрированных пользователей по месяцам с накоплением.
Выгрузите два поля:

    - месяц регистрации, приведённый к типу date;
    - общее количество зарегистрированных пользователей на текущий месяц.
*/
SELECT DISTINCT
    DATE_TRUNC('month', created_at)::DATE AS mm,
    COUNT(*) OVER(ORDER BY DATE_TRUNC('month', created_at))
FROM tools_shop.users
ORDER BY mm;

/*
6.
Рассчитайте сумму трат на привлечение пользователей с накоплением по месяцам c 2017 по 2018 год включительно.
Выгрузите два поля:

    - месяц, приведённый к типу date;
    - сумма трат на текущий месяц с накоплением.
*/
WITH spending_amount AS (
    SELECT DISTINCT
        DATE_TRUNC('month', MIN(created_at))::DATE AS months,
        SUM(costs) OVER (ORDER BY DATE_TRUNC('month', created_at)) AS total_costs
    FROM tools_shop.costs
    GROUP BY DATE_TRUNC('year', created_at), DATE_TRUNC('month', created_at), costs
    HAVING DATE_TRUNC('year', created_at) BETWEEN '2017-01-01' AND '2018-12-31'
)

SELECT months, total_costs
FROM spending_amount
ORDER BY months;

/*
7.
Посчитайте события с названием view_item по месяцам с накоплением. Рассчитайте количество событий только для тех пользователей, которые совершили хотя бы одну покупку.
Выгрузите поля: 

    - месяц события, приведённый к типу date;
    - количество событий за текущий месяц;
    - количество событий за текущий месяц с накоплением.
*/
WITH user_orders AS (
    SELECT DISTINCT user_id
    FROM tools_shop.orders
    WHERE paid_at IS NOT NULL
)

SELECT
    DATE_TRUNC('month', e.event_time)::DATE AS month,
    COUNT(*) AS events_count,
    SUM(COUNT(*)) OVER (ORDER BY date_trunc('month', e.event_time)::date) AS events_cumulative_count
FROM
    tools_shop.events AS e
    JOIN user_orders AS u ON e.user_id = u.user_id
WHERE
    e.event_name = 'view_item'
GROUP BY
    date_trunc('month', e.event_time)::DATE
ORDER BY
    month;
   
/*
8.
Используя конструкцию WINDOW, рассчитайте суммарную стоимость и количество заказов с накоплением от месяца к месяцу.
Выгрузите поля:

    идентификатор заказа;
    месяц оформления заказа, приведённый к типу date;
    сумма заказа;
    количество заказов с накоплением;
    суммарная стоимость заказов с накоплением.
*/
SELECT DISTINCT
    order_id,
    DATE_TRUNC('month', created_at)::DATE AS month,
    total_amt,
    SUM(COUNT(*)) OVER window_options AS orders_count,
    SUM(total_amt) OVER window_options AS total_amt_cumulative
FROM tools_shop.orders
GROUP BY order_id, DATE_TRUNC('month', created_at)::DATE, total_amt
WINDOW window_options AS (ORDER BY DATE_TRUNC('month', created_at)::DATE)
ORDER BY month;

/*
9.
Напишите запрос, который выведет сумму трат на привлечение пользователей по месяцам, а также разницу в тратах между текущим и предыдущим месяцами. Разница должна показывать, на сколько траты текущего месяца отличаются от предыдущего. В случае, если данных по предыдущему месяцу нет, укажите ноль.
Выгрузите поля:

    месяц, приведённый к типу date;
    траты на привлечение пользователей в текущем месяце;
    разница в тратах между текущим и предыдущим месяцами.
*/
WITH get_current_month AS (
SELECT DISTINCT
    DATE_TRUNC('month', created_at)::DATE AS month,
    SUM(costs) OVER (PARTITION BY DATE_TRUNC('month', created_at)::DATE) AS current_month
FROM tools_shop.costs
ORDER BY month
)

SELECT 
    *,  
    COALESCE(current_month - LAG(current_month) OVER(), 0) AS spending_difference
FROM get_current_month;

/*
10.
Напишите запрос, который выведет сумму выручки по годам и разницу выручки между текущим и следующим годом. Разница должна показывать, на сколько выручка следующего года отличается от текущего. В случае, если данных по следующему году нет, укажите ноль.
Выгрузите поля:

    год, приведённый к типу date;
    выручка за текущий год;
    разница в выручке между текущим и следующим годом.
 */
WITH get_current_year AS (
SELECT DISTINCT
    DATE_TRUNC('year', paid_at)::DATE AS year,
    SUM(total_amt) OVER (PARTITION BY DATE_TRUNC('year', paid_at)::DATE) AS current_year
FROM tools_shop.orders
ORDER BY year
)

SELECT 
    year,
    current_year,
    COALESCE(LEAD(current_year) OVER() - current_year, 0) AS next_year
FROM get_current_year;
