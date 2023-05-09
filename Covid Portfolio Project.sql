SELECT *
FROM PortfolioProject..CovidDeaths

--SELECT *
--FROM PortfolioProject..CovidVaccinations


-- Selecting the DATA, I am going to work with

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying, if you contract Covid in Hungary

SELECT Location, date, total_cases, total_deaths, (CAST(total_deaths AS float)/CAST(total_cases AS float)) * 100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Hungary'
and continent is not null 
ORDER BY 1,2


-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

SELECT Location, date, population, total_cases, (total_cases/population) * 100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location = 'Hungary'
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

SELECT Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
GROUP BY Location
ORDER BY TotalDeathCount desc


-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
GROUP BY continent
ORDER BY TotalDeathCount desc


-- GLOBAL NUMBERS

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
--Group By date
ORDER BY 1,2


-- Total Population vs Vaccinations

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(bigint, cv.new_vaccinations)) OVER 
(Partition by cd.location Order by cd.location, CONVERT(date, cd.date)) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
	ON cd.location = cv.location 
	and cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 2, 3


-- Using CTE to perform Calculation on Partition By in previous query

WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(bigint, cv.new_vaccinations)) OVER 
(Partition by cd.location Order by cd.location, CONVERT(date, cd.date)) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
	ON cd.location = cv.location 
	and cd.date = cv.date
WHERE cd.continent IS NOT NULL
-- ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopVsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(bigint, cv.new_vaccinations)) OVER 
(Partition by cd.location Order by cd.location, CONVERT(date, cd.date)) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
	ON cd.location = cv.location 
	and cd.date = cv.date
-- WHERE cd.continent IS NOT NULL
-- ORDER BY 2, 3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(bigint, cv.new_vaccinations)) OVER 
(Partition by cd.location Order by cd.location, CONVERT(date, cd.date)) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
	ON cd.location = cv.location 
	and cd.date = cv.date
where cd.continent is not null 
