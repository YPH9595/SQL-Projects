-- @AUTHER JASMINE ABTAHI 


-- Create the Spending table to store user spend data
CREATE TABLE Spending (
    user_id INT,             -- ID of the user making the spend
    spend_date DATE,         -- Date of the spend
    platform VARCHAR(10),    -- Platform where the spend occurred (mobile/desktop)
    amount DECIMAL(10, 2)    -- Amount spent
);

-- Insert spend data into the Spending table
INSERT INTO Spending (user_id, spend_date, platform, amount)
VALUES
(1, '2019-07-01', 'mobile', 100),
(1, '2019-07-01', 'desktop', 100),
(2, '2019-07-01', 'mobile', 100),
(2, '2019-07-02', 'mobile', 100),
(3, '2019-07-01', 'desktop', 100),
(3, '2019-07-02', 'desktop', 100);

-- Create a Common Table Expression (CTE) to define base spend data by date and platform
WITH BASE AS (
    SELECT DISTINCT spend_date, 'desktop' AS platform
    FROM Spending

    UNION

    SELECT DISTINCT spend_date, 'mobile' AS platform
    FROM Spending

    UNION

    SELECT DISTINCT spend_date, 'both' AS platform
    FROM Spending
)

-- Final query to calculate total amount spent and total users by spend date and platform
SELECT 
    B.spend_date,                   -- Spend date
    B.platform,                     -- Platform (mobile, desktop, or both)
    ISNULL(SUM(S1.amount), 0) AS total_amount,  -- Total amount spent (0 if no spend)
    COUNT(DISTINCT S1.user_id) AS total_users   -- Total number of distinct users
FROM 
    Spending S1
    -- Self join on oppostie platforms to catch users that used both platforms 
    LEFT JOIN Spending S2 
        ON S1.user_id = S2.user_id
        AND S1.spend_date = S2.spend_date
        AND S1.platform != S2.platform
    -- Join the BASE CTE to the Spending table based on two conditions:
    RIGHT JOIN BASE B 
        ON 
        (
            -- Case 1: Join where both platforms ('mobile' and 'desktop') were used on the same date by the same user
            B.spend_date = S1.spend_date     
            AND S2.user_id IS NOT NULL       -- Ensure the user has spent on both platforms (S2 is not NULL)
            AND B.platform = 'both'          
        )
        OR 
        (
            -- Case 2: Join where only one platform ('mobile' or 'desktop') was used by the user
            B.spend_date = S1.spend_date     
            AND S2.user_id IS NULL           -- Ensure the user has spent on only one platform (S2 is NULL)
            AND B.platform = S1.platform      
        )
            
-- Group the results by spend date and platform to get aggregated data
GROUP BY 
    B.spend_date, B.platform
ORDER BY 
    B.spend_date, B.platform;
