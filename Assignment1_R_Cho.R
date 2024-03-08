## create a new project and set-up the project structure (folder, README, etc.)


## 1. Download two dataset about COVID-19 from this GitHub repository: “UID_ISO_FIPS_LookUp_Table” and “time_series_covid19_confirmed_global”. Save both data locally.

# download two dataset
count_city_github_url <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/UID_ISO_FIPS_LookUp_Table.csv?raw=true"
count_city <- read.csv(count_city_github_url)

timeseries_github_url <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv?raw=true"
timeseries <- read.csv(timeseries_github_url)

# save original dataset locally
save(count_city, file = "original_count_city.csv")
save(timeseries, file = "original_timeseries.csv")

-----------------------------------------------------------------------------

## 2. Merge the two datasets and create a long version of the data. Save both long and wide data locally

# creating Combined_Key variable in timeseries data
timeseries$Combined_Key <- 
  ifelse(is.na(timeseries$Province.State) | timeseries$Province.State == "",
         timeseries$Country.Region,
         paste(timeseries$Province.State, timeseries$Country.Region, sep = ", "))

# merging data (wide format)
covid_wide <- timeseries %>%
  left_join(count_city, by = "Combined_Key") %>%
  select(-c(Province.State, Country.Region, Lat.x, Long))

# changing the dataset to long format  
covid_long <- covid_wide %>%
  pivot_longer(
    cols = !c(Combined_Key, UID, iso2, iso3, code3, FIPS, Admin2, Province_State, Country_Region, Lat.y, Long_, Population),
    names_to = "time",
    values_to = "case"
  )

# remove X from covid_long
covid_long$time <- gsub("^X", "", covid_long$time)

# add date variable (month-day-year format)
covid_long$date <- mdy(covid_long$time)

# save both wide and long format dataset locally
save(covid_wide, file = "covid_wide.csv")
save(covid_long, file = "covid_long.csv")



## 3. Create three graphs using ggplot and save them

### i) overall change in time of log number of cases
plot_overall_change <- ggplot(covid_long, aes(x = date, y = log(case + 1))) +
  geom_line(color = "skyblue") +
  labs(title = "Overall Change in Time of Log number of Cases",
       x = "Time", 
       y = "Log Number of Cases")
plot_overall_change

# save the plot locally
ggsave("plot_overall_change.png", plot = plot_overall_change)


### ii) change in time of log number of cases by country
# group_by table
tab_change_ctry <- covid_long %>%
  group_by(Country_Region, date) %>%
  summarise(sum_case = sum(case), .groups = "drop")

# plot
plot_change_ctry <- ggplot(tab_change_ctry, aes(x = date, 
                                                y = log(sum_case), 
                                                color = Country_Region)) +
  geom_line() +
  labs(title = "Change in Time of Log number of Cases",
       x = "Time",
       y = "Log Number of Cases") +
  theme(legend.position = "none")
plot_change_ctry

# save the plot locally
ggsave("plot_change_ctry.png", plot = plot_change_ctry)


### iii) change in time by country of rate of infection per 100,000 cases
# group_by table
tab_change_rate_inf <- covid_long %>%
  group_by(Country_Region, date) %>%
  summarise(sum_case = sum(case), 
            population = sum(Population),
            .groups = "drop")
tab_change_rate_inf$rate_inf <- 
  (tab_change_rate_inf$sum_case/tab_change_rate_inf$population) * 100000

# plot
plot_change_rate_inf <- ggplot(tab_change_rate_inf, 
                               aes(x = date, 
                                   y = rate_inf, 
                                   color = Country_Region)) +
  geom_line() +
  labs(title = "Change in Time of Rate of Infection per 100,000 Cases",
       x = "Time",
       y = "Rate of infection per 100,000 Cases") +
  theme(legend.position = "none")
plot_change_rate_inf

# save
ggsave("plot_change_rate_inf.png", plot = plot_change_rate_inf)







