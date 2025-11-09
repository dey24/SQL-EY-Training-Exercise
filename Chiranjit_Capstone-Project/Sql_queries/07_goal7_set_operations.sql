-- 7.1
SELECT
  CONCAT(m.first_name, ' ', m.last_name) AS full_name,
  m.email AS email,
  'Member' AS type
FROM members AS m

UNION

SELECT
  ba.author_name AS full_name,
  NULL AS email,
  'Author' AS type
FROM book_authors AS ba

ORDER BY
  type, 
  full_name;  
  
-- 7.2
SELECT
  'Loan' AS activity_type,
  l.loan_date AS activity_date,
  CONCAT(m.first_name, ' ', m.last_name, ' borrowed "', b.title, '"') AS description
FROM loans AS l
JOIN members AS m
  ON m.member_id = l.member_id
JOIN book_copies AS bc
  ON bc.copy_id = l.copy_id
JOIN books AS b
  ON b.book_id = bc.book_id
UNION ALL
SELECT
  'Event' AS activity_type,
  e.event_date AS activity_date,
  e.event_name AS description
FROM events AS e
UNION ALL
SELECT
  'Registration' AS activity_type,
  er.registration_date AS activity_date,
  CONCAT(m2.first_name, ' ', m2.last_name, ' registered for "', e2.event_name, '"') AS description
FROM event_registrations AS er
JOIN members AS m2
  ON m2.member_id = er.member_id
JOIN events AS e2
  ON e2.event_id = er.event_id

ORDER BY activity_date DESC
LIMIT 50;

-- 7.3
SELECT
  b.title AS book_title,
  'Available' AS status,
  COUNT(*) AS count
FROM book_copies AS bc
JOIN books AS b
  ON b.book_id = bc.book_id
WHERE NOT EXISTS (
  SELECT 1
  FROM loans AS l2
  WHERE l2.copy_id = bc.copy_id
    AND l2.status = 'active'
)
GROUP BY b.title

UNION

SELECT
  b.title AS book_title,
  'On Loan' AS status,
  COUNT(*) AS count
FROM loans AS l
JOIN book_copies AS bc
  ON bc.copy_id = l.copy_id
JOIN books AS b
  ON b.book_id = bc.book_id
WHERE l.status = 'active'
GROUP BY b.title

ORDER BY book_title;

-- 7.4
SELECT
  CONCAT(m.first_name, ' ', m.last_name) AS member_name,
  m.email,'Overdue' AS issue_type,
  COUNT(*) AS issue_count
FROM loans AS l
JOIN members AS m
  ON m.member_id = l.member_id
WHERE l.status = 'active'
  AND l.return_date IS NULL
  AND l.due_date < CURDATE()
GROUP BY member_name, m.email
UNION ALL
SELECT
  CONCAT(m.first_name, ' ', m.last_name) AS member_name,
  m.email, 'Unpaid Fines' AS issue_type,
  COUNT(*) AS issue_count
FROM fines AS f
JOIN loans AS l ON l.loan_id = f.loan_id
JOIN members AS m ON m.member_id = l.member_id
WHERE (f.paid = 0 OR f.paid = FALSE OR f.payment_date IS NULL)
GROUP BY member_name, m.email
UNION ALL
SELECT
  CONCAT(m.first_name, ' ', m.last_name) AS member_name,
  m.email, 'Suspended' AS issue_type,
  COUNT(*) AS issue_count
FROM members AS m
WHERE m.status = 'suspended'
GROUP BY member_name, m.email
ORDER BY member_name;

-- 7.5
SELECT p.book_title,p.author, 'Popular' AS category, p.loan_count
FROM (
  SELECT b.title AS book_title, ba.author_name AS author, COUNT(l.loan_id) AS loan_count
  FROM books AS b
  LEFT JOIN book_authors AS ba ON ba.author_id = b.author_id
  LEFT JOIN book_copies AS bc ON bc.book_id = b.book_id
  LEFT JOIN loans AS l ON l.copy_id = bc.copy_id
  GROUP BY b.book_id, b.title, ba.author_name
  ORDER BY loan_count DESC, b.title
  LIMIT 10
) AS p
UNION
SELECT u.book_title, u.author, 'Unpopular' AS category, u.loan_count
FROM (
  SELECT b.title AS book_title, ba.author_name AS author, COUNT(l.loan_id) AS loan_count
  FROM books AS b
  LEFT JOIN book_authors AS ba ON ba.author_id = b.author_id
  LEFT JOIN book_copies AS bc ON bc.book_id = b.book_id
  LEFT JOIN loans AS l ON l.copy_id = bc.copy_id
  GROUP BY b.book_id, b.title, ba.author_name
  ORDER BY loan_count ASC, b.title
  LIMIT 10
) AS u
ORDER BY category, loan_count, book_title;