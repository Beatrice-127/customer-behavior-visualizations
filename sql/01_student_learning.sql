/*
===============================================================================
01 - Student Daily Learning with Subscription Status
===============================================================================
Purpose:
    - Track how much time each student watched per day
    - Determine whether the student was on a paid subscription on that day
    - Use as foundational dataset for later analyses (e.g., conversion, retention)

Tables Used:
    - student_learning
    - purchases_info (created in 00_create_views.sql)

SQL Features:
    - LEFT JOIN with purchase periods
    - CASE WHEN to determine subscription status per row
    - CTEs for clean structure
    - Aggregation by student_id and date_watched

Output Columns:
    - student_id
    - date_watched
    - minutes_watched (rounded to 2 decimals)
    - paid (1 = on paid plan that day, 0 = free)
===============================================================================
*/

WITH learning_with_flag AS (
    SELECT 
        l.student_id,
        l.date_watched,
        l.minutes_watched,
        p.date_start,
        p.date_end,
        CASE
            WHEN p.date_start IS NULL OR p.date_end IS NULL THEN 0
            WHEN l.date_watched BETWEEN p.date_start AND p.date_end THEN 1
            ELSE 0
        END AS paid_flag
    FROM student_learning l
    LEFT JOIN purchases_info p USING (student_id)
),
daily_aggregated_learning AS (
    SELECT 
        student_id,
        date_watched,
        SUM(minutes_watched) AS total_minutes_watched,
        MAX(paid_flag) AS paid
    FROM learning_with_flag
    GROUP BY student_id, date_watched
)

SELECT 
    student_id,
    date_watched,
    ROUND(total_minutes_watched, 2) AS minutes_watched,
    paid
FROM daily_aggregated_learning;
