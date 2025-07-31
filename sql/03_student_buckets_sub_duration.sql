/*
===============================================================================
03 - Student Buckets: Subscription Duration
===============================================================================
Purpose:
    - For each paying student, compute:
        • Subscription period (first to last paid date)
        • Total minutes watched during paid period
        • Number of paid days (duration)
    - Segment students into usage buckets based on total_minutes_watched

Tables Used:
    - purchases_info (created in 00_create_views.sql)
    - student_learning
    - student_info

SQL Features:
    - CTEs for clear step-by-step logic
    - RIGHT JOIN to ensure all paying users are included
    - COALESCE, DATEDIFF for robust calculations

Output Columns:
    - student_id
    - date_registered
    - total_minutes_watched (during paid period)
    - num_paid_days
    - user_buckets (based on watched time)
===============================================================================
*/

WITH table_paid_duration AS (
    SELECT 
        student_id,
        MIN(date_start) AS first_paid_day,
        IF(MAX(date_end) <= '2022-10-31', MAX(date_end), '2022-10-31') AS last_paid_day
    FROM purchases_info
    GROUP BY student_id
),

minutes_watched AS (
    SELECT 
        tpd.student_id,
        tpd.first_paid_day,
        tpd.last_paid_day,
        COALESCE(COUNT(sl.minutes_watched), 0) AS total_minutes_watched
    FROM student_learning sl
    RIGHT JOIN table_paid_duration tpd
        ON sl.student_id = tpd.student_id
       AND sl.date_watched BETWEEN tpd.first_paid_day AND tpd.last_paid_day
    GROUP BY tpd.student_id, tpd.first_paid_day, tpd.last_paid_day
),

paid_days AS (
    SELECT 
        *,
        DATEDIFF(last_paid_day, first_paid_day) AS num_paid_days
    FROM minutes_watched
)

SELECT 
    pd.student_id,
    si.date_registered,
    pd.total_minutes_watched,
    pd.num_paid_days,
    CASE
        WHEN total_minutes_watched IS NULL OR total_minutes_watched = 0 THEN '[0]'
        WHEN total_minutes_watched <= 30 THEN '(0, 30]'
        WHEN total_minutes_watched <= 60 THEN '(30, 60]'
        WHEN total_minutes_watched <= 120 THEN '(60, 120]'
        WHEN total_minutes_watched <= 240 THEN '(120, 240]'
        WHEN total_minutes_watched <= 480 THEN '(240, 480]'
        WHEN total_minutes_watched <= 1000 THEN '(480, 1000]'
        WHEN total_minutes_watched <= 2000 THEN '(1000, 2000]'
        WHEN total_minutes_watched <= 3000 THEN '(2000, 3000]'
        WHEN total_minutes_watched <= 4000 THEN '(3000, 4000]'
        WHEN total_minutes_watched <= 6000 THEN '(4000, 6000]'
        ELSE '6000+'
    END AS user_buckets
FROM paid_days pd
JOIN student_info si ON pd.student_id = si.student_id;
