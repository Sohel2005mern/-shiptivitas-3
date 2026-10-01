-- TYPE YOUR SQL QUERY BELOW

-- ===================================================================================
-- PART 1: Create a SQL query that maps out the daily average users before and after
--         the feature change (Release Date: 2018-06-02)
-- ===================================================================================

-- 1A. Daily Active Users (DAU) Time Series with Zero-Filling for Inactive Days:
-- Generates a complete daily calendar from 2018-02-03 through 2019-02-01 (364 days)
-- and joins distinct user logins per date. Days without logins are filled with 0.
WITH RECURSIVE calendar(cal_date) AS (
  SELECT '2018-02-03'
  UNION ALL
  SELECT date(cal_date, '+1 day')
  FROM calendar
  WHERE cal_date < '2019-02-01'
),
daily_logins AS (
  SELECT 
    date(login_timestamp, 'unixepoch') AS login_date,
    COUNT(DISTINCT user_id) AS dau
  FROM login_history
  GROUP BY login_date
)
SELECT 
  c.cal_date AS date,
  COALESCE(d.dau, 0) AS daily_active_users,
  CASE 
    WHEN c.cal_date < '2018-06-02' THEN 'Pre-Release'
    ELSE 'Post-Release'
  END AS period
FROM calendar c
LEFT JOIN daily_logins d ON c.cal_date = d.login_date
ORDER BY c.cal_date ASC;


-- 1B. Summary Comparison of Average DAU Before vs. After Feature Release:
-- Calculates average DAU across all 119 pre-release and 245 post-release calendar days.
WITH RECURSIVE calendar(cal_date) AS (
  SELECT '2018-02-03'
  UNION ALL
  SELECT date(cal_date, '+1 day')
  FROM calendar
  WHERE cal_date < '2019-02-01'
),
daily_logins AS (
  SELECT 
    date(login_timestamp, 'unixepoch') AS login_date,
    COUNT(DISTINCT user_id) AS dau
  FROM login_history
  GROUP BY login_date
),
calendar_dau AS (
  SELECT 
    c.cal_date,
    COALESCE(d.dau, 0) AS dau,
    CASE 
      WHEN c.cal_date < '2018-06-02' THEN 'Pre-Release (2018-02-03 to 2018-06-01)'
      ELSE 'Post-Release (2018-06-02 to 2019-02-01)'
    END AS period
  FROM calendar c
  LEFT JOIN daily_logins d ON c.cal_date = d.login_date
)
SELECT 
  period,
  COUNT(*) AS total_calendar_days,
  SUM(dau) AS total_active_user_days,
  ROUND(AVG(dau), 4) AS average_dau
FROM calendar_dau
GROUP BY period
ORDER BY period DESC;


-- ===================================================================================
-- PART 2: Create a SQL query that indicates the number of status changes by card
-- ===================================================================================

-- Evaluates all 200 cards in the database.
-- Note: 'oldStatus IS NOT NULL' filters out the initial card creation / insertion rows,
-- counting only genuine lane/status transitions.
SELECT 
  c.id AS card_id,
  c.name AS card_name,
  COUNT(h.id) AS status_changes
FROM card c
LEFT JOIN card_change_history h 
  ON c.id = h.cardID 
  AND h.oldStatus IS NOT NULL
GROUP BY c.id, c.name
ORDER BY status_changes DESC, c.id ASC;
