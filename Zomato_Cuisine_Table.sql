CREATE TABLE public.restaurant_cuisines AS
SELECT
    "Restaurant ID",
    TRIM(cuisine) AS cuisine
FROM public.zomato,
     UNNEST(STRING_TO_ARRAY("Cuisines", ',')) AS cuisine;