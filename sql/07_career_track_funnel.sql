/*
===============================================================================
07 - Career Track Funnel
===============================================================================
Purpose:
    - Build a funnel of student progress through career tracks
    - Funnel stages:
        • Enrolled in a track
        • Attempted a course exam
        • Completed a course exam
        • Attempted a final exam
        • Earned a career track certificate
    - Each row corresponds to a stage + track combination (total: 5 actions × N tracks)

Tables Used:
    - student_career_track_enrollments
    - career_track_info
    - exam_info
    - student_exams

SQL Features:
    - Multiple UNION-ed queries for each stage
    - Conditional filtering via exam_category (2 = course exam, 3 = final exam)
    - COUNT(DISTINCT student_id) for accuracy

Output Columns:
    - action (string)
    - track (track_id)
    - count (number of students at that stage)
===============================================================================
*/

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
