# My Cowrywise SQL Assessment Analysis Submission

This README provides an explanation of the SQL queries found in the four assessment files: `Assessment_Q1.sql`, `Assessment_Q2.sql`, `Assessment_Q3.sql`, and `Assessment_Q4.sql`.

## Question 1: `Assessment_Q1.sql` - High-Value Customers with Multiple Products

```sql
SELECT u.id AS owner_id,
       CONCAT(first_name, ' ', last_name) AS name,
       COUNT(DISTINCT s.id) AS savings_count, -- this count will give us all savings because the id comes from savings table
       COUNT(DISTINCT p.id) AS investment_count, -- this count will give us all investment because the id comes from plans_plan table which has been filtered for investments
       SUM(s.confirmed_amount) / 100 AS total_deposits -- the value was divided by 100 because all amounts are in kobo
FROM users_customuser u
LEFT JOIN savings_savingsaccount s
				ON u.id = s.owner_id
       AND s.confirmed_amount > 0 -- filters out savings not funded
LEFT JOIN plans_plan p
				ON u.id = p.owner_id
       AND p.is_a_fund = 1 -- this condition filters the plans_plan for investments
WHERE s.confirmed_amount IS NOT NULL -- filters out investments not funded
				AND p.id IS NOT NULL
GROUP BY u.id, u.name
HAVING savings_count > 0
				AND investment_count > 0
ORDER BY total_deposits DESC;
```

### Per-Question Explanation:

This query aims to identify high-value customers who hold both savings and investment products.

1.  **`SELECT` Clause:**
    * `u.id AS owner_id`: Selects the user ID as `owner_id`.
    * `CONCAT(first_name, ' ', last_name) AS name`: Concatenates the first and last names from the `users_customuser` table to get the customer's full name.
    * `COUNT(DISTINCT s.id) AS savings_count`: Counts the number of distinct savings accounts for each user. The comment correctly notes that this counts all savings accounts (that have a `confirmed_amount` greater than 0 due to the `LEFT JOIN` condition).
    * `COUNT(DISTINCT p.id) AS investment_count`: Counts the number of distinct investment plans for each user. The comment correctly points out that this leverages the `p.is_a_fund = 1` condition in the `LEFT JOIN` to only count investment plans.
    * `SUM(s.confirmed_amount) / 100 AS total_deposits`: Calculates the total amount deposited across all the user's funded savings accounts. The division by 100 correctly converts the amount from kobo to Naira.

2.  **`FROM` and `LEFT JOIN` Clauses:**
    * `FROM users_customuser u`: Starts with the `users_customuser` table, aliased as `u`.
    * `LEFT JOIN savings_savingsaccount s ON u.id = s.owner_id AND s.confirmed_amount > 0`: Performs a left join with the `savings_savingsaccount` table (`s`) based on the `owner_id`. The `AND s.confirmed_amount > 0` condition is applied during the join, effectively only linking funded savings accounts.
    * `LEFT JOIN plans_plan p ON u.id = p.owner_id AND p.is_a_fund = 1`: Performs another left join with the `plans_plan` table (`p`) based on the `owner_id`, and filters for investment plans (`p.is_a_fund = 1`) during the join.

3.  **`WHERE` Clause:**
    * `s.confirmed_amount IS NOT NULL AND p.id IS NOT NULL`: This clause filters out users who do not have at least one funded savings account (`s.confirmed_amount IS NOT NULL`) and at least one investment plan (`p.id IS NOT NULL`). This is a crucial step to ensure we are only considering customers with both product types.

4.  **`GROUP BY` Clause:**
    * `GROUP BY u.id, u.name`: Groups the results by the user's ID and name to aggregate their savings and investment counts and total deposits.

5.  **`HAVING` Clause:**
    * `HAVING savings_count > 0 AND investment_count > 0`: This clause filters the grouped results to only include customers who have more than zero savings accounts and more than zero investment plans. This could be simplified as the `WHERE` clause already ensures at least one of each exists.

6.  **`ORDER BY` Clause:**
    * `ORDER BY total_deposits DESC`: Orders the final result set by the `total_deposits` in descending order, showing the customers with the highest total deposits first.

## Question 2: `Assessment_Q2.sql` - Customer Transaction Frequency Categorization

```sql
-- Question 2 Step 1: Calculate monthly transaction count per customer
WITH transactions_per_month AS (
    SELECT
        owner_id,
        DATE_FORMAT(transaction_date, '%Y-%m') AS txn_month,
        COUNT(*) AS txn_count
    FROM savings_savingsaccount
    GROUP BY owner_id, txn_month
),

-- Step 2: Calculate average transactions per month per customer
avg_txn_per_customer AS (
    SELECT
        owner_id,
        AVG(txn_count) AS avg_txn_per_month
    FROM transactions_per_month
    GROUP BY owner_id
),

-- Step 3: Categorize customers by frequency
categorized_customers AS (
    SELECT
        CASE
            WHEN avg_txn_per_month >= 10 THEN 'High Frequency'
            WHEN avg_txn_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category,
        owner_id,
        avg_txn_per_month
    FROM avg_txn_per_customer
),

-- Final Output: Aggregate by frequency category
SELECT
    frequency_category,
    COUNT(owner_id) AS customer_count,
    ROUND(AVG(avg_txn_per_month), 1) AS avg_transactions_per_month
FROM categorized_customers
GROUP BY frequency_category;
```

### Per-Question Explanation:

This query categorizes customers based on their average monthly transaction frequency in their savings accounts.

1.  **`transactions_per_month` CTE:**
    * Selects `owner_id` and formats the `transaction_date` to get the year and month (`YYYY-MM`) as `txn_month`.
    * Counts the number of transactions (`COUNT(*)`) for each `owner_id` within each `txn_month`.
    * Groups the results by `owner_id` and `txn_month`.

2.  **`avg_txn_per_customer` CTE:**
    * Selects `owner_id` and calculates the average transaction count per month (`AVG(txn_count)`) for each customer using the results from `transactions_per_month`.
    * Groups the results by `owner_id`.

3.  **`categorized_customers` CTE:**
    * Selects the `owner_id` and `avg_txn_per_month` from `avg_txn_per_customer`.
    * Uses a `CASE` statement to categorize customers into 'High Frequency' (>= 10 transactions/month), 'Medium Frequency' (3-9 transactions/month), and 'Low Frequency' (< 3 transactions/month) based on their `avg_txn_per_month`.

4.  **Final `SELECT` Statement:**
    * Selects the `frequency_category`.
    * Counts the number of customers in each category (`COUNT(owner_id)`).
    * Calculates the average of `avg_txn_per_month` for each category, rounded to one decimal place.
    * Groups the final results by `frequency_category`.

## Question 3: `Assessment_Q3.sql` - Account Inactivity Alert

```sql
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
```

### Per-Question Explanation:

This query attempts to find savings and investment accounts with no activity for over one year (365 days).

1.  **Savings Account Part:**
    * Selects the `id` as `plan_id`, `owner_id`, and adds a literal 'Savings' as the `type`.
    * `MAX(transaction_date)`: Finds the latest transaction date for each savings account. As noted in our previous discussion, this considers all transaction types (inflow, outflow, etc.).
    * `DATEDIFF(CURRENT_DATE, MAX(transaction_date)) AS inactivity_days`: Calculates the number of days since the last transaction.
    * Groups the results by `id` and `owner_id`.
    * `HAVING inactivity_days > 365`: Filters for accounts where the last transaction was more than 365 days ago.

2.  **Investment Account Part:**
    * Selects the `id` as `plan_id`, `owner_id`, and adds a literal 'Investment' as the `type`.
    * `MAX(created_on)`: Finds the latest creation date for investment plans. As discussed, `created_on` might not accurately reflect the last *transaction* date.
    * `DATEDIFF(CURRENT_DATE, MAX(created_on)) AS inactivity_days`: Calculates the number of days since the investment plan was created.
    * `WHERE is_deleted = 0 and is_a_fund = 1`: Filters for active investment fund accounts.
    * Groups the results by `id` and `owner_id`.
    * `HAVING inactivity_days > 365`: Filters for investment plans where the creation date was more than 365 days ago.


## Question 4: `Assessment_Q4.sql` - Customer Lifetime Value (CLV) Estimation

```sql
/*Question 4 Customer Lifetime Value (CLV) Estimation
Scenario: Marketing wants to estimate CLV based on account tenure and transaction
volume (simplified model).
Task: For each customer, assuming the profit_per_transaction is 0.1% of the transaction
value, calculate:
● Account tenure (months since signup)
● Total transactions
● Estimated CLV (Assume: CLV = (total_transactions / tenure) * 12 *
avg_profit_per_transaction)
● Order by estimated CLV from highest to lowest
Tables:
● users_customuser
● savings_savingsaccount*/

SELECT u.id AS customer_id,
       CONCAT(first_name, ' ', last_name) AS name,
       TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()) AS tenure_months, -- This gives the difference from when the user signed up and today
       COUNT(s.id) AS total_transactions,
       ROUND((COUNT(s.id) / (TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()))) * 12 * (0.001 * AVG(s.confirmed_amount)) / 100, 2) AS estimated_clv
/* Breaking down the code directly above
Estimated CLV (Assume: CLV = (total_transactions / tenure) * 12 * avg_profit_per_transaction)
COUNT(s.id) is the total_transactions,
(MONTH, u.date_joined, CURDATE()) are the tenure months
avg_profit_per_transaction is the avg_profit_per_transaction assuming the profit_per_transaction is 0.1% of the transaction
value
*/
FROM users_customuser u
LEFT JOIN savings_savingsaccount s
		ON u.id = s.owner_id
GROUP BY u.id, u.name
ORDER BY estimated_clv DESC;
```

### Per-Question Explanation:

This query estimates the Customer Lifetime Value (CLV) for each customer based on their account tenure and transaction volume in their savings accounts.

1.  **`SELECT` Clause:**
    * `u.id AS customer_id`: Selects the user ID as `customer_id`.
    * `CONCAT(first_name, ' ', last_name) AS name`: Concatenates the first and last names for the customer's name.
    * `TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()) AS tenure_months`: Calculates the account tenure in months by finding the difference between the `date_joined` from the `users_customuser` table and the current date.
    * `COUNT(s.id) AS total_transactions`: Counts the total number of savings accounts associated with each user. In this simplified model, each savings account entry is considered a transaction.
    * `ROUND((COUNT(s.id) / (TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()))) * 12 * (0.001 * AVG(s.confirmed_amount)) / 100, 2) AS estimated_clv`: Calculates the estimated CLV using the provided formula:
        * `(COUNT(s.id) / (TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE())))`: Average transactions per month.
        * `* 12`: Annualizes the average transactions.
        * `* (0.001 * AVG(s.confirmed_amount)) / 100`: Multiplies by the average profit per transaction. `0.001` represents 0.1%, and `AVG(s.confirmed_amount) / 100` calculates the average transaction value in Naira across all savings accounts.

2.  **`FROM` and `LEFT JOIN` Clauses:**
    * `FROM users_customuser u`: Starts with the `users_customuser` table.
    * `LEFT JOIN savings_savingsaccount s ON u.id = s.owner_id`: Performs a left join with the `savings_savingsaccount` table based on the `owner_id`. This includes all users, even those without any savings accounts (in which case `COUNT(s.id)` would be 0).

3.  **`GROUP BY` Clause:**
    * `GROUP BY u.id, u.name`: Groups the results by `customer_id` and `name` to perform the aggregate functions.

4.  **`ORDER BY` Clause:**
    * `ORDER BY estimated_clv DESC`: Orders the results by the calculated `estimated_clv` in descending order, showing the customers with the highest estimated CLV first.

## Challenges:

Based on the task, some were:

  * **Understanding the Data Model:** Without a clear schema diagram, correctly identifying the relationships between `users_customuser`, `savings_savingsaccount`, and `plans_plan` based on the column names (`owner_id`, `id`) was crucial.
  * **Addressing the "No Inflow" Requirement:** As highlighted in the explanation for Question 3, the provided query did not directly address the "no inflow transactions" requirement, indicating a potential misunderstanding or lack of specific transaction history data in the `savings_savingsaccount` and `plans_plan` tables as they are currently structured in that query. A resolution would involve querying separate transaction tables with a transaction type (inflow/outflow).
  * **Simplified CLV Model:** The CLV calculation in Question 4 was simplified by using the average `confirmed_amount` across all savings accounts. A more accurate CLV would typically consider the individual transaction values for each customer.

