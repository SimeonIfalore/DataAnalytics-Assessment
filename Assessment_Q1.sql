-- Question 1  High-Value Customers with Multiple Products
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
