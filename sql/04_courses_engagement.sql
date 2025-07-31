/*
===============================================================================
04 - Courses Engagement
===============================================================================
Purpose:
    - Analyze student engagement at the course level
    - Compute:
        • Total minutes watched per course
        • Average minutes watched per student
        • Estimated course completion rate (minutes_per_student / course_duration)

Tables Used:
    - course_info
    - student_learning

SQL Features:
    - Aggregation with SUM and COUNT(DISTINCT)
    - Derived field calculation (completion rate)
    - Rounding to two decimal places for presentation

Output Columns:
    - course_id
    - course_title
    - minutes_watched
    - minutes_per_student
    - completion_rate
===============================================================================
*/

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
