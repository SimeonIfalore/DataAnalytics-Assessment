
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
)

-- Final Output: Aggregate by frequency category
SELECT 
    frequency_category,
    COUNT(owner_id) AS customer_count,
    ROUND(AVG(avg_txn_per_month), 1) AS avg_transactions_per_month
FROM categorized_customers
GROUP BY frequency_category;

