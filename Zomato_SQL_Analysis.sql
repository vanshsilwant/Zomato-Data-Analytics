-- ============================================================
-- ZOMATO TECHNOLOGIES — DATA ANALYST CASE STUDY
-- PHASE 2: SQL BUSINESS ANALYSIS

--
-- Dataset: zomato
-- Database: zomato_analysis
--
-- DATA ASSUMPTIONS
-- 1. Aggregate rating = 0 means Not Rated.
-- 2. Rating/vote averages use rated and voted rows:
--      Aggregate rating > 0 AND Votes > 0
-- 3. Cuisines can contain multiple cuisines in one row.
-- 4. Minimum-sample rules from the case study:
--      20+ restaurants for city analysis
--      50+ restaurants for best-rated cuisines
-- ============================================================


-- ============================================================
-- 0. INDEXING / PERFORMANCE OPTIMIZATION
-- ============================================================

-- Country + City: supports repeated country/city filtering.
CREATE INDEX IF NOT EXISTS idx_zomato_country_city
ON zomato ("Country", "City");

-- Partial index: only rated/voted rows used in rating analysis.
CREATE INDEX IF NOT EXISTS idx_zomato_rated_country_city
ON zomato ("Country", "City")
WHERE "Aggregate rating" > 0
  AND "Votes" > 0;

-- Supports most-voted restaurant analysis.
CREATE INDEX IF NOT EXISTS idx_zomato_votes
ON zomato ("Votes" DESC);

-- Partial index for rated/voted rows.
CREATE INDEX IF NOT EXISTS idx_zomato_rated
ON zomato ("Aggregate rating")
WHERE "Aggregate rating" > 0
  AND "Votes" > 0;

-- Supports filtering by price segment when needed.
CREATE INDEX IF NOT EXISTS idx_zomato_price_range
ON zomato ("Price range");

-- Supports filtering by delivery availability.
CREATE INDEX IF NOT EXISTS idx_zomato_online_delivery
ON zomato ("Has Online delivery");

-- Supports filtering by table-booking availability.
CREATE INDEX IF NOT EXISTS idx_zomato_table_booking
ON zomato ("Has Table booking");

-- Useful for restaurant-level identification and DISTINCT counts.
CREATE INDEX IF NOT EXISTS idx_zomato_restaurant_id
ON zomato ("Restaurant ID");




-- ============================================================
-- Q1. RESTAURANTS PER COUNTRY
-- Business question:
-- How many restaurants are present in each country?
-- ============================================================

SELECT
    "Country",
    COUNT(*) AS restaurant_count
FROM zomato
GROUP BY "Country"
ORDER BY restaurant_count DESC;


-- ============================================================
-- Q2. AVERAGE RATING AND VOTES PER CITY
-- Minimum 20 rated/voted restaurants per city.
-- Business question:
-- Which cities have enough rated restaurants to compare their
-- average rating and average popularity?
-- ============================================================

SELECT
    "Country",
    "City",
    COUNT(*) AS restaurant_count,
    ROUND(AVG("Aggregate rating")::numeric, 2) AS avg_rating,
    ROUND(AVG("Votes")::numeric, 2) AS avg_votes
FROM zomato
WHERE "Aggregate rating" > 0
  AND "Votes" > 0
GROUP BY "Country", "City"
HAVING COUNT(*) >= 20
ORDER BY avg_rating DESC;


-- ============================================================
-- Q3. NEVER-RATED RESTAURANTS BY COUNTRY
-- Business question:
-- How large is the never-rated problem in each country?
-- ============================================================

SELECT
    "Country",
    COUNT(*) AS total_restaurants,
    COUNT(*) FILTER (
        WHERE "Aggregate rating" = 0
    ) AS never_rated,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE "Aggregate rating" = 0
        ) / COUNT(*),
        2
    ) AS never_rated_percentage
FROM zomato
GROUP BY "Country"
ORDER BY never_rated_percentage DESC;


-- ============================================================
-- Q4A. ONLINE DELIVERY VS RATING
-- Business question:
-- Is there a difference in average rating between restaurants
-- with and without online delivery?
-- Note: association/difference, not causation.
-- ============================================================

SELECT
    "Has Online delivery",
    COUNT(*) AS restaurant_count,
    ROUND(AVG("Aggregate rating")::numeric, 2) AS avg_rating
FROM zomato
WHERE "Aggregate rating" > 0
  AND "Votes" > 0
GROUP BY "Has Online delivery"
ORDER BY avg_rating DESC;


-- ============================================================
-- Q4B. TABLE BOOKING VS RATING
-- Business question:
-- Is there a difference in average rating between restaurants
-- with and without table booking?
-- Note: association/difference, not causation.
-- ============================================================

SELECT
    "Has Table booking",
    COUNT(*) AS restaurant_count,
    ROUND(AVG("Aggregate rating")::numeric, 2) AS avg_rating
FROM zomato
WHERE "Aggregate rating" > 0
  AND "Votes" > 0
GROUP BY "Has Table booking"
ORDER BY avg_rating DESC;


-- ============================================================
-- Q5. PRICE RANGE VS RATING AND VOTES
-- Business question:
-- How does price segment relate to average rating and popularity?
-- ============================================================

SELECT
    "Price range",
    COUNT(*) AS restaurant_count,
    ROUND(AVG("Aggregate rating")::numeric, 2) AS avg_rating,
    ROUND(AVG("Votes")::numeric, 2) AS avg_votes
FROM zomato
WHERE "Aggregate rating" > 0
  AND "Votes" > 0
GROUP BY "Price range"
ORDER BY "Price range";


-- ============================================================
-- Q6. TOP 10 CUISINES BY RESTAURANT COUNT + RATING
-- Business question:
-- Which cuisines have the largest restaurant presence, and what
-- are their average ratings and total votes?
--
-- COUNT(DISTINCT Restaurant ID) is used because one restaurant
-- can list multiple cuisines. After UNNEST, the same restaurant
-- may appear more than once.
-- ============================================================

WITH cuisine_data AS (
    SELECT
        TRIM(cuisine) AS cuisine,
        "Restaurant ID",
        "Aggregate rating",
        "Votes"
    FROM zomato,
         UNNEST(STRING_TO_ARRAY("Cuisines", ',')) AS cuisine
    WHERE "Aggregate rating" > 0
      AND "Votes" > 0
)
SELECT
    cuisine,
    COUNT(DISTINCT "Restaurant ID") AS restaurant_count,
    ROUND(AVG("Aggregate rating")::numeric, 2) AS avg_rating,
    SUM("Votes") AS total_votes
FROM cuisine_data
GROUP BY cuisine
ORDER BY restaurant_count DESC
LIMIT 10;


-- ============================================================
-- Q7. BEST-RATED CUISINES
-- Minimum 50 rated/voted restaurants.
-- Business question:
-- Which cuisines have strong average ratings with a sufficiently
-- large restaurant sample?
-- ============================================================

WITH cuisine_data AS (
    SELECT
        TRIM(cuisine) AS cuisine,
        "Restaurant ID",
        "Aggregate rating",
        "Votes"
    FROM zomato,
         UNNEST(STRING_TO_ARRAY("Cuisines", ',')) AS cuisine
    WHERE "Aggregate rating" > 0
      AND "Votes" > 0
)
SELECT
    cuisine,
    COUNT(DISTINCT "Restaurant ID") AS restaurant_count,
    ROUND(AVG("Aggregate rating")::numeric, 2) AS avg_rating
FROM cuisine_data
GROUP BY cuisine
HAVING COUNT(DISTINCT "Restaurant ID") >= 50
ORDER BY avg_rating DESC
LIMIT 10;


-- ============================================================
-- Q8. TOP 3 CITIES PER COUNTRY BY AVERAGE RATING
-- Minimum 20 rated/voted restaurants per city.
-- Business question:
-- Which cities have the highest average ratings within each
-- country after applying a minimum sample-size rule?
-- ============================================================

WITH city_ratings AS (
    SELECT
        "Country",
        "City",
        COUNT(*) AS restaurant_count,
        AVG("Aggregate rating") AS avg_rating
    FROM zomato
    WHERE "Aggregate rating" > 0
      AND "Votes" > 0
    GROUP BY "Country", "City"
    HAVING COUNT(*) >= 20
),
ranked_cities AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY "Country"
            ORDER BY avg_rating DESC
        ) AS city_rank
    FROM city_ratings
)
SELECT
    "Country",
    "City",
    restaurant_count,
    ROUND(avg_rating::numeric, 2) AS avg_rating,
    city_rank
FROM ranked_cities
WHERE city_rank <= 3
ORDER BY "Country", city_rank;


-- ============================================================
-- Q9. TOP 10 MOST-VOTED RESTAURANTS
-- Business question:
-- Which restaurants have the highest number of votes, and what
-- city, cuisine, price range and rating do they have?
-- ============================================================

SELECT
    "Restaurant ID",
    "Restaurant Name",
    "Country",
    "City",
    "Cuisines",
    "Price range",
    "Aggregate rating",
    "Votes"
FROM zomato
WHERE "Votes" > 0
ORDER BY "Votes" DESC
LIMIT 10;


-- ============================================================
-- Q10. OVERALL RATING-HEALTH DISTRIBUTION
-- Business question:
-- What percentage of the restaurant catalog is Not Rated, Poor,
-- Average, Good or Very Good?
-- ============================================================

WITH rating_buckets AS (
    SELECT
        CASE
            WHEN "Aggregate rating" = 0 THEN 'Not Rated'
            WHEN "Aggregate rating" < 2 THEN 'Poor'
            WHEN "Aggregate rating" < 3 THEN 'Average'
            WHEN "Aggregate rating" < 4 THEN 'Good'
            ELSE 'Very Good'
        END AS rating_bucket
    FROM zomato
)
SELECT
    rating_bucket,
    COUNT(*) AS restaurant_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM rating_buckets
GROUP BY rating_bucket
ORDER BY
    CASE rating_bucket
        WHEN 'Not Rated' THEN 1
        WHEN 'Poor' THEN 2
        WHEN 'Average' THEN 3
        WHEN 'Good' THEN 4
        WHEN 'Very Good' THEN 5
    END;


-- ============================================================
-- Q11. INDIA CITY-LEVEL BREAKDOWN
-- Business question:
-- How do Indian cities differ in restaurant count, average
-- rating, average votes, delivery coverage and booking coverage?
-- ============================================================

SELECT
    "City",
    COUNT(*) AS restaurant_count,
    ROUND(
        AVG("Aggregate rating") FILTER (
            WHERE "Aggregate rating" > 0
              AND "Votes" > 0
        )::numeric,
        2
    ) AS avg_rating,
    ROUND(
        AVG("Votes") FILTER (
            WHERE "Aggregate rating" > 0
              AND "Votes" > 0
        )::numeric,
        2
    ) AS avg_votes,
    ROUND(
        100.0 * AVG(
            CASE
                WHEN "Has Online delivery" = 'Yes' THEN 1
                ELSE 0
            END
        ),
        2
    ) AS delivery_percentage,
    ROUND(
        100.0 * AVG(
            CASE
                WHEN "Has Table booking" = 'Yes' THEN 1
                ELSE 0
            END
        ),
        2
    ) AS booking_percentage
FROM zomato
WHERE "Country" = 'India'
GROUP BY "City"
ORDER BY restaurant_count DESC;


-- ============================================================
-- Q12. INDEX PERFORMANCE CHECK
-- Business question:
-- Is PostgreSQL using an index or another execution strategy?
-- ============================================================

EXPLAIN ANALYZE
SELECT
    "Restaurant ID",
    "Restaurant Name",
    "Country",
    "City",
    "Votes"
FROM zomato
WHERE "Country" = 'India'
ORDER BY "Votes" DESC
LIMIT 10;


