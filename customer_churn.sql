1. Data Cleaning

-- Find Duplicates

SELECT Customer_ID
FROM telco
GROUP BY Customer_ID
HAVING COUNT(Customer_ID) > 1

-- Find the count of gender/seniority

SELECT
    COUNT(CASE WHEN Gender = 'Male' THEN 1 END) AS male,
    COUNT(CASE WHEN Gender = 'Female' THEN 1 END) AS female
FROM telco

***

SELECT
    COUNT(CASE WHEN Senior_Citizen = 'Yes' THEN 1 END) AS Yes_Senior,
    COUNT(CASE WHEN Senior_Citizen = 'No' THEN 1 END) AS No_Senior
FROM telco

---- Rank Seniority ------------------------------------------------------------------------------------------------------

WITH cte AS
(
SELECT Customer_ID,
CASE WHEN Senior_Citizen = 'Yes' THEN 'Senior'
      ELSE 'Non_senior'
      END as Seniority,
Contract,
Gender,
ROUND(AVG(Tenure_in_Months), 2) AS avg_tenure,
RANK() OVER(ORDER BY AVG(Monthly_Charge) DESC) AS rnk
FROM telco
WHERE Customer_Status = 'Churned'
GROUP by 1
)

SELECT * FROM cte
WHERE rnk <= 5

-- Total Count of Customers

SELECT COUNT(Customer_ID)
FROM telco

-- Find the percent of churned customers

SELECT Total_Customers, Churned_Customers,
ROUND((100.0 * Churned_Customers / Total_Customers), 2) AS Churned_Percent
  FROM
(SELECT COUNT(CASE WHEN Customer_Status IN ('Stayed', 'Churned')
                         THEN Customer_ID END) AS Total_Customers
              , COUNT(CASE WHEN Customer_Status = 'Churned'
                         THEN Customer_ID END) AS Churned_Customers
FROM telco) as cte;

---- Find the average monthly charges for churned customers

SELECT ROUND(AVG(Monthly_Charge), 2) as Avg_Charges
FROM telco
WHERE Customer_Status = 'Churned';

---- Find the average customers that joined, stayed, churned

SELECT
ROUND(AVG(CASE WHEN Customer_Status = 'Joined' THEN Age END), 2) AS Avg_Age_Joined,
ROUND(AVG(CASE WHEN Customer_Status = 'Stayed' THEN Age END), 2) AS Avg_Age_Stayed,
ROUND(AVG(CASE WHEN Customer_Status = 'Churned' THEN Age END), 2) AS Avg_Age_Churned
FROM telco

-- How much revenue was lost to churned customers

SELECT Customer_Status, COUNT(Customer_ID) AS Customers,
ROUND((SUM(Total_Revenue) * 100.0) / SUM(SUM(Total_Revenue)) OVER(), 1) as Revenue
FROM telco
GROUP BY Customer_Status
ORDER BY Revenue DESC

-- What was typical tenure for churned customers

SELECT
    CASE
        WHEN Tenure_in_Months <= 6 THEN '6 months'
        WHEN Tenure_in_Months <= 12 THEN '1 Year'
        WHEN Tenure_in_Months <= 24 THEN '2 Years'
        ELSE '> 2 Years'
    END AS Tenure,
    ROUND(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER(),1) AS Churn_Percentage
FROM telco
WHERE Customer_Status = 'Churned'
GROUP BY Tenure
ORDER BY Churn_Percentage DESC;

-- What are the feedback or complaints form churned customers

SELECT Churn_Category, COUNT(Customer_ID) AS churn_customers
FROM telco
WHERE Customer_Status = 'Churned'
AND Tenure_in_Months < 4
GROUP BY 1
ORDER BY 2 DESC

SELECT Churn_Category, Churn_Reason, COUNT(Customer_ID) AS churn_customers
FROM telco
WHERE Customer_Status = 'Churned'
AND Churn_Category LIKE '%Other%'
GROUP BY 1, 2
ORDER BY 3 DESC

UPDATE telco -----------------------------------------------------------------------------------------
SET Churn_Category =
CASE WHEN 'Churn_Reason' IN('Moved', 'Deceased') THEN 'Personal Circumstances'
             WHEN 'Churn_Reason' = "Don't Know" THEN 'Personal Unknown'
    WHEN 'Churn_Reason' = 'Poor expertise of online support' THEN 'Dissatisfaction'
END;


---- Replace NULL values with NA under Churn Reason column
UPDATE telco
SET Churn_Reason="NA"
WHERE Churn_Reason IS NULL;


---- Replace NULL values with NA under Churn Reason
UPDATE telco
SET Churn_Category ="NA"
Where Churn_Category IS NULL

---- Calculate the percentage for churn customers ----------------------------------------------------------------------------
WITH cte AS
(
select count(Customer_ID)  AS cnt_customers
FROM telco
WHERE Customer_Status = 'Churned'
)

SELECT Churn_Category,
(SELECT cnt_customers FROM cte) as cnt_customers,
((SELECT cnt_customers FROM cte) / 7043) * 100 AS percent
FROM telco


-- Count the net retention of customers this month (Round)

SELECT Churn_Revenue, Nonchurn_Revenue,
               Nonchurn_Revenue - Churn_Revenue as Net_Retention
FROM (
SELECT SUM(CASE WHEN Customer_Status = 'Stayed'
THEN Monthly_Charge
END
) as nonchurn_revenue,
SUM(CASE WHEN Customer_Status = 'Churned'
THEN Monthly_charge
END
) as churn_revenue
 FROM telco
) as cte;

---- Calculate the percent of net retention

SELECT Total_Customers, Churn_Customers,
               ROUND((100 * churn_customers / total_customers), 0) as Churn_Percent
FROM (
SELECT ROUND(SUM(CASE WHEN Customer_Status IN('Stayed', 'Churned')
THEN Monthly_Charge
END
), 0) as Total_Customers,
ROUND(SUM(CASE WHEN Customer_Status = 'Churned'
THEN Monthly_charge
END
), 0) as Churn_Customers
 FROM telco
) as cte;

-- Which cities have the highest churn rate

SELECT
    City,
    COUNT(Customer_ID) AS Churned,
    CEILING(COUNT(CASE WHEN Customer_Status = 'Churned' THEN Customer_ID ELSE NULL END) * 100.0 / COUNT(Customer_ID)) AS Churn_Rate
FROM telco
GROUP BY City
HAVING COUNT(Customer_ID)  > 30
AND
COUNT(CASE WHEN Customer_Status = 'Churned' THEN Customer_ID ELSE NULL END) > 0
ORDER BY Churn_Rate DESC;


-- What are the general reasons for churn (Churn Category)

SELECT
  Churn_Category,  
  ROUND(SUM(Total_Revenue),0)AS Churned_Sum,
  CEILING((COUNT(Customer_ID) * 100.0) / SUM(COUNT(Customer_ID)) OVER()) AS Churn_Percentage
FROM telco
WHERE Customer_Status = 'Churned'
GROUP BY Churn_Category
ORDER BY Churn_Percentage DESC;

---- What offer did churned customers have

SELECT  
    Offer,
    ROUND(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churned
FROM telco
WHERE Customer_Status = 'Churned'
GROUP BY Offer
ORDER BY Churned DESC;

---- What internet type did churned customers have

SELECT
    Internet_Type,
    COUNT(Customer_ID) AS Churned,
    ROUND(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churn_Percentage
FROM telco
WHERE Customer_Status = 'Churned'
GROUP BY Internet_Type
ORDER BY Churned DESC;

-------- Find the total number of internet service based on the customer status

WITH CountData AS (
  SELECT
    Customer_Status,
    Internet_Service,
    COUNT(*) AS Total
  FROM telco
  WHERE Internet_Service IS NOT NULL
  GROUP BY Customer_Status, Internet_Service
),
TotalPerStatus AS (
  SELECT
    Customer_Status,
    SUM(Total) AS StatusTotal
  FROM CountData
  GROUP BY Customer_Status
)
SELECT
  CountData.Customer_Status,
  CountData.Internet_Service,
  CountData.Total,
  ROUND((CountData.Total * 100 / TotalPerStatus.StatusTotal), 2) AS Percentage
FROM CountData
JOIN TotalPerStatus ON CountData.Customer_Status = TotalPerStatus.Customer_Status
ORDER BY CountData.Customer_Status DESC, CountData.Internet_Service;

-------- Avg_Monthly_GB_Download

SELECT
Customer_Status,
ROUND(AVG(Avg_Monthly_GB_Download),1) as Average_Download
FROM telco
WHERE Avg_Monthly_GB_Download IS NOT NULL
GROUP BY Customer_Status
ORDER BY Average_Download DESC;


---- Did churned customers have premium tech support

SELECT
    Premium_Tech_Support,
    COUNT(Customer_ID) AS Churned,
    ROUND(COUNT(Customer_ID) *100.0 / SUM(COUNT(Customer_ID)) OVER(),1) AS Churn_Percentage
FROM telco
WHERE Customer_Status = 'Churned'
GROUP BY Premium_Tech_Support
ORDER BY Churned DESC;

---- What contract were churned customers on

SELECT
    Contract,
    COUNT(Customer_ID) AS Churned,
    ROUND(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churn_Percentage
FROM telco
WHERE Customer_Status = 'Churned'
GROUP BY Contract
ORDER BY Churned DESC;

-------- Contract

WITH TotalStatus AS (
  SELECT
    Customer_Status,
    COUNT(*) as TotalPerStatus
  FROM telco
  WHERE Contract IS NOT NULL
  GROUP BY Customer_Status
)

SELECT
  a.Customer_Status,
  a.Contract,
  COUNT(a.Contract) as Total,
  ROUND(COUNT(a.Contract) * 100.0 / b.TotalPerStatus, 1) as Percentage
FROM telco a
JOIN TotalStatus b ON a.Customer_Status = b.Customer_Status
WHERE a.Contract IS NOT NULL
GROUP BY a.Customer_Status, a.Contract, b.TotalPerStatus
ORDER BY a.Customer_Status, Total DESC;

-- Do having dependents correlated with churned

SELECT
main.Customer_Status,
main.Number_of_Dependents as Dependents,
COUNT(*) AS Total,
ROUND(COUNT(*) * 100 / Total_Status.Total_Per_Status, 1) AS Taxa
FROM telco main
JOIN (
SELECT
Customer_Status,
COUNT(*) AS Total_Per_Status
FROM telco
GROUP BY Customer_Status
) AS Total_Status
ON main.Customer_Status = Total_Status.Customer_Status
GROUP BY main.Customer_Status, main.Number_of_Dependents, Total_Status.Total_Per_Status
ORDER BY main.Customer_Status ASC, Dependents;

-- Payment Method

WITH cte AS
(
SELECT Payment_Method, COUNT(Customer_ID) as Churn
FROM telco
WHERE Churn_Label LIKE 'Yes'
GROUP BY Payment_Method
),
cte2 AS
(
SELECT Payment_Method, COUNT(Customer_ID) as Non_Churn
FROM telco
WHERE Churn_Label LIKE 'No'
GROUP BY Payment_Method
)

SELECT a.Payment_Method, a.Churn, b.Non_Churn,
a.Churn + b.Non_Churn AS total,
SUM(a.Churn + b.Non_Churn) OVER(ORDER BY a.Payment_Method) AS Running_Total
FROM cte a
INNER JOIN cte2 b
ON a.Payment_Method = b.Payment_Method
