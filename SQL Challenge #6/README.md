# Mastering SQL: Identifying Customers with Consecutive Increasing Transactions

In this article, we will explore how to write an SQL query that identifies customers who have made consecutive transactions with increasing amounts over several days. We’ll cover the logic step-by-step, and I'll guide you through a complex example that considers various edge cases. 

## The Problem
You have a table named `Transactions` with data about customer transactions, including the `transaction_ID`, `customer_ID`, `transaction_date`, and `amount`. Your goal is to find the customers who have made consecutive transactions with increasing amounts for at least three consecutive days. You also need to include the start and end dates of these periods.

Here’s the structure of the `Transactions` table:

```sql
CREATE TABLE Transactions (
    transaction_id INT PRIMARY KEY,
    customer_id INT,
    transaction_date DATE,
    amount DECIMAL(10, 2)
);
```
## Sample Data
To start, let’s insert some sample data into the `Transactions` table: 

```sql
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

```
## The SQL Query

To solve this problem, we need to:

   1. Identify consecutive transactions with increasing amounts.
   2. Group these sequences by customer and determine the start and end dates.
   3. Ensure that the sequences have at least three transactions.

Here’s the SQL query that accomplishes this:

```sql
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

-- Sum the sequence_flag to generate an indicator for each sequence
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
```
## Understanding the Query

1. **CTE (Common Table Expression):** We use a CTE to identify whether each transaction is partbol of a consecutive sequence with increasing amounts. The `IIF` function checks two things: 

    1. Whether the current transaction is happening the day after the previous transaction (`DATEDIFF` = 1) 
    2. Whether the amount of the current transaction is greater than the amount of the previous one. 

    If both conditions are met, meaning the transaction is part of the same sequence and we assign `0`. Otherwise, it marks the transaction as the start of a new sequence and we assign `1`. This is helpful when we sum these values to form group indicators. 

    |transaction_id|customer_id|transaction_date|amount|lag_date|lag_amount|sequence_flag|
    |---|---|---|---|---|---|---|
    |1|101|2023-05-01|100.00|NULL|NULL|1|
    |2|101|2023-05-02|150.00|2023-05-01|100.00|0|
    |3|101|2023-05-03|200.00|2023-05-02|150.00|0|
    |4|102|2023-05-01|50.00|NULL|NULL|1|
    |5|102|2023-05-03|100.00|2023-05-01|50.00|1|
    |6|102|2023-05-04|200.00|2023-05-03|100.00|0|
    |7|105|2023-05-01|100.00|NULL|NULL|1|
    |8|105|2023-05-02|150.00|2023-05-01|100.00|0|
    |9|105|2023-05-03|200.00|2023-05-02|150.00|0|
    |10|105|2023-05-04|300.00|2023-05-03|200.00|0|
    |11|105|2023-05-12|250.00|2023-05-04|300.00|1|
    |12|105|2023-05-13|260.00|2023-05-12|250.00|0|
    |13|105|2023-05-14|270.00|2023-05-13|260.00|0|

2. **Generating Indicators:** By summing up the `sequence_flag` cumulatively for each customer, we create unique values, or an `indicator`, that help identifying transaction sequences. If a transaction starts a new sequence, meaning that the treansaction has a `sequence_flag` of `1`, the `indicator` increases. 

    |transaction_id|customer_id|transaction_date|amount|sequence_flag|indicator|
    |---|---|---|---|---|---|
    |1|101|2023-05-01|100.00|1|1|
    |2|101|2023-05-02|150.00|0|1|
    |3|101|2023-05-03|200.00|0|1|
    |4|102|2023-05-01|50.00|1|1|
    |5|102|2023-05-03|100.00|1|2|
    |6|102|2023-05-04|200.00|0|2|
    |7|105|2023-05-01|100.00|1|1|
    |8|105|2023-05-02|150.00|0|1|
    |9|105|2023-05-03|200.00|0|1|
    |10|105|2023-05-04|300.00|0|1|
    |11|105|2023-05-12|250.00|1|2|
    |12|105|2023-05-13|260.00|0|2|
    |13|105|2023-05-14|270.00|0|2|


3. **Final Selection:** We group the results by `customer_id` and sequence `indicator`, selecting only those groups with more than two transactions (at least three consecutive transactions). The `MIN` and `MAX` functions give us the start and end dates of each sequence.

    |customer_id|consecutive_start|consecutive_end|
    |---|---|---|
    |101|2023-05-01|2023-05-03|
    |105|2023-05-01|2023-05-04|
    |105|2023-05-12|2023-05-14|

## Test Case for Comprehensive Testing
To fully test our query, we need a more complex dataset that includes different scenarios like gaps in dates, decreasing amounts, and consecutive decreasing sequences. Here’s a more intricate set of test data: 

```sql
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
```

## Conclusion

In this article, we explored how to write an SQL query that identifies customers with consecutive transactions of increasing amounts over multiple days. To make sure our solution is robust, we tested it with various test case senarios. 

Happy querying!