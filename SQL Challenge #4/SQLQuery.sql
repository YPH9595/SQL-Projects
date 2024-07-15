--@AUTHOR Jasmine Abtahi

-- Create the inventory table
CREATE TABLE inventory (
    item_id INTEGER,
    item_type VARCHAR(255),
    item_category VARCHAR(255),
    square_footage DECIMAL(10, 2)
);

-- Insert example input data into the inventory table
INSERT INTO inventory (item_id, item_type, item_category, square_footage) VALUES
(1374, 'prime_eligible', 'mini refrigerator', 68.00),
(4245, 'not_prime', 'standing lamp', 26.40),
(2452, 'prime_eligible', 'television', 85.00),
(3255, 'not_prime', 'side table', 22.60),
(1672, 'prime_eligible', 'laptop', 8.50);

SELECT * 
FROM inventory;

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

