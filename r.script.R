
# eBird dataset -----------------------------------------------------------


# Install packages --------------------------------------------------------

remotes::install_github("CornellLabofOrnithology/auk")

install.packages("auk")


# load packages -----------------------------------------------------------

library(gridExtra)

library(lubridate)

library(psych)

library(tidyverse)

library(readr)

library(auk)

library(dplyr)


# read data ---------------------------------------------------------------
dir.create("data", showWarnings = FALSE)

f_in <- "Data/ebd_sedwre_relJan-2021/ebd_sedwre_relJan-2021.txt"
f_out <- "ebd_filtered_sedwre.txt"
ebird_data <- f_in %>%
  auk_ebd() %>%
  auk_species(species = "Sedge Wren") %>%
  auk_country(country = "US") %>%
  auk_filter(file = f_out, overwrite = TRUE) %>%
  read_ebd()

glimpse(ebird_data)

ebird_data
ebird_data <- as_tibble(ebird_data)
ebird_data

ebird_data %>% filter(category == "TRUE") %>% select(
  latitude,
  longitude,
  observation_date,
  country,
  state,
  time_observations_started,
  duration_minutes,
  effort_distance_km,
  effort_area_ha,
  category,
  common_name,
  breeding_bird_atlas_category,
)


# Graph for quick glimpse -------------------------------------------------

read_ebd %>%
  dplyr::mutate(year = lubridate::year(observation_date)) %>%
  ggplot() +
  geom_bar(aes(year))  +
  hrbrthemes::theme_ipsum(
    base_size = 12,
    axis_title_size = 12,
    axis_text_size = 12)

# convert time ------------------------------------------------------------

time_to_decimal <- function(x) {
  x <- hms(x, quiet = TRUE)
  hour(x) + minute(x) / 60 + second(x) / 3600}



