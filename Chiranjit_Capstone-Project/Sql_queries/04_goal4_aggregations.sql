-- 4.1
SELECT 
    membership_type,
    COUNT(*) AS member_count,
    CONCAT(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM members), 0), '%') AS percentage
FROM members
GROUP BY membership_type
ORDER BY member_count DESC;

-- 4.2
SELECT 
    CASE paid
        WHEN 1 THEN 'Collcted'
        ELSE 'Outstanding'
    END AS payment_status,
    SUM(fine_amount) AS total_amount,
    COUNT(*) AS fine_count
FROM fines
GROUP BY paid
ORDER BY payment_status DESC;

-- 4.3
SELECT 
    genre,
    COUNT(DISTINCT book_id) AS number_of_titles,
    SUM(total_copies) AS total_copies
FROM books
GROUP BY genre
ORDER BY total_copies DESC
LIMIT 5;

-- 4.4
SELECT 
    m.membership_type,
    ROUND(AVG(DATEDIFF(l.return_date, l.loan_date)), 2) AS avg_days,
    COUNT(l.loan_id) AS count_of_loans
FROM loans l
JOIN members m 
    ON l.member_id = m.member_id
WHERE l.status = 'returned'
GROUP BY m.membership_type
ORDER BY avg_days DESC;


-- 4.5
SELECT 
    b.title,
    b.author_id,
    b.genre,
    bc.acquisition_date
FROM book_copies bc
LEFT JOIN loans l 
    ON bc.copy_id = l.copy_id
JOIN books b 
    ON bc.book_id = b.book_id
WHERE l.loan_id IS NULL
ORDER BY bc.acquisition_date ASC;

 -- 4.6
 SELECT * FROM loans;
 SELECT * FROM fines;
 SELECT * FROM members;
 
 SELECT 
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    COUNT(l.loan_id) AS total_loans,
    SUM(CASE WHEN l.status = 'active' THEN 1 ELSE 0 END) AS active_loans,
    COALESCE(SUM(CASE WHEN f.paid = 0 THEN f.fine_amount ELSE 0 END), 0) AS unpaid_fines
FROM members m
JOIN loans l 
    ON m.member_id = l.member_id
LEFT JOIN fines f 
    ON l.loan_id = f.loan_id
GROUP BY m.member_id, m.first_name, m.last_name
HAVING COUNT(l.loan_id) > 0
ORDER BY total_loans DESC
LIMIT 10;

-- 4.7
SELECT * FROM events;
SELECT * FROM event_registrations;
SELECT 
    EXTRACT(YEAR FROM loan_date) AS loan_year,
    EXTRACT(MONTH FROM loan_date) AS loan_month,
    COUNT(*) AS total_loans,
    COUNT(DISTINCT member_id) AS unique_borrowers,
    COUNT(DISTINCT copy_id) AS unique_books
FROM loans
GROUP BY 
    EXTRACT(YEAR FROM loan_date),
    EXTRACT(MONTH FROM loan_date)
ORDER BY 
    loan_year DESC,
    loan_month DESC
LIMIT 6;

-- 4.8
SELECT 
    e.event_name,
    e.event_date,
    COUNT(er.registration_id) AS registrations_count,
    e.max_attendees,
    ROUND((COUNT(er.registration_id) * 100.0 / e.max_attendees), 2) AS percentage_capacity
FROM events e
LEFT JOIN event_registrations er 
    ON e.event_id = er.event_id
WHERE e.event_date > CURRENT_DATE
GROUP BY 
    e.event_id, 
    e.event_name, 
    e.event_date, 
    e.max_attendees
ORDER BY 
    percentage_capacity DESC;