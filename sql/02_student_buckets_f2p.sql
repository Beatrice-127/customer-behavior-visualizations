/*
===============================================================================
02 - Student Buckets: F2P Conversion Rate
===============================================================================
Purpose:
    - Identify whether each student made a purchase (f2p = 1 if yes, else 0)
    - Compute total minutes watched from registration to first purchase
    - Segment students into engagement buckets based on watched time

Tables Used:
    - student_info
    - student_purchases
    - student_learning

SQL Features:
    - CTEs for modular logic
    - LEFT JOIN to preserve non-paying users
    - CASE WHEN for conditional metrics
    - Engagement bucket segmentation based on total_minutes_watched

Output Columns:
    - student_id
    - date_registered
    - f2p (1 if paid, 0 if not)
    - total_minutes_watched (rounded to 2 decimals)
    - bucket (string category)
===============================================================================
*/

WITH table_student_total_learn AS (
    SELECT
        i.student_id,
        i.date_registered,
        IFNULL(SUM(l.minutes_watched), 0) AS total_minutes_watched
    FROM student_info i
    LEFT JOIN student_learning l USING (student_id)
    GROUP BY i.student_id, i.date_registered
),

table_first_purchase AS (
    SELECT 
        student_id,
        MIN(date_purchased) AS date_first_purchased
    FROM student_purchases
    GROUP BY student_id
),

table_purchased_watch_time AS (
    SELECT
        p.student_id,
        p.date_first_purchased,
        ROUND(SUM(l.minutes_watched), 2) AS minutes_before_purchase
    FROM table_first_purchase p
    JOIN student_learning l
      ON p.student_id = l.student_id
     AND l.date_watched < p.date_first_purchased
    GROUP BY p.student_id, p.date_first_purchased
),

sum_table AS (
    SELECT
        t.student_id,
        t.date_registered,
        CASE WHEN f.student_id IS NOT NULL THEN 1 ELSE 0 END AS f2p,
        CASE
            WHEN f.student_id IS NULL THEN ROUND(t.total_minutes_watched, 2)
            ELSE ROUND(p.minutes_before_purchase, 2)
        END AS total_minutes_watched
    FROM table_student_total_learn t
    LEFT JOIN table_first_purchase f USING (student_id)
    LEFT JOIN table_purchased_watch_time p USING (student_id)
)

SELECT 
    student_id,
    date_registered,
    f2p,
    IFNULL(total_minutes_watched, 0) AS total_minutes_watched,
    CASE
        WHEN IFNULL(total_minutes_watched, 0) = 0 THEN '[0]'
        WHEN total_minutes_watched <= 5 THEN '(0, 5]'
        WHEN total_minutes_watched <= 10 THEN '(5, 10]'
        WHEN total_minutes_watched <= 15 THEN '(10, 15]'
        WHEN total_minutes_watched <= 20 THEN '(15, 20]'
        WHEN total_minutes_watched <= 25 THEN '(20, 25]'
        WHEN total_minutes_watched <= 30 THEN '(25, 30]'
        WHEN total_minutes_watched <= 40 THEN '(30, 40]'
        WHEN total_minutes_watched <= 50 THEN '(40, 50]'
        WHEN total_minutes_watched <= 60 THEN '(50, 60]'
        WHEN total_minutes_watched <= 70 THEN '(60, 70]'
        WHEN total_minutes_watched <= 80 THEN '(70, 80]'
        WHEN total_minutes_watched <= 90 THEN '(80, 90]'
        WHEN total_minutes_watched <= 100 THEN '(90, 100]'
        WHEN total_minutes_watched <= 110 THEN '(100, 110]'
        WHEN total_minutes_watched <= 120 THEN '(110, 120]'
        WHEN total_minutes_watched <= 240 THEN '(120, 240]'
        WHEN total_minutes_watched <= 480 THEN '(240, 480]'
        WHEN total_minutes_watched <= 1000 THEN '(480, 1000]'
        WHEN total_minutes_watched <= 2000 THEN '(1000, 2000]'
        WHEN total_minutes_watched <= 3000 THEN '(2000, 3000]'
        WHEN total_minutes_watched <= 4000 THEN '(3000, 4000]'
        WHEN total_minutes_watched <= 6000 THEN '(4000, 6000]'
        ELSE '6000+'
    END AS bucket
FROM sum_table;
