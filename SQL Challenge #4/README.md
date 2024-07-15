# Maximize Prime Item Inventory [Amazon SQL Interview Question]

Amazon wants to maximize the storage capacity of its 500,000 square-foot warehouse by prioritizing a specific batch of prime items. The specific prime product batch detailed in the inventory table must be maintained.

So, if the prime product batch specified in the `item_category` column included 1 laptop and 1 side table, that would be the base batch. We could not add another laptop without also adding a side table; they come all together as a batch set.

After prioritizing the maximum number of prime batches, any remaining square footage will be utilized to stock non-prime batches, which also come in batch sets and cannot be separated into individual items.

Write a query to find the maximum number of prime and non-prime batches that can be stored in the 500,000 square feet warehouse based on the following criteria:

 * Prioritize stocking prime batches 
 * After accommodating prime items, allocate any remaining space to non-prime batches

Output the `item_type` with `prime_eligible` first followed by `not_prime`, along with the maximum number of batches that can be stocked.

Assumptions:

* Again, products must be stocked in batches, so we want to find the largest available quantity of prime batches, and then the largest available quantity of non-prime batches
* Non-prime items must always be available in stock to meet customer demand, so the non-prime item count should never be zero.
* Item count should be whole numbers (integers).


### `inventory` Table

| Column Name     | Type     |
|-----------------|----------|
| item_id         | integer  |
| item_type       | string   |
| item_category   | string   |
| square_footage  | decimal  |

### `inventory` Example Input:

| item_id | item_type      | item_category    | square_footage |
|---------|----------------|------------------|----------------|
| 1374    | prime_eligible | mini refrigerator| 68.00          |
| 4245    | not_prime      | standing lamp    | 26.40          |
| 2452    | prime_eligible | television       | 85.00          |
| 3255    | not_prime      | side table       | 22.60          |
| 1672    | prime_eligible | laptop           | 8.50           |

### Example Output:

| item_type      | item_count |
|----------------|------------|
| prime_eligible | 9285       |
| not_prime      | 6          |


## Solution
Let's simplify the question: There are two types of items: prime and non-prime. All items of each type must go into the warehouse together as a batch. This means that if we have a laptop, a mouse, and a speaker in the prime group, all three prime items will be stored together as a batch. You cannot store one without the others.

Our task is to find out how many batches of prime and non-prime items we can store in the 500,000 square feet warehouse. We prioritize space for prime batches, and the remaining space will be used for non-prime batches. 

First, let's see how many items we have in each type and the total size of all items in each type group.

```sql
    SELECT 
        item_type, 
        COUNT(*) AS item_count, 
        SUM(square_footage) AS batch_size
    FROM 
        inventory
    GROUP BY 
        item_type
```
|item_type|item_count|batch_size|
|---|---|---|
|not_prime|2|49.00|
|prime_eligible|3|161.50|

Okay, so now let's see how many prime batches of size 161.50 we can place in the 500,000 sq ft warehouse.

```sql
WITH CTE AS (
    SELECT 
        item_type, 
        COUNT(*) AS item_count, 
        SUM(square_footage) AS batch_size
    FROM 
        inventory
    GROUP BY 
        item_type
)

SELECT 
    FLOOR(500000 / CTE.batch_size) AS batch_count 
FROM 
    CTE
WHERE 
    item_type = 'prime_eligible';

```
|batch_count|
|---|
|3095|

3095 batches multiplied by 3 items per batch equals 9285 total prime items.

Logically, we should subtract (3095 batches multiplied by 161.50 sq ft per batch) from 500,000 sq ft to get the remaining space.

```sql
WITH CTE AS (
    SELECT 
        item_type, 
        COUNT(*) AS item_count, 
        SUM(square_footage) AS batch_size
    FROM 
        inventory
    GROUP BY 
        item_type
)
SELECT 
    500000 - FLOOR(500000 / batch_size) * batch_size AS remaining
FROM 
    CTE 
WHERE 
    item_type = 'prime_eligible';
```
|remaining|
|---|
|157.50|

Now we should calculate how many non-prime batches of size 49.00 can be placed within a space of 157.50 sq ft.

To achieve this, we need to use a `CASE` statement in our query to specify the calculation for the prime and non-prime type groups. Since we are performing both calculations simultaneously, and the non-prime calculation depends on the result of the prime calculation, we use a subquery to hold the `prime_batch_size` at the same time.

Let's put it altogether:
```sql
WITH CTE AS (
    SELECT 
        item_type, 
        COUNT(*) AS item_count, 
        SUM(square_footage) AS batch_size
    FROM 
        inventory
    GROUP BY 
        item_type
)

SELECT 
    CTE.item_type, 
    CASE 
        WHEN CTE.item_type = 'prime_eligible' THEN 
            FLOOR(500000 / CTE.batch_size) * CTE.item_count
        ELSE 
            FLOOR((500000 - FLOOR(500000 / PBS.prime_batch_size) * PBS.prime_batch_size) / CTE.batch_size) * CTE.item_count
    END AS item_count
FROM 
    CTE
CROSS JOIN 
    (
        SELECT 
            batch_size AS prime_batch_size
        FROM 
            CTE
        WHERE 
            item_type = 'prime_eligible'
    ) PBS --Prime Batch Size
ORDER BY
    CTE.item_type DESC;
```

### Result
|item_type|item_count|
|---|---|
|prime_eligible|9285|
|not_prime|6|

## Acknowledgments

Question was posted on DataLemur website: https://datalemur.com/questions/prime-warehouse-storage



