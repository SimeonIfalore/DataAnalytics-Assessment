/* Question 3  - Account Inactivity Alert
Scenario: The ops team wants to flag accounts with no inflow transactions for over one
year.
Task: Find all active accounts (savings or investments) with no transactions in the last 1
year (365 days) .
Tables:
● plans_plan
● savings_savingsaccount*/ 

-- UNION to check both savings and investment accounts
SELECT 
    id AS plan_id,
    owner_id,
    'Savings' AS type, -- creates a new column tag to recognise all savings 
    MAX(transaction_date) AS last_transaction_date,
    DATEDIFF(CURRENT_DATE, MAX(transaction_date)) AS inactivity_days
FROM savings_savingsaccount
GROUP BY id, owner_id
HAVING inactivity_days > 365

UNION

SELECT 
    id AS plan_id,
    owner_id,
    'Investment' AS type,
    MAX(created_on) AS last_transaction_date,
    DATEDIFF(CURRENT_DATE, MAX(created_on)) AS inactivity_days
FROM plans_plan
WHERE is_deleted = 0 and is_a_fund = 1 -- filters out deleted accounts and non investments 
GROUP BY id, owner_id
HAVING inactivity_days > 365;
