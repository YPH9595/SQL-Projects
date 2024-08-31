# 1645 - Hopper Company Queries II [LeetCode]

Write an SQL query to calculate the percentage of working drivers (working_percentage) for each month of 2020. The working percentage is determined by the ratio of drivers who accepted rides in a given month to the total number of drivers available during that month.

* If the number of available drivers during a month is zero, the working_percentage should be 0.00.
* The result should display all months from 1 to 12 (January to December), with the working_percentage rounded to two decimal places.


`Drivers`: Stores information about drivers and the date they joined the platform.

| driver_id | join_date  |
|-----------|------------|
| 10        | 2019-12-10 |
| 8         | 2020-01-13 |
| 5         | 2020-02-16 |
| 7         | 2020-03-08 |
| 4         | 2020-05-17 |
| 1         | 2020-10-24 |
| 6         | 2021-01-05 |

`Rides`: Contains information about rides requested by users and the date of request.

| ride_id | user_id | requested_at |
|---------|---------|--------------|
| 6       | 75      | 2019-12-09   |
| 1       | 54      | 2020-02-09   |
| 10      | 63      | 2020-03-04   |
| 19      | 39      | 2020-04-06   |
| 3       | 41      | 2020-06-03   |
| 13      | 52      | 2020-06-22   |
| 7       | 69      | 2020-07-16   |
| 17      | 70      | 2020-08-25   |
| 20      | 81      | 2020-11-02   |
| 5       | 57      | 2020-11-09   |
| 2       | 42      | 2020-12-09   |
| 11      | 68      | 2021-01-11   |
| 15      | 32      | 2021-01-17   |
| 12      | 11      | 2021-01-19   |
| 14      | 18      | 2021-01-27   |

`AcceptedRides`: Details about rides that have been accepted by drivers, including distance and duration. 

| ride_id | driver_id | ride_distance | ride_duration |
|---------|-----------|---------------|---------------|
| 10      | 10        | 63            | 38            |
| 13      | 10        | 73            | 96            |
| 7       | 8         | 100           | 28            |
| 17      | 7         | 119           | 68            |
| 20      | 1         | 121           | 92            |
| 5       | 7         | 42            | 101           |
| 2       | 4         | 6             | 38            |
| 11      | 8         | 37            | 43            |
| 15      | 8         | 108           | 82            |
| 12      | 8         | 38            | 34            |
| 14      | 1         | 90            | 74            |



## Solution
We will approach the problem in four comprehensive steps:

1. Generate a sequence of months from 1 to 12.
2. Calculate the cumulative total number of drivers available by each month in 2020.
3. Determine the number of active drivers for each month in 2020.
4. Compute the working percentage for each month and present the final result.

Let's explore each step in detail.


### Step 1: Generate a Sequence of Months from 1 to 12
Ensure that all months from January to December are represented in the final result, even if there is no data for certain months. 
* We create a Common Table Expression (CTE) named `Months`.
* The CTE recursively generates numbers from 1 to 12, each representing a month of the year.
* `SELECT 1 AS month`: Initiates the sequence with month 1 (January).
* `UNION ALL SELECT month + 1 FROM Months WHERE month < 12`: Recursively adds 1 to the previous month until it reaches 12 (December).

```sql
WITH Months AS (
    SELECT 1 AS month
    UNION ALL
    SELECT month + 1
    FROM Months
    WHERE month < 12
)
```
| month |
|-------|
| 1     |
| 2     |
| 3     |
| 4     |
| 5     |
| 6     |
| 7     |
| 8     |
| 9     |
| 10    |
| 11    |
| 12    |

### Step 2: Calculate the Cumulative Total Number of Drivers Available by Each Month in 2020
Determine how many drivers were available (i.e., had joined the platform) up to each month in 2020. 
1. Joining Months and Drivers:

    * We perform a `FULL JOIN` between the `Months` CTE and the `Drivers` table.
    * Join Condition: `MONTH(d.join_date) = m.month AND YEAR(d.join_date) = 2020`
    * WHERE Condition: `YEAR(join_date) IS NULL OR YEAR(join_date) <= 2020`
    * This ensures we consider drivers who joined **on or before** each month in 2020 and include all months even if no drivers joined in a particular month.

2. Grouping and Counting Drivers per Month:

    * `GROUP BY m.month`: Groups records by each month.
    * `COUNT(d.driver_id)`: Counts the number of drivers who joined in that specific month.

3. Calculating Cumulative Total:

    * `SUM(COUNT(d.driver_id)) OVER (ORDER BY m.month) AS total_drivers`:
        * The window function calculates a running total of drivers up to each month.
        * This gives us the cumulative number of drivers available by the end of each month. 
```sql
TotalDrivers AS (
    SELECT 
        m.month,
        -- Use SUM() as a window function to get the cumulative count of drivers who joined up to that month
        SUM(COALESCE(drivers_joined, 0)) OVER (ORDER BY m.month) AS total_drivers
    FROM (
        -- For each month, count the number of drivers who joined in that month
        SELECT 
            m.month,
            COUNT(d.driver_id) AS drivers_joined
        FROM 
            Months m
        FULL JOIN 
            Drivers d 
        ON 
            MONTH(d.join_date) = m.month 
            AND YEAR(d.join_date) = 2020
        WHERE 
            YEAR(join_date) IS NULL 
            OR YEAR(join_date) <= 2020
        GROUP BY 
            m.month
    ) m
)
```
|month|total_drivers|
|---|---|
|NULL|1|
|1|2|
|2|3|
|3|4|
|4|4|
|5|5|
|6|5|
|7|5|
|8|5|
|9|5|
|10|6|
|11|6|
|12|6|

### Step 3: Determine the Number of Active Drivers for Each Month in 2020
Identify how many drivers were actively working (i.e., accepted at least one ride) in each month of 2020.

1. Joining Rides and AcceptedRides:

    * `INNER JOIN` between `Rides` and `AcceptedRides` on `ride_id`.
    * Ensures we only consider rides that were accepted by drivers.

2. Filtering for Year 2020:

    * `WHERE YEAR(r.requested_at) = 2020`: Focuses only on rides requested in 2020.

3. Grouping and Counting Active Drivers:

    * `GROUP BY MONTH(r.requested_at)`: Groups data by each month.
    * `COUNT(DISTINCT a.driver_id)`: Counts unique drivers who accepted rides in each month.

```sql
ActiveDrivers AS (
    SELECT 
        MONTH(r.requested_at) AS month,
        COUNT(DISTINCT a.driver_id) AS active_drivers
    FROM 
        Rides r
    -- Join with the AcceptedRides table to consider only rides that were accepted by a driver
    INNER JOIN 
        AcceptedRides a 
    ON 
        r.ride_id = a.ride_id
    WHERE 
        YEAR(r.requested_at) = 2020
    GROUP BY 
        MONTH(r.requested_at)
)
```
|month|active_drivers|
|---|---|
|3|1|
|6|1|
|7|1|
|8|1|
|11|2|
|12|1|

### Step 4: Compute the Working Percentage for Each Month and Present the Final Result
Calculate the working percentage for each month by comparing active drivers to total available drivers and compile the final result set.

1. Joining All Data Sources:

    * `LEFT JOIN` between `Months` and `TotalDrivers` on `month`.
    * `LEFT JOIN` between the `result` and `ActiveDrivers` on `month`.
    * `LEFT JOIN`s ensure that all months are included, even if there are no drivers or no active drivers in a particular month.

2. Calculating Working Percentage:

    * `COALESCE(a.active_drivers, 0)`: If `active_drivers` is `NULL` (no active drivers), defaults to `0`.
    * `COALESCE(t.total_drivers, 1)`: If `total_drivers` is `NULL` (no drivers available), defaults to `1` to avoid division by zero.
    * `(active_drivers * 100.0) / total_drivers`: Calculates the percentage.
    * `ROUND(..., 2)`: Rounds the result to two decimal places.

3. Ordering Results:

    * `ORDER BY m.month`: Ensures the results are displayed from January to December.

```sql
SELECT 
    m.month,
    -- Calculate the percentage of active drivers out of the total available drivers
    ROUND(
        COALESCE(a.active_drivers, 0) * 100.0 / 
        COALESCE(t.total_drivers, 1), 
    2) AS working_percentage
FROM 
    Months m
-- Left join with TotalDrivers to get the cumulative count of drivers up to each month
LEFT JOIN 
    TotalDrivers t 
ON 
    m.month = t.month
-- Left join with ActiveDrivers to get the count of active drivers for each month
LEFT JOIN 
    ActiveDrivers a 
ON 
    m.month = a.month
ORDER BY 
    m.month;
```
`FinalResult`:
|month|working_percentage|
|---|---|
|1|0.000000000000|
|2|0.000000000000|
|3|25.000000000000|
|4|0.000000000000|
|5|0.000000000000|
|6|20.000000000000|
|7|20.000000000000|
|8|20.000000000000|
|9|0.000000000000|
|10|0.000000000000|
|11|33.330000000000|
|12|16.670000000000|


## Conclusion

Thank you for taking the time to explore this solution! 

I hope you found the explanation and the SQL query helpful. If you have any questions, suggestions, or ideas to improve the code, feel free to reach out or open an issue. 

