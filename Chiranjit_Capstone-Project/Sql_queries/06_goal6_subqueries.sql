-- 6.1
SELECT * FROM fines;
SELECT 
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    SUM(f.fine_amount) AS total_unpaid_fines,
    COUNT(f.fine_id) AS num_of_fines
FROM members m
JOIN loans l ON m.member_id = l.member_id
JOIN fines f ON l.loan_id = f.loan_id
WHERE f.paid = 0
GROUP BY m.member_id
HAVING SUM(f.fine_amount) > (
    SELECT AVG(total_fine)
    FROM (
        SELECT SUM(f2.fine_amount) AS total_fine
        FROM fines f2
        JOIN loans l2 ON f2.loan_id = l2.loan_id
        WHERE f2.paid = 0
        GROUP BY l2.member_id
    ) AS avg_table
)
ORDER BY total_unpaid_fines DESC;

-- 6.2
SELECT 
    b.title,
    a.author_name,
    COUNT(l.loan_id) AS total_loans,
    (SELECT AVG(loans_per_book)
     FROM (
         SELECT COUNT(l2.loan_id) AS loans_per_book
         FROM books b2
         JOIN Book_copies c2 ON b2.book_id = c2.book_id
         JOIN loans l2 ON c2.copy_id = l2.copy_id
         GROUP BY b2.book_id
     ) AS avg_table) AS average_loans
FROM books b
JOIN book_authors a ON b.author_id = a.author_id
JOIN book_copies c ON b.book_id = c.book_id
JOIN loans l ON c.copy_id = l.copy_id
GROUP BY b.book_id
HAVING COUNT(l.loan_id) > (
    SELECT AVG(loans_per_book)
    FROM (
        SELECT COUNT(l3.loan_id) AS loans_per_book
        FROM books b3
        JOIN book_copies c3 ON b3.book_id = c3.book_id
        JOIN loans l3 ON c3.copy_id = l3.copy_id
        GROUP BY b3.book_id
    ) AS avg_table
)
ORDER BY total_loans DESC;


-- 6.3
WITH loan_counts AS (
    SELECT member_id, COUNT(*) AS total_loans
    FROM loans
    GROUP BY member_id
),
fine_totals AS (
    SELECT l.member_id, SUM(f.fine_amount) AS total_fines
    FROM fines f
    JOIN loans l ON f.loan_id = l.loan_id
    GROUP BY l.member_id
),
active_counts AS (
    SELECT member_id, COUNT(*) AS active_loans
    FROM loans
    WHERE status = 'active'
    GROUP BY member_id
)
SELECT 
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    COALESCE(lc.total_loans, 0) AS total_loans,
    COALESCE(ac.active_loans, 0) AS active_loans,
    COALESCE(ft.total_fines, 0) AS total_fines,
    m.status AS membership_status
FROM members m
LEFT JOIN loan_counts lc ON m.member_id = lc.member_id
LEFT JOIN fine_totals ft ON m.member_id = ft.member_id
LEFT JOIN active_counts ac ON m.member_id = ac.member_id
ORDER BY total_loans DESC;

-- 6.4
SELECT 
    b.title AS book_title,
    ba.author_name,
    b.genre,
    b.total_copies
FROM books b
LEFT JOIN book_authors ba 
    ON b.author_id = ba.author_id
WHERE b.book_id NOT IN (
    SELECT bc.book_id
    FROM book_copies bc
    JOIN loans l ON bc.copy_id = l.copy_id
)
ORDER BY b.publication_year ASC;

-- 6.5
SELECT 
    m.first_name || ' ' || m.last_name AS member_name,
    COUNT(er.event_id) AS events_attended
FROM members m
JOIN event_registrations er ON m.member_id = er.member_id
JOIN events e ON er.event_id = e.event_id
WHERE e.event_type = 'book_club'
GROUP BY m.member_id, m.first_name, m.last_name
HAVING COUNT(er.event_id) = (
    SELECT COUNT(*) 
    FROM events 
    WHERE event_type = 'book_club'
)
ORDER BY member_name;

-- 6.6
-- WITH fines_per_month AS (
--     SELECT
--         TO_CHAR(payment_date, 'YYYY-MM') AS `year_month`,
--         SUM(fine_amount) AS fine_revenue
--     FROM fines
--     WHERE paid = 'yes'
--     GROUP BY TO_CHAR(payment_date, 'YYYY-MM')
-- ),
-- membership_per_month AS (
--     SELECT
--         TO_CHAR(join_date, 'YYYY-MM') AS `year_month`,
--         COUNT(*) * 100 AS membership_revenue  -- Assuming each new membership = 100 revenue
--     FROM members
--     GROUP BY TO_CHAR(join_date, 'YYYY-MM')
-- )
-- SELECT
--     COALESCE(f.year_month, m.year_month) AS `year_month`,
--     COALESCE(f.fine_revenue, 0) AS fine_revenue,
--     COALESCE(m.membership_revenue, 0) AS membership_revenue,
--     COALESCE(f.fine_revenue, 0) + COALESCE(m.membership_revenue, 0) AS total_revenue
-- FROM fines_per_month f
-- FULL OUTER JOIN membership_per_month m
--     ON f.year_month = m.year_month
-- ORDER BY year_month DESC
-- LIMIT 12;

-- 6.7
SELECT 
    b.title AS book_title,
    a.author_name,
    (SELECT MAX(l.loan_date)
     FROM loans l
     JOIN book_copies bc ON l.copy_id = bc.copy_id
     WHERE bc.book_id = b.book_id
    ) AS most_recent_loan_date,
    (SELECT m.first_name || ' ' || m.last_name
     FROM loans l
     JOIN book_copies bc ON l.copy_id = bc.copy_id
     JOIN members m ON l.member_id = m.member_id
     WHERE bc.book_id = b.book_id
     ORDER BY l.loan_date DESC
     LIMIT 1
    ) AS borrower_name
FROM books b
JOIN book_authors a ON b.author_id = a.author_id
WHERE EXISTS (
    SELECT 1 
    FROM loans l
    JOIN book_copies bc ON l.copy_id = bc.copy_id
    WHERE bc.book_id = b.book_id
)
ORDER BY most_recent_loan_date DESC;