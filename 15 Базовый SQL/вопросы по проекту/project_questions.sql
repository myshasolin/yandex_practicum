/*
1.
Посчитайте, сколько компаний закрылось.
*/
SELECT 
    COUNT(*) 
FROM company
WHERE status = 'closed';

/*
2.
Отобразите количество привлечённых средств для новостных компаний США. Используйте данные из таблицы company. 
Отсортируйте таблицу по убыванию значений в поле funding_total .
*/
SELECT 
    funding_total
FROM company
WHERE country_code = 'USA' AND category_code = 'news'
ORDER BY funding_total DESC;

/*
3.
Найдите общую сумму сделок по покупке одних компаний другими в долларах. Отберите сделки, 
которые осуществлялись только за наличные с 2011 по 2013 год включительно.
*/
SELECT
    SUM(price_amount)
FROM acquisition
WHERE 
    term_code = 'cash' AND 
    EXTRACT(YEAR FROM acquired_at) BETWEEN 2011 AND 2013;

/*
4.
Отобразите имя, фамилию и названия аккаунтов людей в твиттере, у которых названия аккаунтов начинаются на 'Silver'.
*/
SELECT
    first_name,
    last_name,
    twitter_username
FROM people
WHERE twitter_username LIKE 'Silver%';

/*
5.
Выведите на экран всю информацию о людях, у которых названия аккаунтов в твиттере содержат 
подстроку 'money', а фамилия начинается на 'K'.
*/
SELECT 
    *
FROM people
WHERE twitter_username LIKE '%money%' AND last_name LIKE 'K%';

/*
6.
Для каждой страны отобразите общую сумму привлечённых инвестиций, которые получили компании, зарегистрированные 
в этой стране. Страну, в которой зарегистрирована компания, можно определить по коду страны. Отсортируйте данные по убыванию суммы.
*/
SELECT 
    country_code,
    SUM(funding_total)
FROM company
GROUP BY country_code
ORDER BY SUM(funding_total) DESC;

/*
7.
Составьте таблицу, в которую войдёт дата проведения раунда, а также минимальное и максимальное значения суммы инвестиций, привлечённых в эту дату.
Оставьте в итоговой таблице только те записи, в которых минимальное значение суммы инвестиций не равно нулю и не равно максимальному значению.
*/
SELECT
    funded_at,
    MIN(raised_amount),
    MAX(raised_amount)
FROM funding_round
GROUP BY funded_at
HAVING MIN(raised_amount) <> 0 AND (MIN(raised_amount) <> MAX(raised_amount));

/*
8.
Создайте поле с категориями:
    - Для фондов, которые инвестируют в 100 и более компаний, назначьте категорию high_activity.
    - Для фондов, которые инвестируют в 20 и более компаний до 100, назначьте категорию middle_activity.
    - Если количество инвестируемых компаний фонда не достигает 20, назначьте категорию low_activity.
Отобразите все поля таблицы fund и новое поле с категориями.
*/
SELECT 
    *,
    CASE
        WHEN invested_companies >= 100 THEN 'high_activity'
        WHEN invested_companies >= 20 AND invested_companies < 100 THEN 'middle_activity'
        ELSE 'low_activity'
    END
FROM fund;

/*
9.
Для каждой из категорий, назначенных в предыдущем задании, посчитайте округлённое до ближайшего целого 
числа среднее количество инвестиционных раундов, в которых фонд принимал участие. Выведите на экран 
категории и среднее число инвестиционных раундов. Отсортируйте таблицу по возрастанию среднего.
*/
WITH get_fund AS (
	SELECT *,
	       CASE
	           WHEN invested_companies>=100 THEN 'high_activity'
	           WHEN invested_companies>=20 THEN 'middle_activity'
	           ELSE 'low_activity'
	       END AS activity
	FROM fund
)

SELECT 
    activity,
    ROUND(AVG(investment_rounds)) AS avg_investment_rounds
FROM get_fund
GROUP BY activity
ORDER BY avg_investment_rounds;

/*
10.
Проанализируйте, в каких странах находятся фонды, которые чаще всего инвестируют в стартапы. 
Для каждой страны посчитайте минимальное, максимальное и среднее число компаний, в которые инвестировали фонды 
этой страны, основанные с 2010 по 2012 год включительно. Исключите страны с фондами, у которых минимальное 
число компаний, получивших инвестиции, равно нулю. 
Выгрузите десять самых активных стран-инвесторов: отсортируйте таблицу по среднему количеству компаний 
от большего к меньшему. Затем добавьте сортировку по коду страны в лексикографическом порядке.
*/
SELECT 
    country_code AS country,
    MIN(invested_companies) AS min_cnt,
    MAX(invested_companies) AS max_cnt,
    AVG(invested_companies) AS mean_cnt
FROM fund
WHERE EXTRACT(YEAR FROM founded_at) BETWEEN 2010 AND 2012
GROUP BY country_code
HAVING MIN(invested_companies) <> 0
ORDER BY mean_cnt DESC, country
LIMIT 10;

/*
11.
Отобразите имя и фамилию всех сотрудников стартапов. Добавьте поле с названием 
учебного заведения, которое окончил сотрудник, если эта информация известна.
*/
SELECT 
    p.first_name,
    p.last_name,
    e.instituition
FROM people AS p
LEFT JOIN education AS e ON e.person_id = p.id;

/*
12.
Для каждой компании найдите количество учебных заведений, которые окончили её сотрудники. 
Выведите название компании и число уникальных названий учебных заведений. 
Составьте топ-5 компаний по количеству университетов.
*/
SELECT
    c.name,
    COUNT(DISTINCT e.instituition) AS cnt_instituition
FROM company AS c 
JOIN people as p ON p.company_id = c.id
JOIN education AS e ON e.person_id = p.id
GROUP BY c.name
ORDER BY cnt_instituition DESC
LIMIT 5;

/*
13.
Составьте список с уникальными названиями закрытых компаний, для которых первый раунд финансирования оказался последним.
*/
SELECT DISTINCT
    c.name 
FROM company AS c
JOIN funding_round AS f ON f.company_id = c.id
WHERE 
    c.status = 'closed' AND
    f.is_first_round = 1 AND
    f.is_last_round  = 1;

/*
14.
Составьте список уникальных номеров сотрудников, которые работают в компаниях, отобранных в предыдущем задании.
*/
SELECT DISTINCT
    p.id
FROM company AS c
JOIN funding_round AS f ON f.company_id = c.id
JOIN people AS p ON p.company_id = c.id
WHERE 
    c.status = 'closed' AND
    f.is_first_round = 1 AND
    f.is_last_round  = 1;

/*
15.
Составьте таблицу, куда войдут уникальные пары с номерами сотрудников из предыдущей задачи 
и учебным заведением, которое окончил сотрудник.
*/
SELECT DISTINCT
    p.id AS person_id,
    e.instituition AS education
FROM company AS c
JOIN funding_round AS f ON f.company_id = c.id
JOIN people AS p ON p.company_id = c.id
JOIN education AS e ON e.person_id = p.id
WHERE 
    c.status = 'closed' AND
    f.is_first_round = 1 AND
    f.is_last_round  = 1;

/*
16.
Посчитайте количество учебных заведений для каждого сотрудника из предыдущего задания. 
При подсчёте учитывайте, что некоторые сотрудники могли окончить одно и то же заведение дважды.
*/
SELECT DISTINCT
    p.id AS person_id,
    COUNT(DISTINCT e.id) AS cnt_education
FROM company AS c
JOIN funding_round AS f ON f.company_id = c.id
JOIN people AS p ON p.company_id = c.id
JOIN education AS e ON e.person_id = p.id
WHERE 
    c.status = 'closed' AND
    f.is_first_round = 1 AND
    f.is_last_round  = 1
GROUP BY p.id;

/*
17.
Дополните предыдущий запрос и выведите среднее число учебных заведений (всех, не только уникальных), 
которые окончили сотрудники разных компаний. Нужно вывести только одну запись, группировка здесь не понадобится.
*/
SELECT AVG(t.cnt_education) FROM (
	SELECT DISTINCT
	    p.id AS person_id,
	    COUNT(DISTINCT e.id) AS cnt_education
	FROM company AS c
	JOIN funding_round AS f ON f.company_id = c.id
	JOIN people AS p ON p.company_id = c.id
	JOIN education AS e ON e.person_id = p.id
	WHERE 
	    c.status = 'closed' AND
	    f.is_first_round = 1 AND
	    f.is_last_round  = 1
	GROUP BY p.id
	) AS t;

/*
18.
Напишите похожий запрос: выведите среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники Facebook*.
*(сервис, запрещённый на территории РФ)
*/
SELECT AVG(t.cnt_education) FROM (
	SELECT DISTINCT
	    p.id AS person_id,
	    COUNT(DISTINCT e.id) AS cnt_education
	FROM company AS c
	JOIN funding_round AS f ON f.company_id = c.id
	JOIN people AS p ON p.company_id = c.id
	JOIN education AS e ON e.person_id = p.id
	WHERE 
	    c.name = 'Facebook'
	GROUP BY p.id
	) AS t;

/*
19.
Составьте таблицу из полей:
    - name_of_fund — название фонда;
    - name_of_company — название компании;
    - amount — сумма инвестиций, которую привлекла компания в раунде.
В таблицу войдут данные о компаниях, в истории которых было больше шести важных этапов, 
а раунды финансирования проходили с 2012 по 2013 год включительно.
*/
SELECT DISTINCT
    f.name AS name_of_fund,
    c.name AS name_of_company,
    fr.raised_amount 
FROM fund AS f
JOIN investment AS i ON i.fund_id = f.id
JOIN funding_round AS fr ON fr.id = i.funding_round_id
JOIN company as c ON c.id = i.company_id
WHERE 
    c.milestones > 6 AND 
    (EXTRACT(YEAR FROM fr.funded_at) BETWEEN 2012 AND 2013);

/*
20.
Выгрузите таблицу, в которой будут такие поля:
    - название компании-покупателя;
    - сумма сделки;
    - название компании, которую купили;
    - сумма инвестиций, вложенных в купленную компанию;
    - доля, которая отображает, во сколько раз сумма покупки превысила сумму вложенных 
      в компанию инвестиций, округлённая до ближайшего целого числа.
Не учитывайте те сделки, в которых сумма покупки равна нулю. Если сумма инвестиций 
в компанию равна нулю, исключите такую компанию из таблицы. 
Отсортируйте таблицу по сумме сделки от большей к меньшей, а затем по названию купленной компании 
в лексикографическом порядке. Ограничьте таблицу первыми десятью записями.
*/
WITH 
buyer AS (
	SELECT
	    a_buyer.id AS id_bayer,
	    c_buyer.name AS name_bayer,
	    a_buyer.price_amount AS price_bayer
	FROM company AS c_buyer
	JOIN acquisition AS a_buyer ON a_buyer.acquiring_company_id = c_buyer.id
	WHERE a_buyer.price_amount > 0
),
seller AS (
	SELECT
	    a_seller.id AS id_seller,
	    c_seller.name AS name_seller,
	    c_seller.funding_total AS invest
	FROM company AS c_seller
	JOIN acquisition AS a_seller ON a_seller.acquired_company_id = c_seller.id
	WHERE c_seller.funding_total > 0
)

SELECT 
    name_bayer,
    price_bayer,
    name_seller,
    invest,
    ROUND(price_bayer / invest) AS profit
FROM buyer AS b
JOIN seller AS s ON b.id_bayer = s.id_seller
ORDER BY price_bayer DESC, name_seller
LIMIT 10;

/*
21.
Выгрузите таблицу, в которую войдут названия компаний из категории social, получившие финансирование 
с 2010 по 2013 год включительно. Проверьте, что сумма инвестиций не равна нулю. 
Выведите также номер месяца, в котором проходил раунд финансирования.
*/
SELECT 
    c.name AS name_company,
    EXTRACT(MONTH FROM f.funded_at) AS month_funding
FROM company AS c
JOIN funding_round AS f ON f.company_id = c.id
WHERE 
    category_code  = 'social' AND
    (EXTRACT(YEAR FROM f.funded_at) BETWEEN 2010 AND 2013) AND
    f. raised_amount <> 0;

/*
22.
Отберите данные по месяцам с 2010 по 2013 год, когда проходили инвестиционные раунды. 
Сгруппируйте данные по номеру месяца и получите таблицу, в которой будут поля:
    - номер месяца, в котором проходили раунды;
    - количество уникальных названий фондов из США, которые инвестировали в этом месяце;
    - количество компаний, купленных за этот месяц;
    - общая сумма сделок по покупкам в этом месяце.
*/
WITH 
fundings AS (
    SELECT 
        EXTRACT(MONTH FROM CAST(fr.funded_at AS DATE)) AS months,
        COUNT(DISTINCT f.id) AS count_name
    FROM 
        fund AS f
        LEFT JOIN investment AS i ON f.id = i.fund_id
        LEFT JOIN funding_round AS fr ON i.funding_round_id = fr.id
    WHERE 
        f.country_code = 'USA'
        AND EXTRACT(YEAR FROM CAST(fr.funded_at AS DATE)) BETWEEN 2010 AND 2013
    GROUP BY 
        months
),
acquisitions AS (
    SELECT 
        EXTRACT(MONTH FROM CAST(acquired_at AS DATE)) AS months,
        COUNT(acquired_company_id) AS seller,
        SUM(price_amount) AS sum_total
    FROM 
        acquisition
    WHERE 
        EXTRACT(YEAR FROM CAST(acquired_at AS DATE)) BETWEEN 2010 AND 2013
    GROUP BY 
        months
)
    
SELECT 
    f.months, 
    f.count_name, 
    COALESCE(a.seller, 0) AS seller, 
    COALESCE(a.sum_total, 0) AS sum_total
FROM 
    fundings f
    LEFT JOIN acquisitions a ON f.months = a.months;

/*
23.
Составьте сводную таблицу и выведите среднюю сумму инвестиций для стран, в которых есть стартапы, 
зарегистрированные в 2011, 2012 и 2013 годах. Данные за каждый год должны быть в отдельном поле. 
Отсортируйте таблицу по среднему значению инвестиций за 2011 год от большего к меньшему.
*/
WITH
mean_funding_total_2011 AS (
	SELECT
	    country_code,
	    AVG(funding_total) AS mean_2011
	FROM company
	WHERE EXTRACT(YEAR FROM founded_at) = 2011
	GROUP BY country_code
),
mean_funding_total_2012 AS (
	SELECT
	    country_code,
	    AVG(funding_total) AS mean_2012
	FROM company
	WHERE EXTRACT(YEAR FROM founded_at) = 2012
	GROUP BY country_code
	),
mean_funding_total_2013 AS (
	SELECT
	    country_code,
	    AVG(funding_total) AS mean_2013
	FROM company
	WHERE EXTRACT(YEAR FROM founded_at) = 2013
	GROUP BY country_code
)

SELECT
    s_2011.country_code,
    mean_2011,
    mean_2012,
    mean_2013
FROM mean_funding_total_2011 AS s_2011
JOIN mean_funding_total_2012 AS s_2012 ON s_2012.country_code = s_2011.country_code
JOIN mean_funding_total_2013 AS s_2013 ON s_2013.country_code = s_2011.country_code
ORDER BY mean_2011 DESC;
