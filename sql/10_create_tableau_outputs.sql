USE customer_engagement;

/*
===============================================================================
10 - Create Tables for Tableau Visualizations
===============================================================================
Purpose:
    - Store pre-aggregated analysis results in SQL tables
    - These tables can be exported (e.g. as CSV) and imported into Tableau Public
    - Each CREATE TABLE corresponds to the output of an analysis query from
      earlier numbered files (01 to 09)
===============================================================================
*/

-- 01: Daily learning log with paid/free status
CREATE TABLE student_learning_log AS
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

-- 02: F2P conversion buckets
CREATE TABLE student_buckets_f2p AS
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

-- 03: Subscription duration buckets
CREATE TABLE student_buckets_sub_duration AS
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

-- 04: Course engagement metrics
CREATE TABLE courses_engagement AS
SELECT 
    course_id,
    course_title,
    minutes_watched,
    minutes_per_student,
    ROUND(minutes_per_student / course_duration, 2) AS completion_rate
FROM (
    SELECT 
        i.course_id,
        i.course_title,
        i.course_duration,
        ROUND(SUM(l.minutes_watched), 2) AS minutes_watched,
        ROUND(SUM(l.minutes_watched) / COUNT(DISTINCT l.student_id), 2) AS minutes_per_student
    FROM course_info i
    LEFT JOIN student_learning l USING (course_id)
    GROUP BY i.course_id, i.course_title, i.course_duration
) AS course_stats;

-- 05: Student exam attempts
CREATE TABLE student_exam_attempts AS
SELECT 
    se.exam_attempt_id,
    se.student_id,
    se.exam_id,
    ei.exam_category,
    se.exam_passed,
    se.date_exam_completed
FROM student_exams se
JOIN exam_info ei ON se.exam_id = ei.exam_id;

-- 06: Student certificates with paid status
CREATE TABLE student_certificates AS
SELECT 
    certificate_id,
    student_id,
    certificate_type,
    date_issued,
    MAX(paid) AS paid
FROM (
    SELECT 
        c.certificate_id,
        c.student_id,
        c.certificate_type,
        c.date_issued,
        p.date_start,
        p.date_end,
        CASE
            WHEN p.date_start IS NULL OR p.date_end IS NULL THEN 0
            WHEN c.date_issued BETWEEN p.date_start AND p.date_end THEN 1
            ELSE 0
        END AS paid
    FROM student_certificates c
    LEFT JOIN purchases_info p USING (student_id)
) AS cert_with_paid_flag
GROUP BY certificate_id, student_id, certificate_type, date_issued;


-- 07: Career track funnel
CREATE TABLE career_track_funnel AS
SELECT 
    'Enrolled in a track' AS action,
    track_id AS track,
    COUNT(*) AS count
FROM student_career_track_enrollments
GROUP BY track

UNION

SELECT 
    'Attempted a course exam' AS action,
    scte.track_id AS track,
    COUNT(DISTINCT se.student_id) AS count
FROM student_career_track_enrollments scte
JOIN career_track_info cti ON scte.track_id = cti.track_id
JOIN exam_info ei ON cti.course_id = ei.course_id
JOIN student_exams se 
    ON se.exam_id = ei.exam_id
   AND se.student_id = scte.student_id
WHERE ei.exam_category = 2
GROUP BY scte.track_id

UNION

SELECT 
    'Completed a course exam' AS action,
    scte.track_id AS track,
    COUNT(DISTINCT se.student_id) AS count
FROM student_career_track_enrollments scte
JOIN career_track_info cti ON scte.track_id = cti.track_id
JOIN exam_info ei ON cti.course_id = ei.course_id
JOIN student_exams se 
    ON se.exam_id = ei.exam_id
   AND se.student_id = scte.student_id
WHERE ei.exam_category = 2
  AND se.exam_passed = 1
GROUP BY scte.track_id

UNION

SELECT 
    'Attempted a final exam' AS action,
    scte.track_id AS track,
    COUNT(DISTINCT se.student_id) AS count
FROM student_career_track_enrollments scte
JOIN student_exams se ON scte.student_id = se.student_id
JOIN exam_info ei ON se.exam_id = ei.exam_id
WHERE ei.exam_category = 3
  AND ei.track_id = scte.track_id
GROUP BY scte.track_id

UNION

SELECT 
    'Earned a career track certificate' AS action,
    scte.track_id AS track,
    COUNT(DISTINCT se.student_id) AS count
FROM student_career_track_enrollments scte
JOIN student_exams se 
    ON scte.student_id = se.student_id
   AND se.exam_passed = 1
JOIN exam_info ei ON se.exam_id = ei.exam_id
WHERE ei.exam_category = 3
  AND ei.track_id = scte.track_id
GROUP BY scte.track_id;

-- 08: Student onboarding status
CREATE TABLE student_onboarding AS
SELECT 
    s.*,
    CASE 
        WHEN e.student_id IS NOT NULL THEN 1
        ELSE 0
    END AS student_onboarded
FROM student_info s
LEFT JOIN (
    SELECT DISTINCT student_id FROM student_engagement
) e ON s.student_id = e.student_id;

-- 09: Course rating distribution
CREATE TABLE course_ratings_summary AS
WITH rating_counts AS (
    SELECT 
        course_rating,
        COUNT(*) AS count
    FROM course_ratings
    GROUP BY course_rating
),
total_count AS (
    SELECT COUNT(*) AS total FROM course_ratings
),
average_rating AS (
    SELECT ROUND(AVG(course_rating), 2) AS avg_rating FROM course_ratings
)

SELECT 
    rc.course_rating,
    rc.count,
    ROUND(100.0 * rc.count / t.total, 2) AS percent_of_total,
    a.avg_rating
FROM rating_counts rc
CROSS JOIN total_count t
CROSS JOIN average_rating a
ORDER BY rc.course_rating;