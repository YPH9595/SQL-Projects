-- @AUTHER Jasmine Abtahi

-- Create the Drivers table
CREATE TABLE Drivers (
    driver_id INT PRIMARY KEY,
    join_date DATE
);

-- Insert data into the Drivers table
INSERT INTO Drivers (driver_id, join_date) VALUES
(10, '2019-12-10'),
(8, '2020-01-13'),
(5, '2020-02-16'),
(7, '2020-03-08'),
(4, '2020-05-17'),
(1, '2020-10-24'),
(6, '2021-01-05');

-- Create the Rides table
CREATE TABLE Rides (
    ride_id INT PRIMARY KEY,
    user_id INT,
    requested_at DATE
);

-- Insert data into the Rides table
INSERT INTO Rides (ride_id, user_id, requested_at) VALUES
(6, 75, '2019-12-09'),
(1, 54, '2020-02-09'),
(10, 63, '2020-03-04'),
(19, 39, '2020-04-06'),
(3, 41, '2020-06-03'),
(13, 52, '2020-06-22'),
(7, 69, '2020-07-16'),
(17, 70, '2020-08-25'),
(20, 81, '2020-11-02'),
(5, 57, '2020-11-09'),
(2, 42, '2020-12-09'),
(11, 68, '2021-01-11'),
(15, 32, '2021-01-17'),
(12, 11, '2021-01-19'),
(14, 18, '2021-01-27');

-- Create the AcceptedRides table
CREATE TABLE AcceptedRides (
    ride_id INT,
    driver_id INT,
    ride_distance INT,
    ride_duration INT,
    PRIMARY KEY (ride_id, driver_id),
    FOREIGN KEY (ride_id) REFERENCES Rides(ride_id),
    FOREIGN KEY (driver_id) REFERENCES Drivers(driver_id)
);

-- Insert data into the AcceptedRides table
INSERT INTO AcceptedRides (ride_id, driver_id, ride_distance, ride_duration) VALUES
(10, 10, 63, 38),
(13, 10, 73, 96),
(7, 8, 100, 28),
(17, 7, 119, 68),
(20, 1, 121, 92),
(5, 7, 42, 101),
(2, 4, 6, 38),
(11, 8, 37, 43),
(15, 8, 108, 82),
(12, 8, 38, 34),
(14, 1, 90, 74);

---------------------------------------------------------

-- Step 1: Generate a sequence of numbers from 1 to 12, representing the months of the year
WITH Months AS (
    SELECT 1 AS month
    UNION ALL 
    SELECT month + 1
    FROM Months 
    WHERE month < 12
),

-- Step 2: Calculate the cumulative total of drivers who joined by each month in 2020
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
),
-- Step 3: Calculate the number of active drivers (who accepted rides) for each month in 2020
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

-- Step 4: Combine the results to calculate the percentage of active drivers each month
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
