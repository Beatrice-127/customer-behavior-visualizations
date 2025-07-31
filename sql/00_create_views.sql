/*
===============================================================================
00 - Create Supporting Views
===============================================================================
View: purchases_info
===============================================================================
Purpose:
    - Create a reusable view to unify purchase period information
    - Determine start and end date of subscriptions per student
    - Adjust for refund cases by overriding end date with refund date when present

Source Tables:
    - student_purchases

SQL Functions Used:
    - CASE WHEN, DATE_ADD, MAKEDATE, IF, DATE_REFUNDED logic

Output:
    - purchase_id
    - student_id
    - purchase_type
    - date_start
    - date_end (adjusted if refunded)
===============================================================================
*/

CREATE VIEW purchases_info AS
SELECT 
    purchase_id,
    student_id,
    purchase_type,
    date_start,
    IF(date_refunded IS NULL, date_end, date_refunded) AS date_end
FROM (
    SELECT 
        purchase_id,
        student_id,
        purchase_type,
        date_purchased AS date_start,
        CASE
            WHEN purchase_type = 0 THEN DATE_ADD(MAKEDATE(YEAR(date_purchased), DAY(date_purchased)), INTERVAL MONTH(date_purchased) MONTH)
            WHEN purchase_type = 1 THEN DATE_ADD(MAKEDATE(YEAR(date_purchased), DAY(date_purchased)), INTERVAL MONTH(date_purchased) + 2 MONTH)
            WHEN purchase_type = 2 THEN DATE_ADD(MAKEDATE(YEAR(date_purchased), DAY(date_purchased)), INTERVAL MONTH(date_purchased) + 11 MONTH)
        END AS date_end,
        date_refunded
    FROM student_purchases
) a;
