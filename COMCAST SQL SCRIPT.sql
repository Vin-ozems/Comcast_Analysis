CREATE DATABASE comcast;
USE comcast;
-- ---------------------------------------------------------- TABLE CREATION ---------------------------------------------------------------------------
CREATE TABLE comcast(
	Id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
	Ticket INT NOT NULL UNIQUE,
	Customer_Complaint VARCHAR(255) NOT NULL,	
	`Date` VARCHAR(20) NOT NULL,
	Date_month_year	VARCHAR(20) NOT NULL,
	`Time` VARCHAR(20) NOT NULL,
	Received_Via VARCHAR(25) NOT NULL,	
	City VARCHAR(25) NOT NULL,
	State VARCHAR(25) NOT NULL,	
	Zip_code INT NOT NULL,	
	`Status` VARCHAR(25) NOT NULL,	
	`Proxy` VARCHAR(5) NOT NULL,
INDEX idx_customer_compliant(Customer_Complaint),
INDEX idx_Received_Via(Received_Via),
INDEX idx_Status(`Status`)
);
-- ---------------------------------------------------------------------------------------------------------------------------------------------------
# TABLE IMPORT
-- Importing the comcast data using the import wizard
-- ---------------------------------------------------- DATA CLEANING --------------------------------------------------------------------------------
# CHECKING FOR DUPLICATE
SELECT Id, Ticket, Customer_Complaint, `Date`, 
       Date_month_year, `Time`, Received_Via, 
       City, State, Zip_code, `Status`, `Proxy`,COUNT(*) AS count
FROM comcast
GROUP BY Id, Ticket, Customer_Complaint, `Date`, 
       Date_month_year, `Time`, Received_Via, 
       City, State, Zip_code, `Status`, `Proxy`
HAVING COUNT(*) > 1;

# HANDLING MISSING VALUES
SELECT * 
FROM comcast
WHERE Id IS NULL OR Ticket IS NULL
                 OR Customer_Complaint IS NULL OR `Date` IS NULL
                 OR Date_month_year IS NULL OR `Time` IS NULL
                 OR Received_Via IS NULL OR City IS NULL OR State IS NULL 
                 OR Zip_code IS NULL OR `Status` IS NULL OR `Proxy` IS NULL;

# DATA STANDARDIZATION AND COLUMN NORMALIZATION
/*DATE CONVERSION FROM STRING DATA-TYPE TO DATE DATA-TYPE*/
SET SQL_SAFE_UPDATES = 0;
ALTER TABLE comcast ADD COLUMN New_Date DATE;
UPDATE comcast
SET New_Date = STR_TO_DATE(`Date`, '%d-%m-%Y');
ALTER TABLE comcast DROP COLUMN `Date`;
ALTER TABLE comcast CHANGE COLUMN New_Date `Date` DATE;

/*DATE CONVERSION FROM STRING DATA-TYPE TO DATE DATA-TYPE*/
ALTER TABLE comcast ADD COLUMN `month` VARCHAR(10);
UPDATE comcast
SET `month` = MONTHNAME(STR_TO_DATE(Date_month_year, '%d-%b-%y'));
ALTER TABLE comcast DROP COLUMN Date_month_year;

-- ----------------------------------------------------------- EDA ------------------------------------------------------------------------------------
# What is the total number of complaints received?
SELECT COUNT(*) 
FROM comcast;

# What is the most common complaint status?
SELECT `Status`, 
	   COUNT(*) AS Count 
FROM comcast 
GROUP BY Status 
ORDER BY Count DESC;

# What is the total number of complaints by city?
SELECT City, COUNT(*) AS Count 
FROM comcast 
GROUP BY City;

# What is the most common complaint received via channel?
SELECT Received_Via, 
	   COUNT(*) AS Count 
FROM comcast 
GROUP BY Received_Via 
ORDER BY Count DESC;

# Which customers have filed more than 5 complaints?*
SELECT ID AS CustomerID,
	   Ticket
FROM comcast 
GROUP BY CustomerID 
HAVING COUNT(*) > 5;

# How can we automatically update the complaint status to "verified" when the proxy is 'no' and problem 'solved'
DELIMITER $$
CREATE TRIGGER trg_UpdateStatusOnProxy
AFTER UPDATE ON comcast
FOR EACH ROW
BEGIN
    IF NEW.Proxy = 'No' AND OLD.Status = 'Solved' THEN
        UPDATE comcast
        SET Status = 'Verified'
        WHERE Ticket = NEW.Ticket;
    END IF;
END$$
DELIMITER ;

# How can we retrieve the top 10 complaints by city
DELIMITER //
CREATE PROCEDURE top_city()
BEGIN
    SELECT City, 
           COUNT(*) AS Count,
           ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS row_rank
    FROM comcast 
    GROUP BY City    
    ORDER BY COUNT(*) DESC;
END;
CALL top_city();


# Which month has the highest complaints?
WITH ComplaintCounts AS (
    SELECT MONTH(Date) AS ComplaintMonth, 
           MONTHNAME(Date) AS MonthName,
           COUNT(*) AS ComplaintCount
    FROM comcast
    GROUP BY MONTH(Date), MONTHNAME(Date)
),
MaxComplaintMonth AS (
    SELECT ComplaintMonth, 
           MonthName, 
           ComplaintCount
    FROM ComplaintCounts
    ORDER BY ComplaintCount DESC
    LIMIT 1
)
SELECT * 
FROM MaxComplaintMonth;



