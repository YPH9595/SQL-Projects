--@Auther Jasmine Abtahi

-- Create the HallEvents table to store event details including hall_id, start_day, and end_day
CREATE TABLE HallEvents (
    hall_id INT,
    start_day DATE,
    end_day DATE
);

-- Insert sample data into the HallEvents table
INSERT INTO HallEvents (hall_id, start_day, end_day) VALUES
(1, '2023-01-13', '2023-01-14'),
(1, '2023-01-14', '2023-01-17'),
(1, '2023-02-18', '2023-02-25'),
(1, '2023-01-10', '2023-01-20'),
(1, '2023-02-15', '2023-02-25'),
(1, '2023-02-18', '2023-02-22'),
(1, '2023-01-01', '2023-01-02'),
(2, '2022-12-09', '2022-12-23'),
(2, '2022-12-13', '2022-12-17'),
(2, '2023-01-22', '2023-01-28'),
(2, '2023-01-19', '2023-01-23'),
(3, '2022-12-01', '2023-01-30'),
(3, '2023-01-21', '2023-01-29'),
(3, '2023-01-25', '2023-02-05'),
(3, '2023-02-01', '2023-02-07'),
(4, '2023-02-02', '2023-02-06'),
(4, '2023-02-05', '2023-02-10'),
(4, '2023-03-01', '2023-03-02');

-- Display all events ordered by hall_id, start_day, and end_day
SELECT * 
FROM HallEvents
ORDER BY hall_id, start_day, end_day;

-- Use Common Table Expressions (CTE) to identify and merge overlapping events within the same hall

WITH CTE AS 
(
    -- Compare to find the overlap based on the previous event's end_day
    SELECT *, 
           IIF(LAG(end_day) OVER(PARTITION BY hall_id ORDER BY start_day, end_day) >= start_day, 0, 1) AS overlap
    FROM HallEvents
), 

T AS 
(
    -- Calculate the indicator to prepare for merging
    SELECT *, 
           SUM(overlap) OVER(PARTITION BY hall_id ORDER BY start_day, end_day) AS indicator
    FROM CTE
)

-- Final query to merge overlapping events by grouping them and selecting the minimum start_day and maximum end_day for each group
SELECT hall_id, 
       MIN(start_day) AS start_day, 
       MAX(end_day) AS end_day 
FROM T
GROUP BY hall_id, indicator
ORDER BY hall_id, start_day, end_day;
