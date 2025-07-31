/*
===============================================================================
09 - Course Ratings
===============================================================================
Purpose:
    - Provide the distribution of course ratings for visualizing:
        • Rating proportions (e.g. 1–5 star breakdown for pie chart)
        • Overall average rating

Tables Used:
    - course_ratings

SQL Features:
    - GROUP BY rating value
    - COUNT and percentage calculation
    - Window function to calculate global average in each row

Output Columns:
    - course_rating (1–5)
    - count (number of ratings)
    - percent_of_total (% of all ratings, rounded)
    - avg_rating (same value across all rows for Tableau reference)
===============================================================================
*/

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
