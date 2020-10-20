# Script for reading and wrangling the Google, Apple, and Facebook mobility datasets

library(tidyverse)
library(zoo)

# Prepare Google data -----------------------

## Google data
google <- read_csv(google_path)

google <- google %>%
    filter(country_region == "United Kingdom") %>%
    mutate(sub_region_1 = str_to_lower(sub_region_1),
           sub_region_1 = case_when(
               sub_region_1 == "bristol city" ~ "city of bristol",
               TRUE ~ sub_region_1))

## Geography lookup
geo_lookup <- read_csv("https://raw.githubusercontent.com/datasciencecampus/google-mobility-reports-data/master/geography/Google_Places_Lookup_Table_200417.csv")

geo_lookup <- geo_lookup %>%
    mutate(GPL_NM = str_to_lower(GPL_NM))

## Merge the Google and geo lookup
google_by_country <- google %>%
    left_join(geo_lookup, by = c("sub_region_1" = "GPL_NM")) %>%
    mutate(
        REGION_NM = case_when(
            REGION_NM %in% c("Wales", "Scotland", "Northern Ireland") ~ REGION_NM,
            is.na(sub_region_1) ~ "United Kingdom",
            TRUE ~ "England")) %>%
    pivot_longer(cols = retail_and_recreation_percent_change_from_baseline:
                     residential_percent_change_from_baseline,
                 names_to = "variable", values_to = "value") %>%
    mutate(
        variable = case_when(
            variable == "grocery_and_pharmacy_percent_change_from_baseline" ~ "Supermarkets and pharmacy",
            variable == "parks_percent_change_from_baseline" ~ "Parks",
            variable == "residential_percent_change_from_baseline" ~ "Residential",
            variable == "retail_and_recreation_percent_change_from_baseline" ~ "Retail and recreation",
            variable == "transit_stations_percent_change_from_baseline" ~ "Public transport",
            variable == "workplaces_percent_change_from_baseline" ~ "Workplaces"
            
        )
    )

## Summarise data and compute rolling averages
### Wales
wales_summary <- google_by_country %>%
    filter(REGION_NM == "Wales") %>%
    group_by(date, variable) %>%
    summarise(mean_pct = mean(value, na.rm = T))

google_wales_rolling_avg <- wales_summary %>%
    arrange(variable, date) %>%
    group_by(variable) %>%
    mutate(
        rolling_avg = rollapply(mean_pct, 7, mean, align = "right", fill = NA)
    )

### UK
uk_summary <- google_by_country %>%
    filter(REGION_NM == "United Kingdom") %>%
    group_by(date, variable) %>%
    summarise(mean_pct = mean(value, na.rm = T))

google_uk_rolling_avg <- uk_summary %>%
    arrange(variable, date) %>%
    group_by(variable) %>%
    mutate(
        rolling_avg = rollapply(mean_pct, 7, mean, align = "right", fill = NA)
    )

### UK nations
nation_summary <- google_by_country %>%
    filter(REGION_NM != "United Kingdom",
           !(variable %in% c("Residential", "Workplaces"))
           ) %>%
    group_by(date, REGION_NM) %>%
    summarise(mean_pct = mean(value, na.rm = T))

google_nation_rolling_average <- nation_summary %>%
    arrange(REGION_NM, date) %>%
    group_by(REGION_NM) %>%
    mutate(
        rolling_avg = rollapply(mean_pct, 7, mean, align = "right", fill = NA)
    )

# Prepare Apple data -----------------------

apple <- read_csv(apple_path)

## This code finds the column names that refer to dates (this data is in
## a wide format). This makes pivoting to longer format easier
fixed_colnames <- c("geo_type", "region", "transportation_type", "alternative_name",
                    "sub-region", "country")

date_colnames <- colnames(apple)[!(colnames(apple) %in% fixed_colnames)]

## Driving data

apple_nations <- apple %>%
    filter(region %in% c("United Kingdom", "Wales", "Northern Ireland", "Scotland", "England")) %>%
    pivot_longer(cols = date_colnames, names_to = "date") %>%
    mutate(date = as.Date(date))

apple_nations_rolling_average <- apple_nations %>%
    arrange(region, transportation_type, date) %>%
    group_by(region, transportation_type) %>%
    mutate(
        rolling_avg = rollapply(value, 7, mean, align = "right", fill = NA)
    )

## Comparison of Cardiff and Bristol 
apple_cities <- apple %>%
    filter(region %in% c('Cardiff', 'Bristol')) %>%
    pivot_longer(cols = date_colnames, names_to = "date")

apple_cities_rolling_average <- apple_cities%>%
    arrange(region, transportation_type, date) %>%
    group_by(region, transportation_type) %>%
    mutate(
        rolling_avg = rollapply(value, 7, mean, align = "right", fill = NA),
        date = as.Date(date)
    )


# Prepare Facebook data -----------------------

facebook <- read_tsv(facebook_path) %>%
    filter(polygon_name %in% c("England", "Scotland", "Wales", "Northern Ireland"),
           country == "GBR") %>%
    mutate(
        all_day_bing_tiles_visited_relative_change =
            as.numeric(all_day_bing_tiles_visited_relative_change),
        all_day_ratio_single_tile_users = 
            as.numeric(all_day_ratio_single_tile_users),
        ds = as.Date(ds)
    ) %>%
    pivot_longer(cols = c("all_day_bing_tiles_visited_relative_change",
                          "all_day_ratio_single_tile_users"), names_to = "variable")

facebook_rolling_average <- facebook %>%
    arrange(polygon_name, variable, ds) %>%
    group_by(polygon_name, variable) %>%
    mutate(
        rolling_avg = rollapply(value, 7, mean, align = "right", fill = NA)
    )