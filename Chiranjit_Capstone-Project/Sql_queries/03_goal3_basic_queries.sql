-- Goal 3: Basic Information Retrieval Queries
-- 3.1
SELECT first_name, last_name, email, membership_type from members WHERE status = "active" ORDER BY last_name ASC, first_name;  

-- 3.2
SELECT 
    b.title AS title,
    a.author_name AS author_name,
    b.publication_year AS publication_year,
    b.genre AS genre
FROM 
    books b
LEFT JOIN 
    book_authors a ON b.author_id = a.author_id
WHERE 
    b.publication_year >= 2001
ORDER BY 
    b.publication_year DESC;
    
-- 3.3
SELECT 
	b.title AS title, b.genre AS genre, b.total_copies AS total_copies, a.author_name AS author_name 
FROM 
	books b 
LEFT JOIN 
	book_authors a 
ON 
	b.author_id = a.author_id 
WHERE 
	b.genre = "Fiction" ORDER BY b.title ASC;
    
-- 3.4
SELECT 
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    b.title AS book_title,
    l.loan_date,
    l.due_date,
    DATEDIFF(CURDATE(), l.due_date) AS days_overdue
FROM loans l
JOIN members m ON l.member_id = m.member_id
JOIN book_copies bc ON l.copy_id = bc.copy_id
JOIN books b ON bc.book_id = b.book_id
WHERE l.status = 'active'
  AND l.due_date < CURDATE()
ORDER BY days_overdue DESC;

-- 3.5
SELECT 
    first_name,
    last_name,
    join_date,
    membership_type
FROM members
WHERE join_date >= DATE_SUB(CURDATE(), INTERVAL 180 DAY)
ORDER BY join_date DESC;

-- 3.6
SELECT 
    b.title,
    bc.copy_number,
    bc.condition,
    bc.acquisition_date
FROM book_copies bc
JOIN books b ON bc.book_id = b.book_id
WHERE bc.condition = 'poor'
ORDER BY bc.acquisition_date ASC;

-- 3.7
SELECT 
    mem.first_name,
    mem.last_name,
    f.fine_amount,
    f.fine_reason,
    l.loan_date
FROM fines f
JOIN loans l ON f.loan_id = l.loan_id
JOIN members mem ON l.member_id = mem.member_id
WHERE f.paid = 0
ORDER BY f.fine_amount DESC
LIMIT 10;


-- 3.8
SELECT 
    event_name,
    event_date,
    event_type,
    max_attendees
FROM events
WHERE event_date > CURDATE()
  AND event_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)
ORDER BY event_date ASC;