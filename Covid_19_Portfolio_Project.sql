-- Verifying both tables have the same number of records after importing data from excel. 

	select count(*) from CovidDeaths

	select count(*) from CovidVaccinations

-- Querying data from both tables ordered by location and date

	select * from CovidDeaths order by location,date

	select * from CovidVaccinations order by location, date

-- Working with the CovidDeaths Table 

-- Querying columns that will be used for data exploration

	select continent, location, date, total_cases, new_cases, total_deaths, population 
	from CovidDeaths where continent is not null order by location,date 

-- Identifying Total Cases v/s Total Deaths 
-- The following query will show the chances an indidvidual may die if contracted with COVID-19 in India
	select Continent, location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage  
	from CovidDeaths where location = 'India' order by location,date 

-- Looking at Total Cases v/s Population in India

	select Continent, Location, Date, Population, Total_cases, (Total_cases/population)*100 as Percentage_of_cases 
	from CovidDeaths where location like '%India%' order by location,date 

-- Looking at Number of cases and Percentage of cases by Location

	select Continent, Location, Population, max(total_cases) as Number_of_cases, max((total_cases/population))*100 as Percentage_of_cases 
	from CovidDeaths 
	where continent is not null 
	group by Continent, location, population 
	order by continent, location,Percentage_of_cases desc

-- Looking at Number of deaths and Percentage of deaths by Location

	select Continent, Location, Population, max(cast(total_deaths as int)) as Number_of_deaths, max((cast(total_deaths as int))/population)*100 as Percentage_of_deaths 
	from CovidDeaths 
	where continent is not null 
	group by Continent,location, population 
	order by Number_of_deaths desc

-- Looking at death count by continent from the location column.  

	select location, max(cast(total_deaths as int)) as Number_of_deaths 
	from CovidDeaths 
	where continent is null 
	group by location 
	order by Number_of_deaths desc

-- Global statistics. Breaking down cases v/s deaths by date. 

	select date, sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as DeathPercentage
	from CovidDeaths
	where continent is not null and new_cases is not null
	group by date
	order by date

-- Global statistics. Total Cases v/s Deaths till date. 

	select  sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as DeathPercentage
	from CovidDeaths
	where continent is not null and location is not null
	
	select  max(total_cases) as TotalCases, max(cast(total_deaths as int)) as TotalDeaths, (max(cast(total_deaths as int))/max(total_cases))*100 as DeathPercentage
	from CovidDeaths
	
-- Joining both tables. 

-- Looking at Total Cases v/s New Vaccinations by location on each date. 

	select Distinct dea.continent, dea.location, dea.date, dea.total_cases, vac.new_vaccinations
	from CovidDeaths dea
	join CovidVaccinations vac
	on dea.continent = vac.continent
	and dea.date = vac.date
	where dea.continent is not null
	order by dea.location, dea.date

-- Looking at Total Cases v/s New Vaccinations v/s New Vaccinations till date by location on each date. 

	select dea.continent, dea.location, dea.date, dea.total_cases, vac.new_vaccinations, sum(convert(bigint,vac.new_vaccinations)) 
	over (partition by dea.location order by dea.location, dea.date) as Vaccinations_till_date 
	from CovidDeaths dea
	join CovidVaccinations vac
	on dea.iso_code = vac.iso_code
	and dea.date = vac.date
	where dea.continent is not null
	order by dea.location, dea.date
-- Used bigint because of Arithmetic overflow error converting expression to data type int.

--Test Query (Ignore)
	--	select * --dea.continent, dea.location, dea.date, dea.total_cases, vac.new_vaccinations 
	--	from CovidDeaths dea
	--	join CovidVaccinations vac
	--	on dea.iso_code = vac.iso_code
	--	and dea.date = vac.date
	--	where dea.continent is not null
	--	order by dea.location, dea.date

-- Looking at Total Population v/s New Vaccinations v/s New Vaccinations till date by location on each date. 

	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(bigint,vac.new_vaccinations)) 
	over (partition by dea.location order by dea.location, dea.date) as Vaccinations_till_date 
	from CovidDeaths dea
	join CovidVaccinations vac
	on dea.iso_code = vac.iso_code
	and dea.date = vac.date
	where dea.continent is not null
	order by dea.location, dea.date
		
 -- We will use CTE (Common Table Expression) to find out the percentage of people that were vaccinated in each location on a given date. 
 -- CTE does not support order by but it can be used outside the with statement when selecting data from CTE as seen below. 
 -- With CTE we don't have specify data types of the columns in the CTE. 

	with VaccinationvsPopulation(Continent, location, date, population, new_vaccinations, Vaccinations_till_date) 
	as
	(
 	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(bigint,vac.new_vaccinations)) 
	over (partition by dea.location order by dea.location, dea.date) as Vaccinations_till_date 
	from CovidDeaths dea
	join CovidVaccinations vac
	on dea.iso_code = vac.iso_code
	and dea.date = vac.date
	where dea.continent is not null
	--order by dea.location, dea.date
	)
	select *, (Vaccinations_till_date/population) * 100 
	from VaccinationvsPopulation order by 2,3

-- Doing the same thing above but instead using a TEMP Table. 
-- In the temp table we have to specify the data type for each column that is created. 
-- The drop table if exists command is very useful when making alteration to the table we can run the entire query from drop table to select to get the desired output with the alterations.

	Drop Table if exists PercentPopulationVaccinated
	Create Table PopulationVaccinated
	(
		Continent nvarchar(255),
		Location nvarchar(255),
		Date datetime,
		Population numeric,
		New_vaccinations numeric,
		Vaccinations_till_date numeric
	)
	insert into PopulationVaccinated
	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(bigint,vac.new_vaccinations)) 
	over (partition by dea.location order by dea.location, dea.date) as Vaccinations_till_date 
	from CovidDeaths dea
	join CovidVaccinations vac
	on dea.iso_code = vac.iso_code
	and dea.date = vac.date
	where dea.continent is not null
	order by dea.location, dea.date

	select *, (Vaccinations_till_date/Population) * 100 PercentPopulationVaccinated
	from PopulationVaccinated order by 2,3
	
-- Creating view to store data for visualizations later. 

	Create View PercentageofPopulationVaccinated as
	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(bigint,vac.new_vaccinations)) 
	over (partition by dea.location order by dea.location, dea.date) as Vaccinations_till_date 
	from CovidDeaths dea
	join CovidVaccinations vac
	on dea.iso_code = vac.iso_code
	and dea.date = vac.date
	where dea.continent is not null
	--order by dea.location, dea.date

-- Querying data from the view. 
	select *, (Vaccinations_till_date/Population) * 100 PercentPopulationVaccinated
	from PercentageofPopulationVaccinated order by 2,3