CREATE DATABASE saas_db;
USE saas_db;
DROP TABLE IF EXISTS saas_churn;

CREATE TABLE saas_churn (
    Customer_Id VARCHAR(50),
    Signup_Date DATE,
    Plan_Type VARCHAR(50),
    Industry VARCHAR(100),
    Company_Size VARCHAR(50),
    Country VARCHAR(50),
    Acquisition_Channel VARCHAR(50),
    Billing_Cycle VARCHAR(50),
    Seats_Purchased INT,
    Seats_Active INT,
    Mrr DECIMAL(10, 2),
    Onboarding_Completed VARCHAR(10),
    Avg_Monthly_Logins DECIMAL(10, 2),
    Features_Used_Count INT,
    Days_Since_Last_Login INT,
    Support_Tickets_90D INT,
    Avg_Resolution_Hours DECIMAL(10, 2),
    Csat_Score DECIMAL(3, 2),
    Failed_Payments_6M INT,
    Payment_Method VARCHAR(50),
    Customer_Status VARCHAR(50),
    Churn_Date DATE NULL,
    Tenure_Months INT,
    Churn_Reason VARCHAR(255)
);


-- Business Problem: A B2B SaaS company is facing a customer loss problem, where many users are canceling their paid subscriptions every month. Because of this, the company is losing Monthly Recurring Revenue (MRR) despite acquiring new customers. 
-- The goal of this project is to analyze customer usage data, support logs, and payment patterns to find the main reasons behind customer cancellation and identify high-risk users before they leave, so the customer success team can take early action to retain them.

-- Start Analysing Data

-- -------------------------------------------

SELECT * FROM saas_churn;

-- KPI Summary: Overall Customer & Revenue Churn Observation:

-- 1. Total Customer Churn Rate stands at 14.94% (6,559 out of 43,912 customers).
-- 2. Revenue Churn Rate is 10.51%, leading to a total Monthly Recurring Revenue (MRR) loss of $14.44M out of $137.39M. 
-- 3. Indicates a significant revenue leakage requiring immediate retention focus.


SELECT COUNT(*) AS Total_Customers,
SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) AS Churned_Customers,
ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Churn_Rate_Pct,
ROUND(SUM(Mrr), 2) AS Total_MRR,
ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN Mrr ELSE 0 END), 2) AS MRR_Lost,
ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN Mrr ELSE 0 END) * 100.0 / SUM(Mrr), 2) AS MRR_Churn_Rate_Pct
FROM Saas_Churn;

-- -------x--------x---------x----------

-- Churn Driver Analysis: Key Reasons & Revenue Impact Observation:

-- 1. "Low Product Usage" is the single largest churn driver, accounting for 32.37% of churned accounts (2,123 customers).
-- 2. "Pricing Too High" is the second leading cause at 22.73% (1,491 customers).
-- 3. Combined, poor engagement and pricing concerns drive over 55% of total customer cancellations, pointing to product adoption & value-perception gaps.

SELECT Churn_Reason,
COUNT(*) AS Churned_Count,
ROUND(SUM(Mrr), 2) AS Revenue_Lost,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS Percentage_Share
FROM Saas_Churn
WHERE Customer_Status = 'Churned'
GROUP BY Churn_Reason
ORDER BY Churned_Count DESC;

-- -------x--------x---------x----------

-- Product Engagement & Usage Behavior Analysis Observation:

-- 1. Churned customers show significantly lower engagement, averaging only 10.62 monthly logins compared to 22.52 logins for Active customers (~53% drop).
-- 2. Feature utilization is lower in churned users (4.22 features vs 6.84 for active users), indicating incomplete onboarding or low product adoption.
-- 3. Inactivity is more than double for churned users (17.81 average inactive days vs 7.68 days for active users), serving as a clear early indicator of churn risk.

SELECT Customer_Status,
ROUND(AVG(Avg_Monthly_Logins), 2) AS Avg_Logins,
ROUND(AVG(Features_Used_Count), 2) AS Avg_Features_Used,
ROUND(AVG(Days_Since_Last_Login), 2) AS Avg_Days_Inactive
FROM Saas_Churn
GROUP BY Customer_Status;

-- -------x--------x---------x----------


-- Support Experience & Customer Satisfaction (CSAT) Impact Observation:

-- 1. Churned customers report lower satisfaction, with an average CSAT score of 2.85 compared to 3.43 for Active customers.
-- 2. Support resolution times are higher for churned users (13.46 hours avg vs 10.99 hours for active users), indicating support bottlenecks.
-- 3. Churned accounts submit slightly more support tickets (1.44 vs 1.21 in 90 days), showing that unresolved or lingering issues accelerate customer drop-off.

SELECT Customer_Status,
ROUND(AVG(Support_Tickets_90D), 2) AS Avg_Tickets_90D,
ROUND(AVG(Avg_Resolution_Hours), 2) AS Avg_Resolution_Time,
ROUND(AVG(Csat_Score), 2) AS Avg_CSAT
FROM Saas_Churn
GROUP BY Customer_Status;

-- -------x--------x---------x----------


-- Customer Churn Risk Scoring (Early Warning System) Observation:

-- 1. Segments active accounts into 3 distinct risk tiers to enable proactive retention:

-- High Risk: Accounts with extreme inactivity (>30 days), low logins (<3/month), poor CSAT (<=2), or payment failures (>=2). Requires urgent outreach.
-- Medium Risk: Accounts showing early warning signs like moderate inactivity (15-30 days) or average satisfaction (CSAT = 3).
-- Low Risk: Highly engaged and satisfied accounts with stable payments.
  
-- 2. Ordering by MRR DESC prioritizes high-revenue Enterprise accounts first, helping Customer Success teams prevent maximum potential revenue loss.

SELECT Customer_Id, Plan_Type, Mrr, Avg_Monthly_Logins, Days_Since_Last_Login, Failed_Payments_6M, Csat_Score,
CASE WHEN Days_Since_Last_Login > 30 OR Avg_Monthly_Logins < 3 OR Failed_Payments_6M >= 2 OR Csat_Score <= 2
THEN 'High Risk' WHEN Days_Since_Last_Login BETWEEN 15 AND 30 OR Csat_Score = 3 THEN 'Medium Risk'
ELSE 'Low Risk' END AS Churn_Risk_Level
FROM Saas_Churn
WHERE Customer_Status = 'Active'
ORDER BY Mrr DESC;

-- -------x--------x---------x----------


-- Customer Tenure & Onboarding Cohort Analysis Observation:

-- 1. Churn risk is highest during early tenure, peaking at Month 1 (52.35% churn rate) and remaining high in Month 2 (37.84%) and Month 3 (25.17%).
-- 2. Indicates major friction during the initial customer onboarding phase, where new users struggle to see immediate product value.
-- 3. Customer retention stabilizes significantly as tenure increases (drops to ~10% by Month 5). Focusing on early onboarding assistance can directly reduce overall churn.


SELECT Tenure_Months,
COUNT(*) AS Total_Customers,
SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) AS Churned_Customers,
ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Churn_Rate_Pct
FROM Saas_Churn
GROUP BY Tenure_Months
ORDER BY Tenure_Months ASC;

-- -------x--------x---------x----------

-- Plan Type Churn & Revenue Impact Analysis Observation:

-- 1. Enterprise plan has the lowest churn rate at 8.80%, but causes the highest revenue loss ($7.31M) due to high contract value / MRR per user.
-- 2. Basic plan suffers from the highest churn rate at 17.10% (3,311 users churned), followed closely by the Pro plan at 15.14% (2,599 users churned).
-- 3. Shows that while lower-tier plans lose more volume, losing even a few Enterprise accounts severely impacts total recurring revenue.

SELECT Plan_Type,
COUNT(*) AS Total_Customers,
SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) AS Churned_Count,
ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Churn_Rate_Pct,
ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN Mrr ELSE 0 END), 2) AS Revenue_Lost
FROM Saas_Churn
GROUP BY Plan_Type
ORDER BY Revenue_Lost DESC;

-- -------x--------x---------x----------

-- Support Escalation & Ticket Volume Analysis Observation:

-- 1. Churn rate increases directly with ticket volume, jumping from 12.05% for 0 tickets to 22.57% for accounts with 4+ support tickets.
-- 2. Average resolution time is highest for the '4+ Tickets' bucket (17.6 hours), indicating that complex or unresolved issues lead to higher customer frustration.
-- 3. High ticket volume combined with slow resolution is a strong churn trigger. Setting priority SLAs for multi-ticket accounts can help reduce churn.


SELECT
CASE WHEN Support_Tickets_90D = 0 THEN '0 Tickets'
WHEN Support_Tickets_90D BETWEEN 1 AND 3 THEN '1-3 Tickets'
ELSE '4+ Tickets' END AS Ticket_Bucket,
COUNT(*) AS Total_Users,
ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Churn_Rate_Pct,
ROUND(AVG(Avg_Resolution_Hours), 1) AS Avg_Resolution_Time
FROM Saas_Churn
GROUP BY Ticket_Bucket;

-- -------x--------x---------x----------

-- Seat Utilization & License Adoption Analysis Observation:

-- 1. Churned customers show much lower seat utilization at 57.02% (avg 30.9 active seats out of 56.6 purchased), compared to 77.18% for Active users.
-- 2. Under-utilization of purchased licenses indicates low adoption and shelfware, making customers feel they are overpaying for unused value.
-- 3. Monitoring seat usage can trigger early success interventions (e.g. offering downsell options or team onboarding) before the customer decides to cancel.

SELECT Customer_Status,
ROUND(AVG(Seats_Purchased), 1) AS Avg_Seats_Bought,
ROUND(AVG(Seats_Active), 1) AS Avg_Seats_Active,
ROUND(AVG(Seats_Active * 100.0 / NULLIF(Seats_Purchased, 0)), 2) AS Seat_Utilization_Pct
FROM Saas_Churn
GROUP BY Customer_Status;

-- -------x--------x---------x----------

-- Onboarding Completion Impact on Churn Observation:

-- 1. Customers who did not complete onboarding churn at 39.5%, against only 8.0% for those who did (~5x higher).
-- 2. Combined with the early-tenure spike (Month 1-3), this shows onboarding failure is the biggest controllable churn driver.
-- 3. Making onboarding completion mandatory (guided setup, check-in calls in the first 30 days) can directly cut early churn.

SELECT Onboarding_Completed,
COUNT(*) AS Total_Customers,
SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) AS Churned_Customers,
ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Churn_Rate_Pct,
ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN Mrr ELSE 0 END), 2) AS Revenue_Lost,
ROUND(AVG(Features_Used_Count), 2) AS Avg_Features_Used
FROM Saas_Churn
GROUP BY Onboarding_Completed
ORDER BY Churn_Rate_Pct DESC;

-- -------x--------x---------x----------

-- Billing Cycle Churn Analysis Observation:

-- 1. Monthly-billed customers churn at 17.5% compared to 10.2% for Annual customers.
-- 2. Annual contracts lock customers in and give them time to see value, so retention is naturally higher.
-- 3. Offering a discount to move Monthly customers to Annual plans can reduce churn and stabilize recurring revenue.

SELECT Billing_Cycle,
COUNT(*) AS Total_Customers,
SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) AS Churned_Customers,
ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Churn_Rate_Pct,
ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN Mrr ELSE 0 END), 2) AS Revenue_Lost
FROM Saas_Churn
GROUP BY Billing_Cycle
ORDER BY Churn_Rate_Pct DESC;

-- -------x--------x---------x----------

-- Company Size Churn Analysis Observation:

-- 1. Smallest companies (1-10 employees) churn at 18.1%, while large companies (1000+ employees) churn at only 9.0%.
-- 2. Churn falls steadily as company size grows, so small businesses are the most price-sensitive and least committed segment.
-- 3. Small accounts need low-touch, automated retention, while large accounts need dedicated account management to protect high MRR.

SELECT Company_Size,
COUNT(*) AS Total_Customers,
SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) AS Churned_Customers,
ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Churn_Rate_Pct,
ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN Mrr ELSE 0 END), 2) AS Revenue_Lost
FROM Saas_Churn
GROUP BY Company_Size
ORDER BY FIELD(Company_Size, '1-10 employees', '11-50 employees', '51-200 employees', '201-1000 employees', '1000+ employees');

-- -------x--------x---------x----------

-- Onboarding x Billing Cycle Combined Risk Observation:

-- 1. Combining the two strongest drivers identifies the most vulnerable customer segment.
-- 2. Customers with incomplete onboarding on a Monthly plan are expected to show the highest churn, making them the top target for early intervention.

SELECT Onboarding_Completed, Billing_Cycle,
COUNT(*) AS Total_Customers,
ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Churn_Rate_Pct,
ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN Mrr ELSE 0 END), 2) AS Revenue_Lost
FROM Saas_Churn
GROUP BY Onboarding_Completed, Billing_Cycle
ORDER BY Churn_Rate_Pct DESC;

-- END --