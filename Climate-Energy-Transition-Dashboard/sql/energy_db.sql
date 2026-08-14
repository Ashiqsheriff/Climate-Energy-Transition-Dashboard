SELECT * FROM climate_energy;

SELECT COUNT(*)
FROM climate_energy;

SELECT *
FROM climate_energy
LIMIT 10;

SELECT
    MIN(year) AS first_year,
    MAX(year) AS last_year
FROM climate_energy;

SELECT
    country,
    year,
    renewables_share_energy
FROM climate_energy
WHERE renewables_share_energy IS NOT NULL
ORDER BY renewables_share_energy DESC
LIMIT 10;


SELECT
    country,
    year,
    renewables_share_energy
FROM climate_energy
WHERE renewables_share_energy IS NOT NULL
  AND year = (
      SELECT MAX(year)
      FROM climate_energy
      WHERE renewables_share_energy IS NOT NULL
  )
ORDER BY renewables_share_energy DESC
LIMIT 10;

SELECT
    year,
    ROUND(
        AVG(renewables_share_energy)::numeric,
        2
    ) AS avg_renewable_share
FROM climate_energy
WHERE renewables_share_energy IS NOT NULL
GROUP BY year
ORDER BY year;

SELECT
    country,
    year,
    carbon_intensity_elec
FROM climate_energy
WHERE carbon_intensity_elec IS NOT NULL
  AND year = (
      SELECT MAX(year)
      FROM climate_energy
      WHERE carbon_intensity_elec IS NOT NULL
  )
ORDER BY carbon_intensity_elec
LIMIT 10;


WITH renewable_data AS (
    SELECT
        country,
        year,
        renewables_share_energy
    FROM climate_energy
    WHERE renewables_share_energy IS NOT NULL
)
SELECT *
FROM renewable_data
LIMIT 10;


WITH renewable_data AS (
    SELECT
        country,
        year,
        renewables_share_energy
    FROM climate_energy
    WHERE renewables_share_energy IS NOT NULL
),
country_start AS (
    SELECT DISTINCT ON (country)
        country,
        year AS start_year,
        renewables_share_energy AS start_share
    FROM renewable_data
    ORDER BY country, year
)
SELECT *
FROM country_start
ORDER BY start_share DESC
LIMIT 10;

WITH renewable_data AS (
    SELECT
        country,
        year,
        renewables_share_energy
    FROM climate_energy
    WHERE renewables_share_energy IS NOT NULL
),
country_latest AS (
    SELECT DISTINCT ON (country)
        country,
        year AS end_year,
        renewables_share_energy AS end_share
    FROM renewable_data
    ORDER BY country, year DESC
)
SELECT *
FROM country_latest
ORDER BY end_share DESC
LIMIT 10;

WITH renewable_data AS (
    SELECT
        country,
        year,
        renewables_share_energy
    FROM climate_energy
    WHERE renewables_share_energy IS NOT NULL
),

country_start AS (
    SELECT DISTINCT ON (country)
        country,
        year AS start_year,
        renewables_share_energy AS start_share
    FROM renewable_data
    ORDER BY country, year
),

country_latest AS (
    SELECT DISTINCT ON (country)
        country,
        year AS end_year,
        renewables_share_energy AS end_share
    FROM renewable_data
    ORDER BY country, year DESC
)

SELECT
    s.country,
    s.start_year,
    ROUND(s.start_share::numeric, 2) AS start_share,
    l.end_year,
    ROUND(l.end_share::numeric, 2) AS end_share,

    ROUND(
        (l.end_share - s.start_share)::numeric,
        2
    ) AS renewable_improvement_pp

FROM country_start s

JOIN country_latest l
    ON s.country = l.country

WHERE l.end_share IS NOT NULL

ORDER BY renewable_improvement_pp DESC

LIMIT 10;

SELECT
    country,
    year,
    renewables_share_energy,

    LAG(renewables_share_energy)
        OVER (
            PARTITION BY country
            ORDER BY year
        ) AS previous_year_share

FROM climate_energy

WHERE renewables_share_energy IS NOT NULL

ORDER BY country, year;


WITH renewable_yoy AS (
    SELECT
        country,
        year,
        renewables_share_energy,

        LAG(renewables_share_energy)
            OVER (
                PARTITION BY country
                ORDER BY year
            ) AS previous_year_share

    FROM climate_energy

    WHERE renewables_share_energy IS NOT NULL
)

SELECT
    country,
    year,

    ROUND(
        renewables_share_energy::numeric,
        2
    ) AS renewable_share,

    ROUND(
        previous_year_share::numeric,
        2
    ) AS previous_year_share,

    ROUND(
        (renewables_share_energy - previous_year_share)::numeric,
        2
    ) AS yoy_change

FROM renewable_yoy

WHERE previous_year_share IS NOT NULL

ORDER BY yoy_change DESC

LIMIT 10;


WITH renewable_yoy AS (
    SELECT
        country,
        year,
        renewables_share_energy,

        LAG(renewables_share_energy)
            OVER (
                PARTITION BY country
                ORDER BY year
            ) AS previous_year_share

    FROM climate_energy

    WHERE renewables_share_energy IS NOT NULL
)

SELECT
    country,
    year,

    ROUND(
        renewables_share_energy::numeric,
        2
    ) AS renewable_share,

    ROUND(
        previous_year_share::numeric,
        2
    ) AS previous_year_share,

    ROUND(
        (renewables_share_energy - previous_year_share)::numeric,
        2
    ) AS yoy_change

FROM renewable_yoy

WHERE previous_year_share IS NOT NULL

ORDER BY yoy_change DESC

LIMIT 10;


SELECT
    CORR(
        renewables_share_energy,
        carbon_intensity_elec
    ) AS renewable_carbon_correlation

FROM climate_energy

WHERE renewables_share_energy IS NOT NULL
  AND carbon_intensity_elec IS NOT NULL;


SELECT
    country,
    year,

    ROUND(
        renewables_share_energy::numeric,
        2
    ) AS renewable_share,

    ROUND(
        carbon_intensity_elec::numeric,
        2
    ) AS carbon_intensity

FROM climate_energy

WHERE year = 2022
  AND renewables_share_energy IS NOT NULL
  AND carbon_intensity_elec IS NOT NULL

ORDER BY
    renewables_share_energy DESC,
    carbon_intensity_elec ASC

LIMIT 15;  

SELECT
    country,
    renewables_share_energy,
    carbon_intensity_elec,
    energy_per_gdp
FROM climate_energy
WHERE year = 2022
  AND renewables_share_energy IS NOT NULL
  AND carbon_intensity_elec IS NOT NULL
  AND energy_per_gdp IS NOT NULL;

WITH data_2022 AS (
    SELECT
        country,
        renewables_share_energy,
        carbon_intensity_elec,
        energy_per_gdp
    FROM climate_energy
    WHERE year = 2022
      AND renewables_share_energy IS NOT NULL
      AND carbon_intensity_elec IS NOT NULL
      AND energy_per_gdp IS NOT NULL
),

normalized AS (
    SELECT
        country,
        renewables_share_energy,
        carbon_intensity_elec,
        energy_per_gdp,

        (
            renewables_share_energy
            - MIN(renewables_share_energy) OVER ()
        )
        /
        NULLIF(
            MAX(renewables_share_energy) OVER ()
            - MIN(renewables_share_energy) OVER (),
            0
        ) AS renewable_score,

        1 - (
            (
                carbon_intensity_elec
                - MIN(carbon_intensity_elec) OVER ()
            )
            /
            NULLIF(
                MAX(carbon_intensity_elec) OVER ()
                - MIN(carbon_intensity_elec) OVER (),
                0
            )
        ) AS carbon_score,

        1 - (
            (
                energy_per_gdp
                - MIN(energy_per_gdp) OVER ()
            )
            /
            NULLIF(
                MAX(energy_per_gdp) OVER ()
                - MIN(energy_per_gdp) OVER (),
                0
            )
        ) AS efficiency_score

    FROM data_2022
)

SELECT *
FROM normalized
LIMIT 10;


WITH data_2022 AS (
    SELECT
        country,
        renewables_share_energy,
        carbon_intensity_elec,
        energy_per_gdp
    FROM climate_energy
    WHERE year = 2022
      AND renewables_share_energy IS NOT NULL
      AND carbon_intensity_elec IS NOT NULL
      AND energy_per_gdp IS NOT NULL
),

normalized AS (
    SELECT
        country,
        renewables_share_energy,
        carbon_intensity_elec,
        energy_per_gdp,

        (
            renewables_share_energy
            - MIN(renewables_share_energy) OVER ()
        )
        /
        NULLIF(
            MAX(renewables_share_energy) OVER ()
            - MIN(renewables_share_energy) OVER (),
            0
        ) AS renewable_score,

        1 - (
            (
                carbon_intensity_elec
                - MIN(carbon_intensity_elec) OVER ()
            )
            /
            NULLIF(
                MAX(carbon_intensity_elec) OVER ()
                - MIN(carbon_intensity_elec) OVER (),
                0
            )
        ) AS carbon_score,

        1 - (
            (
                energy_per_gdp
                - MIN(energy_per_gdp) OVER ()
            )
            /
            NULLIF(
                MAX(energy_per_gdp) OVER ()
                - MIN(energy_per_gdp) OVER (),
                0
            )
        ) AS efficiency_score

    FROM data_2022
),

final_score AS (
    SELECT
        country,
        renewables_share_energy,
        carbon_intensity_elec,
        energy_per_gdp,

        renewable_score,
        carbon_score,
        efficiency_score,

        (
            renewable_score * 0.40
            + carbon_score * 0.40
            + efficiency_score * 0.20
        ) * 100 AS transition_score

    FROM normalized
)

SELECT
    country,
    ROUND(renewables_share_energy::numeric, 2)
        AS renewable_share,

    ROUND(carbon_intensity_elec::numeric, 2)
        AS carbon_intensity,

    ROUND(energy_per_gdp::numeric, 2)
        AS energy_per_gdp,

    ROUND(transition_score::numeric, 2)
        AS transition_score

FROM final_score

ORDER BY transition_score DESC

LIMIT 10;



WITH data_2022 AS (
    SELECT
        country,
        renewables_share_energy,
        carbon_intensity_elec,
        energy_per_gdp
    FROM climate_energy
    WHERE year = 2022
      AND renewables_share_energy IS NOT NULL
      AND carbon_intensity_elec IS NOT NULL
      AND energy_per_gdp IS NOT NULL
),

normalized AS (
    SELECT
        country,
        renewables_share_energy,
        carbon_intensity_elec,
        energy_per_gdp,

        (
            renewables_share_energy
            - MIN(renewables_share_energy) OVER ()
        )
        /
        NULLIF(
            MAX(renewables_share_energy) OVER ()
            - MIN(renewables_share_energy) OVER (),
            0
        ) AS renewable_score,

        1 - (
            (
                carbon_intensity_elec
                - MIN(carbon_intensity_elec) OVER ()
            )
            /
            NULLIF(
                MAX(carbon_intensity_elec) OVER ()
                - MIN(carbon_intensity_elec) OVER (),
                0
            )
        ) AS carbon_score,

        1 - (
            (
                energy_per_gdp
                - MIN(energy_per_gdp) OVER ()
            )
            /
            NULLIF(
                MAX(energy_per_gdp) OVER ()
                - MIN(energy_per_gdp) OVER (),
                0
            )
        ) AS efficiency_score

    FROM data_2022
),

final_score AS (
    SELECT
        country,
        renewables_share_energy,
        carbon_intensity_elec,
        energy_per_gdp,

        (
            renewable_score * 0.40
            + carbon_score * 0.40
            + efficiency_score * 0.20
        ) * 100 AS transition_score

    FROM normalized
)

SELECT
    RANK() OVER (
        ORDER BY transition_score DESC
    ) AS country_rank,

    country,

    ROUND(
        transition_score::numeric,
        2
    ) AS transition_score

FROM final_score

ORDER BY country_rank;


WITH data_2022 AS (
    SELECT
        country,
        renewables_share_energy,
        carbon_intensity_elec,
        energy_per_gdp
    FROM climate_energy
    WHERE year = 2022
      AND renewables_share_energy IS NOT NULL
      AND carbon_intensity_elec IS NOT NULL
      AND energy_per_gdp IS NOT NULL
),

normalized AS (
    SELECT
        country,
        renewables_share_energy,
        carbon_intensity_elec,
        energy_per_gdp,

        (
            renewables_share_energy
            - MIN(renewables_share_energy) OVER ()
        )
        /
        NULLIF(
            MAX(renewables_share_energy) OVER ()
            - MIN(renewables_share_energy) OVER (),
            0
        ) AS renewable_score,

        1 - (
            carbon_intensity_elec
            - MIN(carbon_intensity_elec) OVER ()
        )
        /
        NULLIF(
            MAX(carbon_intensity_elec) OVER ()
            - MIN(carbon_intensity_elec) OVER (),
            0
        ) AS carbon_score,

        1 - (
            energy_per_gdp
            - MIN(energy_per_gdp) OVER ()
        )
        /
        NULLIF(
            MAX(energy_per_gdp) OVER ()
            - MIN(energy_per_gdp) OVER (),
            0
        ) AS efficiency_score

    FROM data_2022
),

final_score AS (
    SELECT
        *,
        (
            renewable_score * 0.40
            + carbon_score * 0.40
            + efficiency_score * 0.20
        ) * 100 AS transition_score

    FROM normalized
)

SELECT
    RANK() OVER (
        ORDER BY transition_score DESC
    ) AS country_rank,

    country,

    ROUND(
        transition_score::numeric,
        2
    ) AS transition_score,

    CASE
        WHEN transition_score >= 70
            THEN 'Transition Leader'

        WHEN transition_score >= 40
            THEN 'Transitioning'

        ELSE 'High Priority'
    END AS transition_category

FROM final_score

ORDER BY country_rank;


WITH data_2022 AS (
    SELECT
        country,
        renewables_share_energy,
        carbon_intensity_elec,
        energy_per_gdp
    FROM climate_energy
    WHERE year = 2022
      AND renewables_share_energy IS NOT NULL
      AND carbon_intensity_elec IS NOT NULL
      AND energy_per_gdp IS NOT NULL
),

normalized AS (
    SELECT
        country,
        renewables_share_energy,
        carbon_intensity_elec,
        energy_per_gdp,

        -- Renewable score: Higher renewable share = better
        (
            renewables_share_energy
            - MIN(renewables_share_energy) OVER ()
        )
        /
        NULLIF(
            MAX(renewables_share_energy) OVER ()
            - MIN(renewables_share_energy) OVER (),
            0
        ) AS renewable_score,

        -- Carbon score: Lower carbon intensity = better
        1 - (
            (
                carbon_intensity_elec
                - MIN(carbon_intensity_elec) OVER ()
            )
            /
            NULLIF(
                MAX(carbon_intensity_elec) OVER ()
                - MIN(carbon_intensity_elec) OVER (),
                0
            )
        ) AS carbon_score,

        -- Efficiency score: Lower energy/GDP = better
        1 - (
            (
                energy_per_gdp
                - MIN(energy_per_gdp) OVER ()
            )
            /
            NULLIF(
                MAX(energy_per_gdp) OVER ()
                - MIN(energy_per_gdp) OVER (),
                0
            )
        ) AS efficiency_score

    FROM data_2022
),

final_score AS (
    SELECT
        country,

        renewables_share_energy,
        carbon_intensity_elec,
        energy_per_gdp,

        renewable_score,
        carbon_score,
        efficiency_score,

        -- Climate Transition Score
        (
            renewable_score * 0.40
            + carbon_score * 0.40
            + efficiency_score * 0.20
        ) * 100 AS transition_score

    FROM normalized
),

scored_countries AS (
    SELECT
        country,

        transition_score,

        CASE
            WHEN transition_score >= 70
                THEN 'Transition Leader'

            WHEN transition_score >= 40
                THEN 'Transitioning'

            ELSE 'High Priority'
        END AS transition_category

    FROM final_score
)

SELECT
    transition_category,
    COUNT(*) AS country_count
FROM scored_countries
GROUP BY transition_category
ORDER BY country_count DESC;