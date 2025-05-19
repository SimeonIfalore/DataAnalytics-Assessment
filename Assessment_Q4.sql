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
