# 1127. User Purchase Platform [LeetCode]

*Write an SQL query to find the total number of users and the total amount spent using mobile only, desktop only and both mobile and desktop together for each date.*

Each `user_id` can spend on either "mobile" or "desktop" (or both) on a given `spend_date`. We are specifically interested in distinguishing users who spent on one platform only (mobile or desktop) and those who spent on both platforms.

`Spending`: 

|user_id|spend_date|platform|amount|
|---|---|---|---|
|1|2019-07-01|mobile|100.00|
|1|2019-07-01|desktop|100.00|
|2|2019-07-01|mobile|100.00|
|2|2019-07-02|mobile|100.00|
|3|2019-07-01|desktop|100.00|
|3|2019-07-02|desktop|100.00|

`Output`: 

|spend_date|platform|total_amount|total_users|
|---|---|---|---|
|2019-07-01|both|200.00|1|
|2019-07-01|desktop|100.00|1|
|2019-07-01|mobile|100.00|1|
|2019-07-02|both|0.00|0|
|2019-07-02|desktop|100.00|1|
|2019-07-02|mobile|100.00|1|


## Solution
We will approach the problem in three comprehensive steps:

1. Generate a sequence of spend dates and three platforms: desktop, mobile, and both.
2. Find which users have used both platforms on the same day.
3. Join the two tables from step 1 and 2 to calculate results.

Let's explore each step in detail.


### Step 1: Generate a sequence of spend dates and three platforms: desktop, mobile, and both.
 
```sql
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
```
|spend_date|platform|
|---|---|
|2019-07-01|both|
|2019-07-01|desktop|
|2019-07-01|mobile|
|2019-07-02|both|
|2019-07-02|desktop|
|2019-07-02|mobile|


### Step 2: Find which users have used both platforms on the same day.

* We perform a `LEFT JOIN` between the `Spending` table and itself to capture users who used both platforms on the same day. This way we ensure that users who only used one platform have `NULL` in the `S2` columns. 
 
```sql
SELECT 
*
FROM 
    Spending S1
    -- Self join on oppostie platforms to catch users that used both platforms 
    LEFT JOIN Spending S2 
        ON S1.user_id = S2.user_id
        AND S1.spend_date = S2.spend_date
        AND S1.platform != S2.platform
```
|user_id|spend_date|platform|amount|user_id|spend_date|platform|amount|
|---|---|---|---|---|---|---|---|
|1|2019-07-01|mobile|100.00|1|2019-07-01|desktop|100.00|
|1|2019-07-01|desktop|100.00|1|2019-07-01|mobile|100.00|
|2|2019-07-01|mobile|100.00|NULL|NULL|NULL|NULL|
|2|2019-07-02|mobile|100.00|NULL|NULL|NULL|NULL|
|3|2019-07-01|desktop|100.00|NULL|NULL|NULL|NULL|
|3|2019-07-02|desktop|100.00|NULL|NULL|NULL|NULL|

### Step 3: Join the two tables from step 1 and 2 to calculate results.

* We perform a `RIGHT JOIN` between the above table and our `BASE` table. The conditions ensure that:

    * Users who spent on both platforms are counted when `BASE.platform = 'both'` and `S2.user_id IS NOT NULL`.
    * Users who spent on only one platform are counted when `S2.user_id IS NULL`.


```sql
SELECT 
*
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
```
|user_id|spend_date|platform|amount|user_id|spend_date|platform|amount|spend_date|platform|
|---|---|---|---|---|---|---|---|---|---|
|1|2019-07-01|mobile|100.00|1|2019-07-01|desktop|100.00|2019-07-01|both|
|1|2019-07-01|desktop|100.00|1|2019-07-01|mobile|100.00|2019-07-01|both|
|3|2019-07-01|desktop|100.00|NULL|NULL|NULL|NULL|2019-07-01|desktop|
|2|2019-07-01|mobile|100.00|NULL|NULL|NULL|NULL|2019-07-01|mobile|
|NULL|NULL|NULL|NULL|NULL|NULL|NULL|NULL|2019-07-02|both|
|3|2019-07-02|desktop|100.00|NULL|NULL|NULL|NULL|2019-07-02|desktop|
|2|2019-07-02|mobile|100.00|NULL|NULL|NULL|NULL|2019-07-02|mobile|
 * Finally we `group by` `spend_date` and `platform` to compute the total spending and unique user counts for each combination of platform and date. 

```sql
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
```
`FinalResult`:
|spend_date|platform|total_amount|total_users|
|---|---|---|---|
|2019-07-01|both|200.00|1|
|2019-07-01|desktop|100.00|1|
|2019-07-01|mobile|100.00|1|
|2019-07-02|both|0.00|0|
|2019-07-02|desktop|100.00|1|
|2019-07-02|mobile|100.00|1|

