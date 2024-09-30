# 1384 - Total Sales Amount by Year [LeetCode]

*Write a solution to report the total sales amount of each item for each year, with corresponding `product_name`, `product_id`, `report_year`, and `total_amount`.*


`Product` Table: 
|product_id|product_name|
|---|---|
|1|LC Phone|
|2|LC T-Shirt|
|3|LC Keychain|


`Sales` Table:
|product_id|period_start|period_end|average_daily_sales|
|---|---|---|---|
|1|2019-01-25|2019-02-28|100|
|2|2018-12-01|2020-01-01|10|
|3|2019-12-01|2020-01-31|1|


`Output` Table: 
|product_id|product_name|report_year|total_amount|
|---|---|---|---|
|1|LC Phone|2019|3500|
|2|LC T-Shirt|2018|310|
|2|LC T-Shirt|2019|3650|
|2|LC T-Shirt|2020|10|
|3|LC Keychain|2019|31|
|3|LC Keychain|2020|31|

In this post, we’ll explore how to solve this problem using **Recursive SQL Common Table Expressions (CTEs)**. If you’re someone who wants to understand SQL better or love tackling real-world database queries, you’re in the right place! 

## Solution
When the sales period spans multiple years, we need to split the sales by year and calculate how much was sold in each year. This is where things get interesting! Here’s how we can break it down:

### Step 1: Split sales by year: 
If the sales period goes across more than one year, we need to calculate the sales separately for each year. For example, if sales start in 2019 and end in 2020, we need to calculate the total for 2019 and then for 2020. 
1. **Initial Sales Period**: In the base part of the `CTE`, we select the main sales data but ensure that if the sales period goes beyond December 31st of any year, we cut it off at that point. We use `CASE` and `DATEFROMPARTS` to determine whether the sales end within the same year or spill over into the next.
 
```sql
    -- Select the main sales data, adjusting 'period_end' to the year-end if necessary
    SELECT *,
           CASE 
               WHEN DATEFROMPARTS(YEAR(period_start), 12, 31) > period_end 
               THEN period_end 
               ELSE DATEFROMPARTS(YEAR(period_start), 12, 31) 
           END AS period_end_main
    FROM Sales
```
|product_id|period_start|period_end|average_daily_sales|period_end_main|
|---|---|---|---|---|
|1|2019-01-25|2019-02-28|100|2019-02-28|
|2|2018-12-01|2020-01-01|10|2018-12-31|
|3|2019-12-01|2020-01-31|1|2019-12-31|

2. **Recursive Part**: In the second part, we handle the sales periods that span into the next year. For example, if sales start in 2019 but continue into 2020, we create a new row for the next year and adjust the sales end period accordingly. Just like the first step, we ensure that if the sales period goes beyond December 31st of any year, we cut it off at that point. We use `CASE` and `DATEFROMPARTS` to determine whether the sales end within the same year or spill over into the next. This recursion keeps running until all years in the sales period are accounted for.
```sql
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
```
|product_id|period_start|period_end|average_daily_sales|period_end_main|
|---|---|---|---|---|
|1|2019-01-25|2019-02-28|100|2019-02-28|
|2|2018-12-01|2020-01-01|10|2018-12-31|
|2|2019-01-01|2020-01-01|10|2019-12-31|
|2|2020-01-01|2020-01-01|10|2020-01-01|
|3|2019-12-01|2020-01-31|1|2019-12-31|
|3|2020-01-01|2020-01-31|1|2020-01-31|


### Step 2: Count number of days in each sales year: 

The `average_daily_sales` column provides the average number of sales per day. By calculating the number of days within each sales year and multiplying it by the `average_daily_sales`, we can determine the total sales for that year. We use `DATEDIFF` to calculate the number of days between `period_start` and `period_end_main`.
 
```sql
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
```
|product_id|product_name|report_year|total_amount|
|---|---|---|---|
|1|LC Phone|2019|3500|
|2|LC T-Shirt|2018|310|
|2|LC T-Shirt|2019|3650|
|2|LC T-Shirt|2020|10|
|3|LC Keychain|2019|31|
|3|LC Keychain|2020|31|

