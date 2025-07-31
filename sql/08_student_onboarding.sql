/*
===============================================================================
08 - Student Onboarding Status
===============================================================================
Purpose:
    - Determine whether each student has onboarded the platform
    - A student is considered "onboarded" if they appear in the engagement log

Tables Used:
    - student_info
    - student_engagement

SQL Functions Used:
    - EXISTS / NOT EXISTS
    - Boolean CASE WHEN

Output Columns:
    - student_id
    - date_registered (or other columns from student_info)
    - student_onboarded (1 = onboarded, 0 = not onboarded)
===============================================================================
*/

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
