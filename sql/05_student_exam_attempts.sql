/*
===============================================================================
05 - Student Exam Attempts
===============================================================================
Purpose:
    - Retrieve detailed exam attempt information for each student
    - Join exam metadata (category) for enriched analysis
    - Useful for calculating pass rates, exam category performance, and timelines

Tables Used:
    - student_exams
    - exam_info

SQL Features:
    - Simple JOIN
    - Direct column selection

Output Columns:
    - exam_attempt_id
    - student_id
    - exam_id
    - exam_category
    - exam_passed (1 = pass, 0 = fail)
    - date_exam_completed
===============================================================================
*/

SELECT 
    se.exam_attempt_id,
    se.student_id,
    se.exam_id,
    ei.exam_category,
    se.exam_passed,
    se.date_exam_completed
FROM student_exams se
JOIN exam_info ei ON se.exam_id = ei.exam_id;
