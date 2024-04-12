# SQL CHALLENGE: Calculating the number of remaining inventories in the past 90, 180, 270, and 365 days 

We want to generate an inventory age report which would show the distribution of remaining inventory across the length of time the inventory has been sitting at the warehouse. We are trying to classify the inventory on hand across the below 4 buckets to denote the time the inventory has been lying the warehouse.

0-90 days old<br />
91-180 days old<br />
181-270 days old<br />
271 – 365 days old

For example, the warehouse received 100 units yesterday and shipped 30 units today, then there are 70 units which are a day old.

The warehouses use FIFO (first in first out) approach to manage inventory, i.e., the inventory that comes first will be sent out first. 

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


## Solution
Since the items in this warehouse are shipped out based on a first-in, first-out (FIFO) algorithm, we can simplify the logic as follows:

* If the current on-hand quantity in the warehouse is 100 and we have 30 items that were shipped in within the last 90 days (latest batch), we can be sure that all 30 items from the latest batch are still remaining since the total on-hand quantity is greater than 30. And there are 100 - 30 = 70 remaining items from previous batches. 

* On the other hand, if the total on-hand quantity is smaller than 30 (e.g., 10), we can deduce that there are 30 - 10 = 20 remaining items within the 0-90 days batch and all the previous batches have 0 items remained.

```
-- PERIOD 1: DAY 1 TO 90
SUM_InBound_1 AS
	(SELECT SUM(OnHandQuantityDelta) AS SUM_InBound
	FROM WAREHOUSE, DAYS
	WHERE event_datetime >= DAY_90 AND event_type = 'InBound'),

REMAINING_1 AS
	(SELECT CASE
			WHEN LATEST_QUANTITY > SUM_InBound_1.SUM_InBound THEN SUM_InBound_1.SUM_InBound
			ELSE LATEST_QUANTITY
			END AS REMAINING
	FROM SUM_InBound_1, DAYS), 
```


### Prerequisites

This script was written in MySQL using Microsoft SQL Server Management Studio (SSMS). For installation:


* [Install SQL Server 2022 on Windows](https://www.microsoft.com/en-us/sql-server/sql-server-downloads)
* [Download SQL Server Management Studio (SSMS)](https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-ver16)


### Result
|0-90 days old|91-180 days old|181-270 days old|271-365 days old|
|-------------|---------------|----------------|----------------|
|176          |102            |0               |0               |








## Acknowledgments

Inspired by:
* [techTFQ YouTube](https://www.youtube.com/watch?v=xN2PRAd8IZQ&list=PLavw5C92dz9Fahr7taauUx5RnTfuGyL--)
* [techTFQ blog](https://techtfq.com/blog/real-sql-interview-question-asked-by-a-faang-company)


