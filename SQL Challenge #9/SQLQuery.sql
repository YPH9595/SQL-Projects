-- @AUTHOR: JASMINE ABTAHI

-- Drop the 'Sales' table if it exists
IF EXISTS (SELECT * FROM sysobjects WHERE name='Sales' AND xtype='U')
BEGIN
    DROP TABLE Sales;
END;
GO  -- Separates the batch to ensure the 'Sales' table is dropped before proceeding

-- Drop the 'Product' table if it exists
IF EXISTS (SELECT * FROM sysobjects WHERE name='Product' AND xtype='U')
BEGIN
    DROP TABLE Product;
END;
GO  -- Separates the batch to ensure the 'Product' table is dropped before proceeding

-- Create the 'Product' table with product_id as the primary key
CREATE TABLE Product (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50)
);

-- Insert sample data into the 'Product' table
INSERT INTO Product (product_id, product_name)
VALUES
    (1, 'LC Phone'),
    (2, 'LC T-Shirt'),
    (3, 'LC Keychain');

-- Create the 'Sales' table with a foreign key reference to the 'Product' table
CREATE TABLE Sales (
    product_id INT,
    period_start DATE,
    period_end DATE,
    average_daily_sales INT,
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

-- Insert sample data into the 'Sales' table
INSERT INTO Sales (product_id, period_start, period_end, average_daily_sales)
VALUES
    (1, '2019-01-25', '2019-02-28', 100),
    (2, '2018-12-01', '2020-01-01', 10),
    (3, '2019-12-01', '2020-01-31', 1);

-------------------------------------------------------------
-- Recursive CTE to split sales data by year boundaries 

WITH CTE AS (
    -- Select the main sales data, adjusting 'period_end' to the year-end if necessary
    SELECT *,
           CASE 
               WHEN DATEFROMPARTS(YEAR(period_start), 12, 31) > period_end 
               THEN period_end 
               ELSE DATEFROMPARTS(YEAR(period_start), 12, 31) 
           END AS period_end_main
    FROM Sales

    UNION ALL 

    -- Recursive part: carry over sales periods into the next year, splitting by year boundaries
    SELECT product_id,
           DATEFROMPARTS(YEAR(period_start) + 1, 1, 1),  -- Start the next period from the beginning of the next year
           period_end,
           average_daily_sales,
           CASE -- Adjust 'period_end' to the year-end if necessary
               WHEN DATEFROMPARTS(YEAR(period_start) + 1, 12, 31) > period_end 
               THEN period_end 
               ELSE DATEFROMPARTS(YEAR(period_start) + 1, 12, 31)
           END
    FROM CTE 
    WHERE YEAR(period_start) + 1 <= YEAR(period_end)  -- Continue splitting until the entire period is covered
)

-- Final select statement to calculate total sales per year
SELECT 
    CTE.product_id,
    product_name, 
    YEAR(period_start) AS report_year, 
    -- Calculate the total number of days in the sales period
    (DATEDIFF(DAY, period_start, period_end_main) + 1)
    -- Multiply the number of days by the average daily sales to get the total amount of sales
    * average_daily_sales AS total_amount
FROM CTE
JOIN Product P ON CTE.product_id = P.product_id  -- Join with the Product table to get product names
ORDER BY CTE.product_id, report_year;  
