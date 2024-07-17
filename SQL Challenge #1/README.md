# **SQL CHALLENGE: Calculating the number of remaining inventories**

*We want to generate an inventory age report which would show the distribution of remaining inventory across the length of time the inventory has been sitting at the warehouse. We are trying to classify the inventory on hand across the below 4 buckets to denote the time the inventory has been lying the warehouse*.

`0-90 days old`<br />
`91-180 days old`<br />
`181-270 days old`<br />
`271–365 days old`

*For example, the warehouse received 100 units yesterday and shipped 30 units today, then there are 70 units which are a day old*.

*The warehouses use FIFO (first in first out) approach to manage inventory, i.e., the inventory that comes first will be sent out first*. 

### `WAREHOUSE` Table:

|ID    |OnHandQuantity|OnHandQuantityDelta|event_type|event_datetime         |
|------|--------------|-------------------|----------|-----------------------|
|SH0013|278           |99                 |OutBound  |2020-05-25 00:25:00.000|
|SH0012|377           |31                 |InBound   |2020-05-24 22:00:00.000|
|SH0011|346           |1                  |OutBound  |2020-05-24 15:01:00.000|
|SH0010|346           |1                  |OutBound  |2020-05-23 05:00:00.000|
|SH009 |348           |102                |InBound   |2020-04-25 18:00:00.000|
|SH008 |246           |43                 |InBound   |2020-04-25 02:00:00.000|
|SH007 |203           |2                  |OutBound  |2020-02-25 09:00:00.000|
|SH005 |334           |1                  |OutBound  |2020-02-18 08:00:00.000|
|SH006 |205           |129                |OutBound  |2020-02-18 07:00:00.000|
|SH004 |335           |27                 |OutBound  |2020-01-29 05:00:00.000|
|SH003 |362           |120                |InBound   |2019-12-31 02:00:00.000|
|SH002 |242           |8                  |OutBound  |2019-05-22 00:50:00.000|
|SH001 |250           |250                |InBound   |2019-05-20 00:45:00.000|

###  `RESULT` Table:
Your output must look like this: 
|0-90 days old|91-180 days old|181-270 days old|271-365 days old|
|---|---|---|---|
|176|102|0|0|


## **Solution**
The items that come in first will go out first. Imagine all items listed in the order of their arrival dates. Now, each time an item is sold (`OutBound`), we cross off one of the (`InBound`) items. To implement this logic, we can expand our table to include a column of `1`'s, with one `1` for each `InBound` item. We will also add another column with one `1` for each `OutBound` item. By putting these two columns together and subtracting the outbound values from the `InBound` values, the `1`'s in the `InBound` column that are not subtracted to zero represent the remaining items. 

1) The `CTE` starts by listing each `InBound` and `OutBound` event types with an initial quantity of `1`.

```SQL
WITH CTE AS (
    SELECT 1 AS QUANTITY, event_datetime, event_type
    FROM WAREHOUSE
```

|QUANTITY|event_datetime|event_type|
|---|---|---|
|1|2019-05-20 00:45:00.000|InBound|
|1|2020-05-23 05:00:00.000|OutBound|
|1|2020-05-24 15:01:00.000|OutBound|
|1|2020-05-24 22:00:00.000|InBound|
|1|2020-05-25 00:25:00.000|OutBound|
|1|2019-05-22 00:50:00.000|OutBound|
|1|2019-12-31 02:00:00.000|InBound|
|1|2020-01-29 05:00:00.000|OutBound|
|1|2020-02-18 08:00:00.000|OutBound|
|1|2020-02-18 07:00:00.000|OutBound|
|1|2020-02-25 09:00:00.000|OutBound|
|1|2020-04-25 02:00:00.000|InBound|
|1|2020-04-25 18:00:00.000|InBound|

2) The recursive part of the `CTE` expands this to multiple rows, one for each unit up to the total quantity (`OnHandQuantityDelta`).

```SQL
--ADD ROWS UNTIL THE THRESHOLD (OnHandQuantityDelta #) IS MET 
WITH CTE AS (
    SELECT 1 AS QUANTITY, event_datetime, event_type --BASE 
    FROM WAREHOUSE
    UNION ALL --ITERATION
    SELECT CTE.QUANTITY + 1, CTE.event_datetime, CTE.event_type
    FROM CTE
    JOIN WAREHOUSE W 
        ON CTE.event_datetime = W.event_datetime 
       AND CTE.QUANTITY + 1 <= W.OnHandQuantityDelta
),
```
|QUANTITY|event_datetime|event_type|
|---|---|---|
|1|2019-05-20 00:45:00.000|InBound|
|1|2020-05-23 05:00:00.000|OutBound|
|1|2020-05-24 15:01:00.000|OutBound|
|...|...|...| 
|246|2019-05-20 00:45:00.000|InBound|
|247|2019-05-20 00:45:00.000|InBound|
|248|2019-05-20 00:45:00.000|InBound|
|249|2019-05-20 00:45:00.000|InBound|
|250|2019-05-20 00:45:00.000|InBound|
|...|...|...| 

3) Each row (representing a single unit) is ranked by its `event_datetime` within its `event_type`.

```SQL
--ADD 1'S COLUMN AND ROW NUMBER 
RANKED AS (
    SELECT 1 AS QUANTITY, event_datetime, event_type, 
           ROW_NUMBER() OVER (PARTITION BY event_type ORDER BY event_datetime) AS rank
    FROM CTE
),
```
|QUANTITY|event_datetime|event_type|rank|
|---|---|---|---|
|1|2019-05-20 00:45:00.000|InBound|1|
|1|2019-05-20 00:45:00.000|InBound|2|
|1|2019-05-20 00:45:00.000|InBound|3|
|...|...|...| 
|1|2020-05-25 00:25:00.000|OutBound|266|
|1|2020-05-25 00:25:00.000|OutBound|267|
|1|2020-05-25 00:25:00.000|OutBound|268|
|...|...|...| 

4) Each row of the `InBound` unit is joined to its corresponding `OutBound` unit where they have equal row numbers.

```SQL
REMAINED AS (
    SELECT R1.QUANTITY AS In_QUANTITY, R1.event_type AS In_event_type, R1.rank AS In_rank, 
           R2.QUANTITY AS Out_QUANTITY, R2.event_type AS Out_event_type, R2.rank AS Out_rank
    FROM RANKED R1
    LEFT JOIN RANKED R2 
        ON R1.rank = R2.rank 
       AND R1.event_type != R2.event_type
	   WHERE R1.event_type = 'Inbound'
```
|In_QUANTITY|In_event_type|In_rank|Out_QUANTITY|Out_event_type|Out_rank|
|---|---|---|---|---|---|
|1|InBound|1|1|OutBound|1|
|1|InBound|2|1|OutBound|2|
|1|InBound|3|1|OutBound|3|
|...|...|...| 
|1|InBound|266|1|OutBound|266|
|1|InBound|267|1|OutBound|267|
|1|InBound|268|1|OutBound|268|
|1|InBound|269|NULL|NULL|NULL|
|1|InBound|270|NULL|NULL|NULL|
|1|InBound|271|NULL|NULL|NULL|
|...|...|...| 
|1|InBound|546|NULL|NULL|NULL|

5) We then substract these two columns, and calculate remaining items. 

```SQL
--CALCULATE REMAINED ITEMS 
REMAINED AS (
    SELECT R1.event_datetime, 
           SUM(R1.QUANTITY - ISNULL(R2.QUANTITY, 0)) AS remained 
    FROM RANKED R1
    LEFT JOIN RANKED R2 
        ON R1.rank = R2.rank 
       AND R1.event_type != R2.event_type
    WHERE R1.event_type = 'Inbound'
    GROUP BY R1.event_datetime
), 
```
|event_datetime|remained|
|---|---|
|2019-05-20 00:45:00.000|0|
|2019-12-31 02:00:00.000|102|
|2020-04-25 02:00:00.000|43|
|2020-04-25 18:00:00.000|102|
|2020-05-24 22:00:00.000|31|

6) Now, we assign each `remained` row to an `event_period` based on the age of the `event_datetime`, and relative to the latest `event_datetime`.

```SQL
--CRETAE THE 4 PERIOD INTERVALS 
PERIODS AS (
    SELECT remained, 
           CASE 
               WHEN event_datetime < DATEADD(DAY, -365, latest) THEN 0
               WHEN event_datetime < DATEADD(DAY, -270, latest) 
                    AND event_datetime >= DATEADD(DAY, -365, latest) THEN 1
               WHEN event_datetime < DATEADD(DAY, -180, latest) 
                    AND event_datetime >= DATEADD(DAY, -270, latest) THEN 2
               WHEN event_datetime < DATEADD(DAY, -90, latest) 
                    AND event_datetime >= DATEADD(DAY, -180, latest) THEN 3
               ELSE 4
           END AS event_period
    FROM REMAINED 
    CROSS JOIN (
        SELECT MAX(event_datetime) AS latest 
        FROM WAREHOUSE
    ) MAX_DAY 
), 
```

|remained|event_period|
|---|---|
|0|0|
|102|3|
|43|4|
|102|4|
|31|4|

7) Lastly, we aggregate the `remained` column, and add columns for each age period.

```SQL
--ADD THE RIGHT COLUMNS FOR OUTPUT 
RESULT AS (
    SELECT SUM(remained) AS total_remained, event_period
    FROM PERIODS 
    GROUP BY event_period
)
--REDUCE THE RESULT TABLE TO ONE ROW 
SELECT MAX(CASE WHEN event_period = 4 THEN total_remained ELSE 0 END) AS '0-90 days old',
       MAX(CASE WHEN event_period = 3 THEN total_remained ELSE 0 END) AS '91-180 days old',
       MAX(CASE WHEN event_period = 2 THEN total_remained ELSE 0 END) AS '181-270 days old',
       MAX(CASE WHEN event_period = 1 THEN total_remained ELSE 0 END) AS '271-365 days old'
FROM RESULT 
OPTION (MAXRECURSION 0); --INFINITE LOOP CTE
```

|0-90 days old|91-180 days old|181-270 days old|271-365 days old|
|-------------|---------------|----------------|----------------|
|176          |102            |0               |0               |


