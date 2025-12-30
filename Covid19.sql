Select *
From coviddeaths
Where continent is not null 
order by continent

SET SQL_SAFE_UPDATES = 0;

UPDATE coviddeaths
SET `date` = STR_TO_DATE(`date`, '%m/%d/%y');

ALTER TABLE coviddeaths
MODIFY COLUMN `date` DATE;

SET SQL_SAFE_UPDATES = 1;



-- Step 1: Disable safe updates temporarily
SET SQL_SAFE_UPDATES = 0;

-- Step 2: Convert the text dates to proper date format
UPDATE covidvaccinations
SET `date` = STR_TO_DATE(`date`, '%m/%d/%y');

-- Step 3: Change the column type from TEXT to DATE
ALTER TABLE covidvaccinations
MODIFY COLUMN `date` DATE;
ALTER TABLE coviddeathnew
MODIFY COLUMN total_deaths INT;

-- Step 4: Re-enable safe updates
SET SQL_SAFE_UPDATES = 1;

-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From coviddeaths
Where continent is not null 
order by 1,2 

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT 
    location, 
    `date`, 
    total_cases, 
    total_deaths,
    (CAST(total_deaths AS DECIMAL(20,4)) / NULLIF(CAST(total_cases AS DECIMAL(20,4)), 0)) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%states%'
  AND continent IS NOT NULL
ORDER BY location, `date`;


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT 
    location, 
    `date`, 
    population, 
    total_cases,
    (CAST(total_cases AS DECIMAL(20,4)) / NULLIF(CAST(population AS DECIMAL(20,4)), 0)) * 100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE location LIKE '%states%'
ORDER BY location, `date`;

-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From coviddeaths
-- Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

-- Countries with Highest Death Count per Population

SELECT Location, MAX(CAST(Total_deaths AS SIGNED)) AS TotalDeathCount
FROM coviddeaths
-- WHERE location LIKE '%states%'
where continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount DESC;


-- Showing contintents with the highest death count per population

  -- BREAKING THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count

SELECT 
    continent,
    MAX(CAST(total_deaths AS SIGNED)) AS TotalDeathCount
FROM coviddeaths
-- WHERE location LIKE '%states%'
 WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- GLOBAL NUMBERS
SELECT 
    date,
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS SIGNED)) AS total_deaths,
    (SUM(CAST(new_deaths AS SIGNED)) / NULLIF(SUM(new_cases), 0)) * 100 AS DeathPercentage
FROM coviddeaths
-- WHERE location LIKE '%states%'
  WHERE continent IS NOT NULL
GROUP BY date
ORDER BY total_cases, total_deaths;

SELECT 
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS SIGNED)) AS total_deaths,
    (SUM(CAST(new_deaths AS SIGNED)) / NULLIF(SUM(new_cases), 0)) * 100 AS DeathPercentage
FROM coviddeaths
WHERE continent IS NOT NULL;

--- 

-- ============================================
-- STEP 1: MUST RUN THESE FIRST - Increase timeouts
-- ============================================
SET GLOBAL connect_timeout = 600;
SET GLOBAL max_allowed_packet = 1073741824;
SET GLOBAL net_read_timeout = 600;
SET GLOBAL net_write_timeout = 600;
SET SESSION max_execution_time = 0;

-- Process without the expensive ORDER BY at the end
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.date
    ) AS RollingPeopleVaccinated
FROM covid.coviddeaths dea
JOIN covid.covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
-- NO ORDER BY HERE - removes the most expensive operationrolling_vaccinations

WITH PopvsVac AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.date
        ) AS RollingPeopleVaccinated
    FROM covid.coviddeathnew dea
    JOIN covid.covidvaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT 
    *,
    (RollingPeopleVaccinated / Population) * 100 AS PercentVaccinated
FROM PopvsVac
ORDER BY location, date;


-- Using Temp Table to perform Calculation on Partition By in previous query


-- Step 1: Drop temp table if exists
DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;

-- Step 2: Create temporary table
CREATE TEMPORARY TABLE PercentPopulationVaccinated (
    Continent VARCHAR(255),
    Location VARCHAR(255),
    `Date` DATE,
    Population DECIMAL(20,0),
    New_vaccinations DECIMAL(20,0),
    RollingPeopleVaccinated DECIMAL(20,0)
);

-- Step 3: Insert data with cumulative sum
INSERT INTO PercentPopulationVaccinated
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    CAST(COALESCE(NULLIF(vac.new_vaccinations, ''), '0') AS DECIMAL) AS New_vaccinations,
    SUM(CAST(COALESCE(NULLIF(vac.new_vaccinations, ''), '0') AS DECIMAL))
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM coviddeathnew dea
JOIN covidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;

-- Step 4: Select with percentage calculation
SELECT *,
       (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM PercentPopulationVaccinated;


CREATE OR REPLACE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    CAST(COALESCE(NULLIF(vac.new_vaccinations, ''), '0') AS SIGNED) AS new_vaccinations,
    SUM(CAST(COALESCE(NULLIF(vac.new_vaccinations, ''), '0') AS SIGNED))
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM coviddeathnew dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
