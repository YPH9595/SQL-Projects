# SQL CHALLENGE 

Imagine a warehouse where the available items are stored as per different batches as indicated in the BATCH table.
Customers can purchase multiple items in a single order as indicated in ORDERS table.

Write an SQL query to determine items for each order are taken from which batch. 
Assume that items are sequencially taken from each batch starting from the first batch.

### BATCH		
|BATCH_ID|QUANTITY|
|---|---|
|B1|5|
|B2|12|
|B3|8|

### ORDERS		
|ORDER_NUMBER|QUANTITY|
|---|---|
|O1|2|
|O2|8|
|O3|2|
|O4|5|
|O5|9|
|O6|5|

### EXPECTED OUTPUT	
|ORDER_NUMBER|BATCH_ID|QUANTITY|
|---|---|---|
|O1|B1|2|
|O2|B1|3|
|O2|B2|5|
|O3|B2|2|
|O4|B2|5|
|O5|B3|8|

## Solution
We need to expand our tables using CTE (Common Table Expression) to create rows with a value of 1 in the quantity column. By adding the ROW_NUMBER() function, we can then join these two tables on the ROW_NUMBER() column and group them in order to count the sum of items that have a quantity of 1. This will help us determine which order needs to match with which batch.

```
-- EXPANDING THE BATCH TABLE WITH 1'S USING CTE (COMMON TABLE EXPRESSION)
WITH BATCH_CTE AS
    (SELECT BATCH_ID, 1 AS QUANTITY -- BASE 
    FROM BATCH
    UNION ALL
    SELECT BATCH_CTE.BATCH_ID, BATCH_CTE.QUANTITY + 1 -- RECURSION 
    FROM BATCH_CTE
    JOIN BATCH ON BATCH.BATCH_ID = BATCH_CTE.BATCH_ID AND BATCH_CTE.QUANTITY + 1 <= BATCH.QUANTITY),

    BATCH_ONES AS
    (SELECT ROW_NUMBER() OVER(ORDER BY BATCH_ID) AS ROW_NUMBER, BATCH_ID, 1 AS QUANTITY
    FROM BATCH_CTE),

	...
```


### Prerequisites

This script was written in MySQL using Microsoft SQL Server Management Studio (SSMS). For installation:


* [Install SQL Server 2022 on Windows](https://www.microsoft.com/en-us/sql-server/sql-server-downloads)
* [Download SQL Server Management Studio (SSMS)](https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-ver16)


### Result
|ORDER_NUMBER|BATCH_ID|QUANTITY|
|---|---|---|
|O1|B1|2|
|O2|B1|3|
|O2|B2|5|
|O3|B2|2|
|O4|B2|5|
|O5|B3|8|

## Acknowledgments

Inspired by:
* [techTFQ YouTube](https://www.youtube.com/watch?v=7skZzocEU6c&list=PLavw5C92dz9Fahr7taauUx5RnTfuGyL--&index=10)
* [techTFQ blog](https://techtfq.com/blog/lets-simplify-and-solve-a-complex-sql-interview-problem)


