---
SELECT COUNT(pt.id)
FROM stackoverflow.post_types pt
JOIN stackoverflow.posts p ON p.post_type_id = pt.id
WHERE pt.type = 'Question'
AND score > 300 OR favorites_count >= 100;

---
SELECT ROUND(AVG(cnt)) AS avg_count
FROM (SELECT COUNT(id) AS cnt,
             EXTRACT(DAY FROM creation_date) AS DAY
      FROM stackoverflow.posts
      WHERE post_type_id = 1
      AND DATE_TRUNC('day', creation_date) BETWEEN '2008-11-01' AND '2008-11-18'
      GROUP BY DAY) AS е;

---
SELECT COUNT(DISTINCT b.user_id)
FROM stackoverflow.badges b
JOIN stackoverflow.users u ON u.id = b.user_id
WHERE u.creation_date::date = b.creation_date::date;

---
SELECT COUNT(DISTINCT p.id)
FROM stackoverflow.posts p
JOIN stackoverflow.votes AS v ON p.id = v.post_id
JOIN stackoverflow.users AS u ON p.user_id = u.id
WHERE display_name = 'Joel Coehoorn'
HAVING COUNT(DISTINCT v.id) >= 1;

---
SELECT *,
       RANK() OVER (ORDER BY id DESC)
FROM stackoverflow.vote_types
ORDER BY id;

---
SELECT u.id,
       COUNT(v.id)
FROM stackoverflow.users u
JOIN stackoverflow.votes v ON u.id = v.user_id
JOIN stackoverflow.vote_types vt ON vt.id = v.vote_type_id
WHERE vt.name = 'Close'
GROUP BY u.id
ORDER BY COUNT(v.id) DESC, u.id DESC
LIMIT 10;

---
SELECT u.id AS id_user,
       COUNT(b.id) AS count_badges,
       DENSE_RANK() OVER (ORDER BY COUNT(b.id) DESC) AS place_rating
FROM stackoverflow.users u
JOIN stackoverflow.badges b ON u.id = b.user_id
WHERE DATE_TRUNC('day', b.creation_date) BETWEEN '2008-11-15' AND '2008-12-15'
GROUP BY id_user
ORDER BY COUNT(b.id) DESC, u.id
LIMIT 10;

---
SELECT p.title,
       u.id,
       p.score,
       ROUND(AVG(p.score) OVER (PARTITION BY u.id))
FROM stackoverflow.posts p
JOIN stackoverflow.users u ON u.id = p.user_id
WHERE p.title IS NOT NULL
AND p.score != 0

---
SELECT p.title
FROM stackoverflow.posts p
JOIN stackoverflow.users u ON u.id = p.user_id
JOIN  stackoverflow.badges b ON u.id = b.user_id
WHERE p.title IS NOT NULL
GROUP BY p.title
HAVING COUNT(b.user_id) > 1000;   

---
SELECT id,
       views,
       CASE
           WHEN views >= 350 THEN 1
           WHEN views < 350 AND views >= 100 THEN 2
           WHEN views < 100 THEN 3
       END
FROM stackoverflow.users
WHERE views > 0
AND location LIKE '%Canada%';

---
WITH categories AS (
    SELECT id,
           views,
           CASE
               WHEN views >= 350 THEN 1
               WHEN views < 350 AND views >= 100 THEN 2
               WHEN views < 100 THEN 3
           END AS category,
           MAX(views) OVER (PARTITION BY CASE
                                          WHEN views >= 350 THEN 1
                                          WHEN views < 350 AND views >= 100 THEN 2
                                          WHEN views < 100 THEN 3
                                       END) AS max_views
    FROM stackoverflow.users
    WHERE views > 0
    AND location LIKE '%Canada%'
)

SELECT id, views, category
FROM categories
WHERE views = max_views
ORDER BY views DESC, id ASC;

---
SELECT EXTRACT(DAY FROM creation_date::date),
       COUNT(id),
       SUM(COUNT(id)) OVER (ORDER BY EXTRACT(DAY FROM creation_date::date))
FROM stackoverflow.users
WHERE creation_date::date BETWEEN '2008-11-01' AND '2008-11-30'
GROUP BY EXTRACT(DAY FROM creation_date::date);

---
WITH raw AS (SELECT user_id,
                    p.creation_date AS frst,
                    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY p.creation_date) AS number_temp,
                    u.creation_date AS reg 
             FROM stackoverflow.posts AS p JOIN stackoverflow.users AS u ON p.user_id = u.id 
             ORDER BY user_id)
SELECT user_id,
       frst - reg
FROM raw
WHERE number_temp = 1;
---
SELECT SUM(views_count),
       DATE_TRUNC('month', creation_date )::date
FROM stackoverflow.posts
WHERE DATE_TRUNC('month', creation_date )::date BETWEEN '2008-01-01' AND '2008-12-31'
GROUP BY DATE_TRUNC('month', creation_date )::date
ORDER BY SUM(views_count) DESC;

---
SELECT u.display_name,
       COUNT(DISTINCT p.user_id)
FROM stackoverflow.users u
JOIN stackoverflow.posts p ON u.id = p.user_id
JOIN stackoverflow.post_types pt ON pt.id = p.post_type_id
WHERE pt.type = 'Answer'
AND p.creation_date::date BETWEEN u.creation_date::date AND (u.creation_date::date + INTERVAL '1 month')
GROUP BY u.display_name
HAVING COUNT(pt.id) > 100
ORDER BY u.display_name ASC;

---
WITH december AS (SELECT u.id
                  FROM stackoverflow.posts p
                  JOIN stackoverflow.users u ON u.id = p.user_id
                  WHERE p.creation_date::date BETWEEN '2008-12-01' AND '2008-12-31'
                  AND u.creation_date::date BETWEEN '2008-09-01' AND '2008-09-30'
                  GROUP BY u.id
                  HAVING COUNT(p.id) > 0)

SELECT COUNT(p.id) AS count_posts,
       DATE_TRUNC('month', p.creation_date)::date AS months
FROM stackoverflow.posts p
WHERE p.creation_date::date BETWEEN '2008-01-01' AND '2008-12-31'
AND p.user_id IN (SELECT * FROM december)
GROUP BY months
ORDER BY months DESC;
---
SELECT user_id,
       creation_date,
       views_count,
       SUM(views_count) OVER (PARTITION BY user_id ORDER BY creation_date ASC)
FROM stackoverflow.posts p
ORDER BY user_id ASC;

---
WITH t AS (SELECT COUNT(DISTINCT creation_date::date) AS count_day,
                  user_id
           FROM stackoverflow.posts
           WHERE creation_date::date BETWEEN '2008-12-01' AND '2008-12-07'
           GROUP BY user_id
           HAVING COUNT(creation_date::date) > 0)

SELECT ROUND(AVG(t.count_day))
FROM t;
---
WITH t AS (SELECT EXTRACT(MONTH FROM creation_date::date) AS month,
                  COUNT(id) AS count_posts
           FROM stackoverflow.posts
           WHERE creation_date::date BETWEEN '2008-09-01' AND '2008-12-31'
           GROUP BY month)
           
SELECT *,
       ROUND((count_posts::numeric / LAG(count_posts) OVER (ORDER BY month) - 1)*100, 2)
FROM t;
---
WITH t AS (SELECT DISTINCT ps.user_id,
                  COUNT(ps.id) AS count_posts
           FROM stackoverflow.posts AS ps
           GROUP BY user_id
           ORDER BY count_posts DESC
           LIMIT 1)

SELECT DISTINCT EXTRACT(WEEK FROM ps.creation_date) AS weeks,
       MAX(ps.creation_date)
FROM stackoverflow.posts AS ps
RIGHT JOIN t AS t ON ps.user_id = t.user_id
WHERE ps.creation_date::date BETWEEN '2008-10-01' AND '2008-10-31'
GROUP BY weeks;
