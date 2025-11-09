-- 8.1
WITH loan_counts AS (
  SELECT
    l.member_id,
    COUNT(*) AS total_loans
  FROM loans AS l
  GROUP BY l.member_id
)
SELECT
  ROW_NUMBER() OVER (ORDER BY lc.total_loans DESC) AS row_num,
  RANK()       OVER (ORDER BY lc.total_loans DESC) AS `rank`,
  DENSE_RANK() OVER (ORDER BY lc.total_loans DESC) AS `dense_rank`,
  CONCAT(m.first_name, ' ', m.last_name) AS member_name,
  lc.total_loans
FROM loan_counts AS lc
JOIN members AS m ON m.member_id = lc.member_id
ORDER BY lc.total_loans DESC, member_name;

-- 8.2
SELECT
  f.payment_date,
  f.fine_amount,
  SUM(f.fine_amount) OVER (
    ORDER BY f.payment_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total
FROM fines AS f
WHERE f.paid = 1
  AND f.payment_date IS NOT NULL
ORDER BY f.payment_date;

-- 8.3
WITH book_loan_counts AS (
  SELECT
    b.book_id,
    b.genre,
    b.title AS book_title,
    COUNT(l.loan_id) AS loan_count
  FROM books AS b
  LEFT JOIN book_copies AS bc ON bc.book_id = b.book_id
  LEFT JOIN loans AS l ON l.copy_id = bc.copy_id
  GROUP BY b.book_id, b.genre, b.title
),
ranked AS (
  SELECT
    genre,
    book_title,
    loan_count,
    RANK() OVER (
      PARTITION BY genre
      ORDER BY loan_count DESC, book_title
    ) AS genre_rank
  FROM book_loan_counts
)
SELECT
  genre,
  book_title,
  loan_count AS loans,
  genre_rank AS rank_within_genre
FROM ranked
WHERE genre_rank <= 3
ORDER BY genre, genre_rank, book_title;

-- 8.4
WITH per_member_month AS (
  SELECT
    l.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member,
    EXTRACT(YEAR_MONTH FROM l.loan_date) AS month_key,
    DATE_FORMAT(l.loan_date, '%Y-%m') AS month_label,
    COUNT(*) AS loans_this_month
  FROM loans AS l
  JOIN members AS m ON m.member_id = l.member_id
  GROUP BY l.member_id, member, month_key, month_label
),
with_lag AS (
  SELECT
    member,
    month_key,
    month_label,
    loans_this_month,
    LAG(loans_this_month) OVER (
      PARTITION BY member
      ORDER BY month_key
    ) AS loans_last_month
  FROM per_member_month
)
SELECT
  member,
  month_label AS month,
  loans_this_month AS loans_this_month,
  loans_last_month AS loans_last_month,
  loans_this_month - loans_last_month AS difference
FROM with_lag ORDER BY member, month_key;

-- 8.5
WITH upcoming AS (
  SELECT
    er.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    e.event_name,
    e.event_date,
    ROW_NUMBER() OVER (
      PARTITION BY er.member_id
      ORDER BY e.event_date ASC, e.event_id
    ) AS rn
  FROM event_registrations AS er
  JOIN events AS e
    ON e.event_id = er.event_id
  JOIN members AS m
    ON m.member_id = er.member_id
  WHERE e.event_date >= CURDATE()
)
SELECT
  member_name,
  event_name AS next_event_name,
  event_date
FROM upcoming
WHERE rn = 1
ORDER BY member_name, event_date;

-- 8.6
WITH RECURSIVE dates AS (
  SELECT CURDATE() - INTERVAL 29 DAY AS d
  UNION ALL
  SELECT d + INTERVAL 1 DAY
  FROM dates
  WHERE d < CURDATE()
),
daily AS (
  SELECT
    d.d AS loan_day,
    COALESCE(COUNT(l.loan_id), 0) AS loans_today
  FROM dates AS d
  LEFT JOIN loans AS l
    ON l.loan_date = d.d
  GROUP BY d.d
)
SELECT
  loan_day AS date,
  loans_today AS loans_that_day,
  AVG(loans_today) OVER (
    ORDER BY loan_day
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) AS moving_avg_7_day
FROM daily
ORDER BY loan_day DESC
LIMIT 30;

-- 8.7
WITH unpaid AS (
  SELECT
    m.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    f.fine_amount
  FROM fines AS f
  JOIN loans AS l ON l.loan_id = f.loan_id
  JOIN members AS m ON m.member_id = l.member_id
  WHERE (f.paid = 0 OR f.paid = FALSE OR f.payment_date IS NULL)
),
ranked AS (
  SELECT
    member_name,
    fine_amount,
    PERCENT_RANK() OVER (ORDER BY fine_amount) AS pct_rank
  FROM unpaid
)
SELECT
  member_name,
  fine_amount,
  ROUND(pct_rank * 100, 2) AS percentile_pct
FROM ranked
ORDER BY pct_rank DESC, fine_amount DESC, member_name;

-- 8.8
WITH ordered_loans AS (
  SELECT
    m.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    l.loan_date,
    LAG(l.loan_date) OVER (
      PARTITION BY m.member_id
      ORDER BY l.loan_date
    ) AS prev_loan_date
  FROM members AS m
  JOIN loans AS l
    ON l.member_id = m.member_id
),
with_gaps AS (
  SELECT
    member_name,
    loan_date,
    prev_loan_date,
    DATEDIFF(loan_date, prev_loan_date) AS days_gap
  FROM ordered_loans
  WHERE prev_loan_date IS NOT NULL
)
SELECT
  member_name,
  loan_date,
  prev_loan_date,
  days_gap
FROM with_gaps
ORDER BY member_name, loan_date;