
# Solving a Complex SQL Challenge on HackerRank: “15 Days of Learning SQL”

*Julia conducted a 15 days of learning SQL contest. The start date of the contest was March 01, 2016 and the end date was March 15, 2016. Write a query to print total number of unique hackers who made at least 1 submission each day (starting on the first day of the contest), and find the `hacker_id` and `name` of the hacker who made maximum number of submissions each day. If more than one such hacker has a maximum number of submissions, print the lowest `hacker_id`. The query should print this information for each day of the contest, sorted by the date.*

### *`Hackers` Table:*
| hacker_id | name     |
|-----------|----------|
| 15758     | Rose     |
| 20703     | Angela   |
| 36396     | Frank    |
| 38289     | Patrick  |
| 44065     | Lisa     |
| 53473     | Kimberly |
| 62529     | Bonnie   |
| 79722     | Michael  |


### *`Submissions` Table:*
| submission_date | submission_id | hacker_id | score |
|-----------------|---------------|-----------|-------|
| 2016-03-01      | 8494          | 20703     | 0     |
| 2016-03-01      | 22403         | 53473     | 15    |
| 2016-03-01      | 23965         | 79722     | 60    |
| 2016-03-01      | 30173         | 36396     | 70    |
| 2016-03-02      | 34928         | 20703     | 0     |
| 2016-03-02      | 38740         | 15758     | 60    |
| 2016-03-02      | 42769         | 79722     | 25    |
| 2016-03-02      | 44364         | 79722     | 60    |
| 2016-03-03      | 45440         | 20703     | 0     |
| 2016-03-03      | 49050         | 36396     | 70    |
| 2016-03-03      | 50273         | 79722     | 5     |
| 2016-03-04      | 50344         | 20703     | 0     |
| 2016-03-04      | 51360         | 44065     | 90    |
| 2016-03-04      | 54404         | 53473     | 65    |
| 2016-03-04      | 61533         | 79722     | 45    |
| 2016-03-05      | 72852         | 20703     | 0     |
| 2016-03-05      | 74546         | 38289     | 0     |
| 2016-03-05      | 76487         | 62529     | 0     |
| 2016-03-05      | 82439         | 36396     | 10    |
| 2016-03-06      | 90006         | 36396     | 40    |
| 2016-03-06      | 90404         | 20703     | 0    |


### *Sample Output:*

```
2016-03-01 4 20703 Angela
2016-03-02 2 79722 Michael
2016-03-03 2 20703 Angela
2016-03-04 2 20703 Angela
2016-03-05 1 36396 Frank
2016-03-06 1 20703 Angela
```

## Solution


### Part 1: Finding the Total Number of Unique Hackers Who Made At Least One Submission Each Day

To solve this part, we need to create a list of all hackers who made at least one submission every day from the start of the contest and then count the number of unique hackers for each date in this list. Here’s how we can approach it:

#### Step 1: Identify the First Submission Date

```sql
(
    SELECT TOP 1 submission_date
    FROM Submissions
    GROUP BY submission_date
    ORDER BY submission_date
) TOP_ONE
```
|submission_date|
|---|
|2016-03-01|

#### Step 2: Fetch All the Entries That Match the First Submission Date

Here we create a base for our `CTE` (common table expression). We will keep adding rows to this `CTE` in step 3.

```sql
WITH CTE AS (
    -- BASE: made of the first date entries in Submission table 
    SELECT S.submission_date, hacker_id 
    FROM Submissions S, (
        SELECT TOP 1 submission_date 
        FROM Submissions
        GROUP BY submission_date
        ORDER BY submission_date
    ) TOP_ONE -- the first date  
    WHERE S.submission_date = TOP_ONE.submission_date
```
|submission_date|hacker_id|
|---|---|
|2016-03-01|20703|
|2016-03-01|53473|
|2016-03-01|79722|
|2016-03-01|36396|

#### Step 3: Create a Sequence of Dates and Hackers Present Since Day 1

To extend our `CTE` base and include hackers who have made submissions every day since day 1, we need to check if the `hacker_id` from the next day exists in the current day. Essentially, we join the `CTE` base table with the `Submissions` table on this condition. The `DATEADD(DAY, +1, CTE.submission_date)` function will increment the date by one day repeatedly until no more matching records are found.

```sql
    UNION ALL 
    
    -- Recursive part of the CTE
    SELECT S.submission_date, S.hacker_id 
    FROM CTE
    JOIN Submissions S 
        ON DATEADD(DAY, +1, CTE.submission_date) = S.submission_date 
        AND CTE.hacker_id = S.hacker_id
),
```
|submission_date|hacker_id|
|---|---|
|2016-03-01|20703|
|2016-03-01|53473|
|2016-03-01|79722|
|2016-03-01|36396|
|2016-03-02|79722|
|2016-03-02|79722|
|2016-03-03|79722|
|2016-03-04|79722|
|2016-03-03|79722|
|2016-03-04|79722|
|2016-03-02|20703|
|2016-03-03|20703|
|2016-03-04|20703|
|2016-03-05|20703|
|2016-03-06|20703|

#### Step 4: Count Unique Hackers for Each Day

Now that we have our list, we group the results by `submission_date` and count the `distinct hacker_ids` for each date:

```sql
UNIQUE_HACKERS_PER_DAY AS (
    SELECT submission_date, COUNT(DISTINCT hacker_id) AS unique_hackers_count
    FROM CTE
    GROUP BY submission_date
)
```
|submission_date|unique_hackers_count|
|---|---|
|2016-03-01|4|
|2016-03-02|2|
|2016-03-03|2|
|2016-03-04|2|
|2016-03-05|1|
|2016-03-06|1|

### Part 2: Finding the Hacker with the Maximum Number of Submissions Each Day

In this part, we aim to identify the hacker with the highest number of submissions for each day. We will rank the hackers based on their number of submissions for each day and then fetch the top-ranked hacker for each day.

#### Step 1: Rank Hackers by Number of Submissions

First, we group the `Submissions` table by `submission_date` and `hacker_id`. Counting the rows in each group will give us the number of submissions each hacker made on each day. We then order these groups in descending order based on the count of submissions (and based on `hacker_id`s in case count number is the same for more than one hacker), and assign a row number to maintain this order of ranks.

```sql
MAX_SUBMISSIONS AS (
    SELECT ROW_NUMBER() OVER (ORDER BY submission_date, COUNT(*) DESC, hacker_id) AS RN,
           submission_date, hacker_id
    FROM Submissions
    GROUP BY submission_date, hacker_id
),
```
|RN|submission_date|hacker_id|
|---|---|---|
|1|2016-03-01|20703|
|2|2016-03-01|36396|
|3|2016-03-01|53473|
|4|2016-03-01|79722|
|5|2016-03-02|79722|
|6|2016-03-02|15758|
|7|2016-03-02|20703|
|8|2016-03-03|20703|
|9|2016-03-03|36396|
|10|2016-03-03|79722|
|11|2016-03-04|20703|
|12|2016-03-04|44065|
|13|2016-03-04|53473|
|14|2016-03-04|79722|
|15|2016-03-05|36396|
|16|2016-03-05|20703|
|17|2016-03-05|38289|
|18|2016-03-05|62529|
|19|2016-03-06|20703|
#### Step 2: Identify the Row Numbers of Top-Ranked Hackers for Each Date

To find the top-ranked hacker for each date, we group the table from the last step by `submission_date` and select the minimum row number (`RN`) within each group. This will give us the row number corresponding to the hacker with the highest number of submissions for each date.

```sql
(
    SELECT MIN(RN) AS min_rn
    FROM MAX_SUBMISSIONS
    GROUP BY submission_date
) MAX_ENTRY
```
|min_rn|
|---|
|1|
|5|
|8|
|11|
|15|
|19|

#### Step 3: Identify the Hacker with the Highest Number of Submissions

To find the top `hacker_id`, we need to join the results from the previous step with the `MAX_SUBMISSIONS` table on the matching row number. This will give us the hacker who has the highest number of submissions for each date.

```sql
MAX_SUBS_PER_DAY AS (
    SELECT submission_date, hacker_id
    FROM (
        SELECT MIN(RN) AS min_rn
        FROM MAX_SUBMISSIONS
        GROUP BY submission_date
    ) MAX_ENTRY 
    JOIN MAX_SUBMISSIONS MS ON MAX_ENTRY.min_rn = MS.RN
)
```
|submission_date|hacker_id|
|---|---|
|2016-03-01|20703|
|2016-03-02|79722|
|2016-03-03|20703|
|2016-03-04|20703|
|2016-03-05|36396|
|2016-03-06|20703|

### Part 3: Joining the Results

The problem requires the name of the hacker as well. To achieve this, we join our three tables to create the final result:

```sql
SELECT UQ.submission_date, unique_hackers_count, Hackers.hacker_id, Hackers.name
FROM UNIQUE_HACKERS_PER_DAY UQ
JOIN MAX_SUBS_PER_DAY MX ON UQ.submission_date = MX.submission_date
JOIN Hackers ON MX.hacker_id = Hackers.hacker_id;
```

## Result
|submission_date|unique_hackers_count|hacker_id|name|
|---|---|---|---|
|2016-03-01|4|20703|Angela|
|2016-03-02|2|79722|Michael|
|2016-03-03|2|20703|Angela|
|2016-03-04|2|20703|Angela|
|2016-03-05|1|36396|Frank|
|2016-03-06|1|20703|Angela|


