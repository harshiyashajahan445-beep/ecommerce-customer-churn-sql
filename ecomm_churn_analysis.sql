-- Select database
USE ecomm;

-- Disable Safe Update Mode temporarily so UPDATE/DELETE statements run smoothly
SET SQL_SAFE_UPDATES = 0;


-- 1. DATA CLEANING:

-- Impute Mode for categorical/count missing values
UPDATE customer_churn SET Tenure = 0 WHERE Tenure IS NULL;
UPDATE customer_churn SET CouponUsed = 1 WHERE CouponUsed IS NULL;
UPDATE customer_churn SET OrderCount = 1 WHERE OrderCount IS NULL;

-- Impute Mean (rounded) for continuous missing values
UPDATE customer_churn 
SET WarehouseToHome = (SELECT AVG(WarehouseToHome) FROM (SELECT WarehouseToHome FROM customer_churn) AS t) 
WHERE WarehouseToHome IS NULL;

UPDATE customer_churn 
SET HourSpendOnApp = (SELECT AVG(HourSpendOnApp) FROM (SELECT HourSpendOnApp FROM customer_churn) AS t) 
WHERE HourSpendOnApp IS NULL;

UPDATE customer_churn 
SET OrderAmountHikeFromlastYear = (SELECT AVG(OrderAmountHikeFromlastYear) FROM (SELECT OrderAmountHikeFromlastYear FROM customer_churn) AS t) 
WHERE OrderAmountHikeFromlastYear IS NULL;

UPDATE customer_churn 
SET DaySinceLastOrder = (SELECT AVG(DaySinceLastOrder) FROM (SELECT DaySinceLastOrder FROM customer_churn) AS t) 
WHERE DaySinceLastOrder IS NULL;

-- Remove extreme distance outliers (> 100 km)

DELETE FROM customer_churn WHERE WarehouseToHome > 100;

-- Standardize inconsistent text values.

UPDATE customer_churn SET PreferredLoginDevice = 'Mobile Phone' WHERE PreferredLoginDevice = 'Phone';
UPDATE customer_churn SET PreferedOrderCat = 'Mobile Phone' WHERE PreferedOrderCat = 'Mobile';
UPDATE customer_churn SET PreferredPaymentMode = 'Cash on Delivery' WHERE PreferredPaymentMode = 'COD';
UPDATE customer_churn SET PreferredPaymentMode = 'Credit Card' WHERE PreferredPaymentMode = 'CC';


-- 2. DATA TRANSFORMATION:

-- Rename misspelled or formatted columns

ALTER TABLE customer_churn RENAME COLUMN PreferedOrderCat TO `Preferred OrderCat`;
ALTER TABLE customer_churn RENAME COLUMN HourSpendOnApp TO HoursSpentOnApp;

-- Add user-friendly label columns for Complaint and Churn flags

ALTER TABLE customer_churn ADD COLUMN ComplaintReceived VARCHAR(3);
UPDATE customer_churn SET ComplaintReceived = CASE WHEN Complain = 1 THEN 'Yes' ELSE 'No' END;

ALTER TABLE customer_churn ADD COLUMN ChurnStatus VARCHAR(10);
UPDATE customer_churn SET ChurnStatus = CASE WHEN Churn = 1 THEN 'Churned' ELSE 'Active' END;

-- Drop redundant binary numeric columns

ALTER TABLE customer_churn DROP COLUMN Churn;
ALTER TABLE customer_churn DROP COLUMN Complain;

-- Re-enable Safe Update Mode
SET SQL_SAFE_UPDATES = 1;


-- 3. DATA EXPLORATION AND ANALYSIS QUERIES:

-- Count of churned and active customers
SELECT ChurnStatus, COUNT(*) AS CustomerCount 
FROM customer_churn 
GROUP BY ChurnStatus;

-- Average tenure and total cashback for churned customers
SELECT ROUND(AVG(Tenure), 2) AS AvgTenure, SUM(CashbackAmount) AS TotalCashback 
FROM customer_churn 
WHERE ChurnStatus = 'Churned';

-- Percentage of churned customers who complained
SELECT ROUND((COUNT(CASE WHEN ComplaintReceived = 'Yes' THEN 1 END) * 100.0) / COUNT(*), 2) AS PercentageComplained
FROM customer_churn 
WHERE ChurnStatus = 'Churned';

-- City tier with highest Laptop & Accessory churn
SELECT CityTier, COUNT(*) AS ChurnedCount 
FROM customer_churn 
WHERE ChurnStatus = 'Churned' AND `Preferred OrderCat` = 'Laptop & Accessory' 
GROUP BY CityTier 
ORDER BY ChurnedCount DESC 
LIMIT 1;

-- Most preferred payment mode among active customers
SELECT PreferredPaymentMode, COUNT(*) AS ActiveCount 
FROM customer_churn 
WHERE ChurnStatus = 'Active' 
GROUP BY PreferredPaymentMode 
ORDER BY ActiveCount DESC 
LIMIT 1;

-- Total order amount hike for single mobile phone buyers
SELECT SUM(OrderAmountHikeFromlastYear) AS TotalOrderHike 
FROM customer_churn 
WHERE MaritalStatus = 'Single' AND `Preferred OrderCat` = 'Mobile Phone';

-- Average devices registered for UPI users
SELECT ROUND(AVG(NumberOfDeviceRegistered), 2) AS AvgDevices 
FROM customer_churn 
WHERE PreferredPaymentMode = 'UPI';

-- City tier with highest customer count
SELECT CityTier, COUNT(*) AS CustomerCount 
FROM customer_churn 
GROUP BY CityTier 
ORDER BY CustomerCount DESC 
LIMIT 1;

-- Gender utilizing highest coupons
SELECT Gender, SUM(CouponUsed) AS TotalCoupons 
FROM customer_churn 
GROUP BY Gender 
ORDER BY TotalCoupons DESC 
LIMIT 1;

-- Max hours spent and count per order category
SELECT `Preferred OrderCat`, COUNT(*) AS CustomerCount, MAX(HoursSpentOnApp) AS MaxHours 
FROM customer_churn 
GROUP BY `Preferred OrderCat`;

-- Total orders for credit card users with max satisfaction score
SELECT SUM(OrderCount) AS TotalOrderCount 
FROM customer_churn 
WHERE PreferredPaymentMode = 'Credit Card' 
  AND SatisfactionScore = (SELECT MAX(SatisfactionScore) FROM customer_churn);

-- Average satisfaction score of complainants
SELECT ROUND(AVG(SatisfactionScore), 2) AS AvgSatisfaction 
FROM customer_churn 
WHERE ComplaintReceived = 'Yes';

-- Order categories with > 5 coupons used
SELECT DISTINCT `Preferred OrderCat` 
FROM customer_churn 
WHERE CouponUsed > 5;

-- Top 3 categories by average cashback
SELECT `Preferred OrderCat`, ROUND(AVG(CashbackAmount), 2) AS AvgCashback 
FROM customer_churn 
GROUP BY `Preferred OrderCat` 
ORDER BY AvgCashback DESC 
LIMIT 3;

-- Payment modes with avg tenure = 10 and total orders > 500
SELECT PreferredPaymentMode 
FROM customer_churn 
GROUP BY PreferredPaymentMode 
HAVING AVG(Tenure) = 10 AND SUM(OrderCount) > 500;

-- Distance category breakdown
SELECT 
    CASE 
        WHEN WarehouseToHome <= 5 THEN 'Very Close Distance'
        WHEN WarehouseToHome <= 10 THEN 'Close Distance'
        WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
        ELSE 'Far Distance'
    END AS DistanceCategory,
    ChurnStatus,
    COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY DistanceCategory, ChurnStatus
ORDER BY DistanceCategory, ChurnStatus;

-- Above-average orders for married customers in City Tier-1
SELECT CustomerID, PreferredPaymentMode, `Preferred OrderCat`, OrderCount, CashbackAmount 
FROM customer_churn 
WHERE MaritalStatus = 'Married' 
  AND CityTier = 1 
  AND OrderCount > (SELECT AVG(OrderCount) FROM customer_churn);

-- 4. CUSTOMER RETURNS TABLE & JOIN QUERY:


-- Create customer_returns table
CREATE TABLE IF NOT EXISTS customer_returns (
    ReturnID INT PRIMARY KEY,
    CustomerID INT,
    ReturnDate DATE,
    RefundAmount INT,
    FOREIGN KEY (CustomerID) REFERENCES customer_churn(CustomerID)
);

-- Insert return records
INSERT INTO customer_returns (ReturnID, CustomerID, ReturnDate, RefundAmount) VALUES
(1001, 50022, '2023-01-01', 2130),
(1002, 50316, '2023-01-23', 2000),
(1003, 51099, '2023-02-14', 2290),
(1004, 52321, '2023-03-08', 2510),
(1005, 52928, '2023-03-20', 3000),
(1006, 53749, '2023-04-17', 1740),
(1007, 54206, '2023-04-21', 3250),
(1008, 54838, '2023-04-30', 1990);

-- Query returns for churned customers who made complaints
SELECT 
    cr.ReturnID,
    cr.CustomerID,
    cr.ReturnDate,
    cr.RefundAmount,
    cc.Gender,
    cc.MaritalStatus,
    cc.CityTier,
    cc.PreferredPaymentMode,
    cc.`Preferred OrderCat`,
    cc.ChurnStatus,
    cc.ComplaintReceived
FROM customer_returns cr
JOIN customer_churn cc ON cr.CustomerID = cc.CustomerID
WHERE cc.ChurnStatus = 'Churned' AND cc.ComplaintReceived = 'Yes';