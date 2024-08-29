# 2494 - Merge Overlapping Events in the Same Hall [LeetCode]

Write an SQL query to merge all the overlapping events that are held in the same hall. Two events overlap if they have at least one day in common.

### `HallEvents`:

|hall_id|start_day|end_day|
|---|---|---|
|1|2023-01-01|2023-01-02|
|1|2023-01-10|2023-01-20|
|1|2023-01-13|2023-01-14|
|1|2023-01-14|2023-01-17|
|1|2023-02-15|2023-02-25|
|1|2023-02-18|2023-02-22|
|1|2023-02-18|2023-02-25|
|2|2022-12-09|2022-12-23|
|2|2022-12-13|2022-12-17|
|2|2023-01-19|2023-01-23|
|2|2023-01-22|2023-01-28|
|3|2022-12-01|2023-01-30|
|3|2023-01-21|2023-01-29|
|3|2023-01-25|2023-02-05|
|3|2023-02-01|2023-02-07|
|4|2023-02-02|2023-02-06|
|4|2023-02-05|2023-02-10|
|4|2023-03-01|2023-03-02|


### `Output`:

|hall_id|start_day|end_day|
|---|---|---|
|1|2023-01-01|2023-01-02|
|1|2023-01-10|2023-01-20|
|1|2023-02-15|2023-02-25|
|2|2022-12-09|2022-12-23|
|2|2023-01-19|2023-01-28|
|3|2022-12-01|2023-02-07|
|4|2023-02-02|2023-02-10|
|4|2023-03-01|2023-03-02|



## Solution
To effectively merge overlapping events within each hall, we need to start by identifying which events overlap. After that, the key is to group events that share common days by an `indicator`. This `indicator` can be determined by checking if the `start_day` of an event falls within the date range of the previous event in an ordered sequence.

Logically, an event overlaps with the previous one if its `start_day` is less than or equal to the previous event's `end_day`. To achieve this, we can use the `LAG()` window function. This logic is demonstrated in the following SQL code:

```sql
SELECT 
    *, 
    LAG(end_day) OVER(PARTITION BY hall_id ORDER BY start_day, end_day) AS previous_end_day, 
    IIF(
        LAG(end_day) OVER(PARTITION BY hall_id ORDER BY start_day, end_day) >= start_day, 
        'Yes', 
        'No'
    ) AS overlap
FROM 
    HallEvents;
```
|hall_id|start_day|end_day|previous_end_day|overlap|
|---|---|---|---|---|
|1|2023-01-01|2023-01-02|NULL|No|
|1|2023-01-10|2023-01-20|2023-01-02|No|
|1|2023-01-13|2023-01-14|2023-01-20|Yes|
|1|2023-01-14|2023-01-17|2023-01-14|Yes|
|1|2023-02-15|2023-02-25|2023-01-17|No|
|1|2023-02-18|2023-02-22|2023-02-25|Yes|
|1|2023-02-18|2023-02-25|2023-02-22|Yes|
|2|2022-12-09|2022-12-23|NULL|No|
|2|2022-12-13|2022-12-17|2022-12-23|Yes|
|2|2023-01-19|2023-01-23|2022-12-17|No|
|2|2023-01-22|2023-01-28|2023-01-23|Yes|
|3|2022-12-01|2023-01-30|NULL|No|
|3|2023-01-21|2023-01-29|2023-01-30|Yes|
|3|2023-01-25|2023-02-05|2023-01-29|Yes|
|3|2023-02-01|2023-02-07|2023-02-05|Yes|
|4|2023-02-02|2023-02-06|NULL|No|
|4|2023-02-05|2023-02-10|2023-02-06|Yes|
|4|2023-03-01|2023-03-02|2023-02-10|No|

While `Yes` and `No` can indicate overlaps, they aren't suitable for grouping events effectively since they don't provide unique identifiers for each group. To create a more specific `indicator`, we can assign numeric values: `1` for `No` (no overlap) and `0` for `Yes` (overlap).

By using the `SUM()` window function to cumulatively add these values, we can achieve our goal. The `0` values won't change the cumulative sum, meaning that if an event overlaps with the previous one (i.e., `Yes`), it will inherit the same group `indicator` as the previous event. This continues until we encounter a non-overlapping event (`No`), where the `indicator` will increment, marking the start of a new group.

This approach allows us to generate unique group identifiers for each set of overlapping events, enabling effective grouping and merging in the subsequent steps.

```sql
WITH CTE AS 
(
    SELECT *, 
           IIF(LAG(end_day) OVER(PARTITION BY hall_id ORDER BY start_day, end_day) >= start_day, 0, 1) AS overlap
    FROM HallEvents
)

    SELECT *, 
           SUM(overlap) OVER(PARTITION BY hall_id ORDER BY start_day, end_day) AS indicator
    FROM CTE; 
```
|hall_id|start_day|end_day|overlap|indicator|
|---|---|---|---|---|
|1|2023-01-01|2023-01-02|1|1|
|1|2023-01-10|2023-01-20|1|2|
|1|2023-01-13|2023-01-14|0|2|
|1|2023-01-14|2023-01-17|0|2|
|1|2023-02-15|2023-02-25|1|3|
|1|2023-02-18|2023-02-22|0|3|
|1|2023-02-18|2023-02-25|0|3|
|2|2022-12-09|2022-12-23|1|1|
|2|2022-12-13|2022-12-17|0|1|
|2|2023-01-19|2023-01-23|1|2|
|2|2023-01-22|2023-01-28|0|2|
|3|2022-12-01|2023-01-30|1|1|
|3|2023-01-21|2023-01-29|0|1|
|3|2023-01-25|2023-02-05|0|1|
|3|2023-02-01|2023-02-07|0|1|
|4|2023-02-02|2023-02-06|1|1|
|4|2023-02-05|2023-02-10|0|1|
|4|2023-03-01|2023-03-02|1|2|

### Result
Now that we have our group indicators, it's time for the last step: group the events in each hall and calculate the start day and end day of each group. 

With our group indicators in place, the final step is to group the events within each hall based on these indicators. Then, we'll calculate the earliest `start_day` and the latest `end_day` for each group, effectively merging the overlapping events.

```sql
WITH CTE AS 
(
    SELECT *, 
           IIF(LAG(end_day) OVER(PARTITION BY hall_id ORDER BY start_day, end_day) >= start_day, 0, 1) AS overlap
    FROM HallEvents
), 

T AS 
(
    SELECT *, 
           SUM(overlap) OVER(PARTITION BY hall_id ORDER BY start_day, end_day) AS indicator
    FROM CTE
)

SELECT hall_id, 
       MIN(start_day) AS start_day, 
       MAX(end_day) AS end_day 
FROM T
GROUP BY hall_id, indicator
ORDER BY hall_id, start_day, end_day;
```
|hall_id|start_day|end_day|
|---|---|---|
|1|2023-01-01|2023-01-02|
|1|2023-01-10|2023-01-20|
|1|2023-02-15|2023-02-25|
|2|2022-12-09|2022-12-23|
|2|2023-01-19|2023-01-28|
|3|2022-12-01|2023-02-07|
|4|2023-02-02|2023-02-10|
|4|2023-03-01|2023-03-02|




