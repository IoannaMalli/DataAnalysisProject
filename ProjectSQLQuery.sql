SELECT TOP 10 * FROM [SQLproject].[dbo].[covid-deaths];

SELECT TOP 10 * FROM [SQLproject].[dbo].[covid-vacc];

--Select Data that we will be using 

Select Location, date, total_cases, new_cases, total_deaths, population
FROM [SQLproject].[dbo].[covid-deaths]
ORDER BY 1,2;

-- Total Cases vs Total Deaths in Greece 
-- Shows the likelihood of death in case of contracting Covid in Greece
Select Location, date, total_cases, total_deaths, ROUND((total_deaths/NULLIF(total_cases,0)),4)*100 AS death_percentage
FROM [SQLproject].[dbo].[covid-deaths]
WHERE location LIKE '%Greece%'
ORDER BY 1,2;

-- Total Cases vs Population
-- Percentage of population that got Covid 
Select Location, date, total_cases, population, ROUND((total_cases/population),4)*100 AS infection_rate
FROM [SQLproject].[dbo].[covid-deaths]
WHERE location LIKE '%Greece%'
ORDER BY 1,2;

-- Highest infection Rate Countries in regards to their population
Select Location, population, MAX(total_cases) AS max_infection_count, Max(ROUND((total_cases/population),4))*100 AS MaxPopulationInfected
FROM [SQLproject].[dbo].[covid-deaths]
GROUP BY Location, Population
ORDER BY MaxPopulationInfected desc

-- Countries with Highest Death Count per capita
Select Location, MAX(total_deaths) AS total_death_count
FROM [SQLproject].[dbo].[covid-deaths]
WHERE continent<>'0'
GROUP BY Location
ORDER BY total_death_count desc

-- Continents with Highest Death count per capita
Select location, MAX(total_deaths) AS total_death_count
FROM [SQLproject].[dbo].[covid-deaths]
WHERE continent= '0' AND location NOT IN ('High income','Upper middle income','Lower middle income','Low income')
GROUP BY location
ORDER BY total_death_count desc

-- Showing the continents with highest death count -- 

Select continent, MAX(total_deaths) AS total_death_count
FROM [SQLproject].[dbo].[covid-deaths]
WHERE continent <> '0' AND location NOT IN ('High income','Upper middle income','Lower middle income','Low income')
GROUP BY continent
ORDER BY total_death_count desc

-- Global Numbers --
SELECT date, SUM(new_cases) as sum_new_cases, SUM(new_deaths) as sum_new_deaths, ROUND(SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100,2) as DeathPercentage
FROM [SQLproject].[dbo].[covid-deaths]
WHERE continent <> '0' AND location NOT IN ('High income','Upper middle income','Lower middle income','Low income')
GROUP BY date
ORDER BY 1,2;

-- Total population vs vaccinated population --
 SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations,
 SUM(CONVERT(bigint,vacc.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.Date)
	AS CumulativePeopleVacc
 FROM [SQLproject].[dbo].[covid-deaths] dea
 JOIN [SQLproject].[dbo].[covid-vacc] vacc
 ON dea.location = vacc.location 
	AND dea.date = vacc.date
WHERE dea.continent <> '0'
ORDER BY 2,3 

-- See the percentage of vaccinated people in each country every day ---
-- Using Common Table Expression -- 
WITH  PopvsVac (Continent, Location, Date, Population,new_vaccinations, RollingPeopleVaccinated)
AS 
( SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations,
 SUM(CONVERT(bigint,vacc.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.Date)
	AS CumulativePeopleVacc
 FROM [SQLproject].[dbo].[covid-deaths] dea
 JOIN [SQLproject].[dbo].[covid-vacc] vacc
 ON dea.location = vacc.location 
	AND dea.date = vacc.date
WHERE dea.continent <> '0')
SELECT *, ROUND((RollingPeopleVaccinated/Population)*100,2) as vacc_population_percentage
FROM PopvsVac
ORDER BY Location, Date

-- Using a temporary table --- 

DROP TABLE IF EXISTS #PercentPopulationVacc
CREATE TABLE #PercentPopulationVacc 
(
Continent nvarchar(70),
Location nvarchar(70),
Date datetime, 
Population numeric, 
New_vaccinations numeric,
RollingPeopleVaccinated numeric
) 
INSERT INTO #PercentPopulationVacc
 SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations,
 SUM(CONVERT(bigint,vacc.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.Date)
	AS CumulativePeopleVacc
 FROM [SQLproject].[dbo].[covid-deaths] dea
 JOIN [SQLproject].[dbo].[covid-vacc] vacc
 ON dea.location = vacc.location 
	AND dea.date = vacc.date
WHERE dea.continent <> '0'

SELECT  *, ROUND((RollingPeopleVaccinated/Population)*100,2) as vacc_population_percentage
FROM #PercentPopulationVacc
ORDER BY Location, Date
