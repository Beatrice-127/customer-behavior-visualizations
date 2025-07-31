/*
===============================================================================
06 - Student Certificates
===============================================================================
Purpose:
    - Retrieve all student certificates with metadata
    - Determine if the student was on a paid plan when the certificate was issued

Tables Used:
    - student_certificates
    - purchases_info (view created in 00_create_views.sql)

SQL Features:
    - LEFT JOIN with subscription periods
    - CASE WHEN to infer paid status
    - MAX(paid) in case of multiple overlapping purchases

Output Columns:
    - certificate_id
    - student_id
    - certificate_type
    - date_issued
    - paid (1 = on paid plan at issuance, else 0)
===============================================================================
*/


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
