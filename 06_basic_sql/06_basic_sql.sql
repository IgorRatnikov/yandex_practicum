---
SELECT *
FROM company
WHERE status = 'closed';

---
SELECT funding_total
FROM company
WHERE category_code = 'news'
AND country_code = 'USA'
ORDER BY funding_total DESC;

---
SELECT SUM(price_amount)
FROM acquisition
WHERE term_code = 'cash'
AND acquired_at BETWEEN '2011-01-01' AND '2013-12-31'; 

---
SELECT first_name, last_name, network_username
FROM people
WHERE network_username LIKE 'Silver%';

---
SELECT *
FROM people
WHERE network_username LIKE '%money%'
AND last_name LIKE 'K%';

---
SELECT country_code, SUM(funding_total)
FROM company
GROUP BY country_code
ORDER BY SUM(funding_total) DESC;

---
SELECT funded_at,
       MIN(raised_amount),
       MAX(raised_amount)
FROM funding_round
GROUP BY funded_at
HAVING MIN(raised_amount) != 0
AND MIN(raised_amount) != MAX(raised_amount);

---
SELECT *,
       CASE
           WHEN invested_companies < 20 THEN 'low_activity'
           WHEN invested_companies >= 20 AND invested_companies < 100 THEN 'middle_activity'
           WHEN invested_companies >= 100 THEN 'high_activity'
       END
FROM fund;

---
SELECT ROUND(AVG(investment_rounds)),
       CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity
FROM fund
GROUP BY activity
ORDER BY ROUND(AVG(investment_rounds)) ASC;

---
SELECT country_code, -- таблица company
       MIN(invested_companies), -- таблица fund
       MAX(invested_companies), -- таблица fund
       AVG(invested_companies) -- таблица fund
FROM fund
WHERE founded_at BETWEEN '2010-01-01' AND '2012-12-31'
GROUP BY country_code
HAVING MIN(invested_companies) > 0
ORDER BY AVG(invested_companies) DESC, country_code ASC
LIMIT 10;

---
SELECT p.first_name,
       p.last_name,
       e.instituition
FROM people AS p
LEFT JOIN education AS e ON p.id = e.person_id;

---
SELECT c.name,
       COUNT(DISTINCT e.instituition)
FROM company AS c
INNER JOIN people AS p ON p.company_id = c.id
INNER JOIN education AS e ON e.person_id = p.id
GROUP BY c.name
ORDER BY COUNT(DISTINCT e.instituition) DESC
LIMIT 5;

---
SELECT DISTINCT c.name
FROM company AS c
INNER JOIN funding_round AS f ON f.company_id = c.id
WHERE c.status = 'closed'
AND f.is_last_round = 1
AND f.is_first_round = 1;

---
SELECT DISTINCT p.id
FROM (SELECT DISTINCT c.id
      FROM company AS c
      INNER JOIN funding_round AS f ON f.company_id = c.id
      WHERE c.status = 'closed'
      AND f.is_last_round = 1
      AND f.is_first_round = 1) AS t
INNER JOIN people AS p ON p.company_id = t.id;

---
SELECT DISTINCT p.id, e.instituition
FROM (SELECT DISTINCT c.id
      FROM company AS c
      INNER JOIN funding_round AS f ON f.company_id = c.id
      WHERE c.status = 'closed'
      AND f.is_last_round = 1
      AND f.is_first_round = 1) AS t
INNER JOIN people AS p ON p.company_id = t.id
INNER JOIN education AS e ON e.person_id = p.id;


---
SELECT p.id, COUNT(e.instituition)
FROM (SELECT DISTINCT c.id
      FROM company AS c
      INNER JOIN funding_round AS f ON f.company_id = c.id
      WHERE c.status = 'closed'
      AND f.is_last_round = 1
      AND f.is_first_round = 1) AS t
INNER JOIN people AS p ON p.company_id = t.id
INNER JOIN education AS e ON e.person_id = p.id
GROUP BY p.id;

---
SELECT p.id, COUNT(e.instituition)
FROM (SELECT DISTINCT c.id
      FROM company AS c
      INNER JOIN funding_round AS f ON f.company_id = c.id
      WHERE c.status = 'closed'
      AND f.is_last_round = 1
      AND f.is_first_round = 1) AS t
INNER JOIN people AS p ON p.company_id = t.id
INNER JOIN education AS e ON e.person_id = p.id
GROUP BY p.id;

---
SELECT AVG(count_inst)
FROM (SELECT p.id, COUNT(e.instituition) AS count_inst
      FROM (SELECT c.id
            FROM company AS c
            WHERE c.name = 'Socialnet') AS t
      INNER JOIN people AS p ON p.company_id = t.id
      INNER JOIN education AS e ON e.person_id = p.id
      GROUP BY p.id) AS avg_inst;

---
SELECT f.name AS name_of_fund,
       c.name AS name_of_company,
       fr.raised_amount AS amount
FROM investment AS i 
LEFT JOIN company AS c ON c.id = i.company_id
LEFT JOIN fund AS f ON f.id = i.fund_id
INNER JOIN funding_round AS fr ON fr.id = i.funding_round_id
WHERE c.milestones > 6
AND funded_at BETWEEN '2012-01-01' AND '2013-12-31';

---
SELECT c1.name,
       a.price_amount,
       c2.name,
       c2.funding_total,
       ROUND(a.price_amount / c2.funding_total)
FROM acquisition AS a
JOIN company AS c1 ON c1.id = a.acquiring_company_id
JOIN company AS c2 ON c2.id = a.acquired_company_id
WHERE a.price_amount > 0
AND c2.funding_total > 0
ORDER BY a.price_amount DESC, c2.name ASC
LIMIT 10;

---
SELECT c.name,
       EXTRACT(MONTH FROM f.funded_at)
FROM company AS c JOIN funding_round AS f ON c.id = f.company_id
WHERE c.category_code = 'social'
AND f.funded_at BETWEEN '2010-01-01' AND '2013-12-31'
AND f.raised_amount > 0;

---
WITH month_fund AS (SELECT EXTRACT(MONTH FROM fr.funded_at) AS MONTH,
                           COUNT(DISTINCT f.name) AS count_of_fund
                    FROM funding_round AS fr 
                    LEFT JOIN investment AS i ON i.funding_round_id = fr.id
                    LEFT JOIN fund AS f ON i.fund_id = f.id
                    WHERE EXTRACT(YEAR FROM fr.funded_at) BETWEEN 2010 AND 2013 
                     AND f.country_code = 'USA'
                    GROUP BY MONTH),
    month_acquired AS (SELECT EXTRACT(MONTH FROM acquired_at) AS MONTH,
                              COUNT(acquired_company_id) AS count_of_acquired,
                              SUM(price_amount) AS sum_of_acquired
                       FROM acquisition
                       WHERE EXTRACT(YEAR FROM acquired_at) BETWEEN 2010 AND 2013 
                       GROUP BY MONTH)
SELECT month_fund.MONTH,
       month_fund.count_of_fund,
       month_acquired.count_of_acquired,
       month_acquired.sum_of_acquired
FROM month_fund JOIN month_acquired ON month_fund.MONTH = month_acquired.MONTH;

WITH
inv_2011 AS (SELECT country_code,
                    AVG(funding_total) AS year_2011
             FROM company
             WHERE EXTRACT(YEAR FROM founded_at) = 2011
             GROUP BY country_code),
inv_2012 AS (SELECT country_code,
                    AVG(funding_total) AS year_2012
             FROM company
             WHERE EXTRACT(YEAR FROM founded_at) = 2012
             GROUP BY country_code),
inv_2013 AS (SELECT country_code,
                    AVG(funding_total) AS year_2013
             FROM company
             WHERE EXTRACT(YEAR FROM founded_at) = 2013
             GROUP BY country_code)
SELECT inv_2011.country_code,
       inv_2011.year_2011,
       inv_2012.year_2012,
       inv_2013.year_2013
FROM inv_2011
INNER JOIN inv_2012 ON inv_2011.country_code = inv_2012.country_code
INNER JOIN inv_2013 ON inv_2012.country_code = inv_2013.country_code
ORDER BY inv_2011.year_2011 DESC;
