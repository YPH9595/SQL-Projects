--@AUTHER JASMINE ABTAHI

-- Create the Transactions table
CREATE TABLE Transactions (
    transaction_id INT PRIMARY KEY,
    customer_id INT,
    transaction_date DATE,
    amount DECIMAL(10, 2)
);

-- Insert sample data into the Transactions table
INSERT INTO Transactions (transaction_id, customer_id, transaction_date, amount)
VALUES
(1, 101, '2023-05-01', 100),
(2, 101, '2023-05-02', 150),
(3, 101, '2023-05-03', 200),
(4, 102, '2023-05-01', 50),
(5, 102, '2023-05-03', 100),
(6, 102, '2023-05-04', 200),
(7, 105, '2023-05-01', 100),
(8, 105, '2023-05-02', 150),
(9, 105, '2023-05-03', 200),
(10, 105, '2023-05-04', 300),
(11, 105, '2023-05-12', 250),
(12, 105, '2023-05-13', 260),
(13, 105, '2023-05-14', 270);

----------------------------------------------------------------------------------
-- Insert complex test data into the Transactions table
INSERT INTO Transactions (transaction_id, customer_id, transaction_date, amount)
VALUES
-- Customer 201: No increasing sequence (same amounts)
(14, 201, '2023-06-01', 100),
(15, 201, '2023-06-02', 100),
(16, 201, '2023-06-03', 100),

-- Customer 202: Two different increasing sequences
(17, 202, '2023-06-01', 50),
(18, 202, '2023-06-02', 100),
(19, 202, '2023-06-03', 150), -- First sequence
(20, 202, '2023-06-05', 60),
(21, 202, '2023-06-06', 120),
(22, 202, '2023-06-07', 180), -- Second sequence

-- Customer 203: Sequence with a break in dates
(23, 203, '2023-06-01', 100),
(24, 203, '2023-06-02', 150),
(25, 203, '2023-06-04', 200), -- Break in the sequence (skips a day)

-- Customer 204: Mixed sequence (increase followed by a decrease)
(26, 204, '2023-06-01', 100),
(27, 204, '2023-06-02', 150),
(28, 204, '2023-06-03', 140), -- Break in the sequence (amount decreases)
(29, 204, '2023-06-04', 160), -- New sequence starts

-- Customer 205: Long sequence with consistent increases
(30, 205, '2023-06-01', 10),
(31, 205, '2023-06-02', 20),
(32, 205, '2023-06-03', 30),
(33, 205, '2023-06-04', 40),
(34, 205, '2023-06-05', 50),

-- Customer 206: Sequence with the same amounts, then increases
(35, 206, '2023-06-01', 200),
(36, 206, '2023-06-02', 200),
(37, 206, '2023-06-03', 300), -- Start of increasing sequence
(38, 206, '2023-06-04', 400),
(39, 206, '2023-06-05', 500),

-- Customer 207: Sequences with non-consecutive transactions in the middle
(40, 207, '2023-06-01', 100),
(41, 207, '2023-06-02', 150),
(42, 207, '2023-06-03', 200),
(43, 207, '2023-06-05', 180), -- Not part of the increasing sequence (decrease)
(44, 207, '2023-06-06', 210),
(45, 207, '2023-06-07', 220);

----------------------------------------------------------------------------------

-- View the inserted data
SELECT * FROM Transactions;

-- CTE (Common Table Expression) to identify consecutive transactions with increasing amounts
WITH CTE AS (
    SELECT 
        *,
        -- Check if the current transaction is part of a consecutive sequence with increasing amounts
        IIF(
            DATEDIFF(DAY, LAG(transaction_date) OVER(PARTITION BY customer_id ORDER BY transaction_date), transaction_date) = 1 
            AND amount > LAG(amount) OVER(PARTITION BY customer_id ORDER BY transaction_date),
            0,  -- Part of the sequence
            1   -- Start of a new sequence
        ) AS sequence_flag 
    FROM Transactions
),

-- Sum the sequence_flag to generate an indicator in order to group each sequence
T AS (
    SELECT 
        *, 
        SUM(sequence_flag) OVER(PARTITION BY customer_id ORDER BY transaction_date) AS indicator
    FROM CTE
)

-- Final query to find the customers with at least three consecutive transactions of increasing amounts
SELECT 
    customer_id, 
    MIN(transaction_date) AS consecutive_start,  -- Start date of the consecutive transactions period
    MAX(transaction_date) AS consecutive_end    -- End date of the consecutive transactions period
FROM T
GROUP BY customer_id, indicator
HAVING COUNT(*) > 2  -- Ensure there are at least three consecutive transactions
ORDER BY customer_id, consecutive_start;
