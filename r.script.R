
# eBird dataset -----------------------------------------------------------


# Install packages --------------------------------------------------------

remotes::install_github("CornellLabofOrnithology/auk")

install.packages("auk")

install.packages("maps")

install.packages("rnaturalearthdata")



# load packages -----------------------------------------------------------

library(gridExtra)

library(lubridate)

library(psych)

library(tidyverse)

library(readr)

library(auk)

library(dplyr)

library(rnaturalearth)



# read data ---------------------------------------------------------------

f_in <- system.file("extdata/ebd-sample.txt", package = "auk")
f_in <- "Data/ebd_sedwre_relJan-2021/ebd_sedwre_relJan-2021.txt"

f_in <- "Data/ebd_sedwre_relJan-2021/ebd_sedwre_relJan-2021.txt"
f_out <- "ebd_filtered_sedwre.txt"
ebird_data <- f_in %>%
  auk_ebd() %>%
  auk_species(species = "Sedge Wren") %>%
  auk_country(country = "US") %>% auk_date(date = c("2000-05-01", "2020-08-30")) %>%
  auk_filter(file = f_out, overwrite = TRUE) %>% auk_complete() %>%
  read_ebd()


# As_tibble form ----------------------------------------------------------

ebird_data
ebird_data <- as_tibble(ebird_data)
ebird_data

# Map the data ------------------------------------------------------------
map_world <-
  borders(category = "species",
          colour = "Green",
          fill = "#585858")
ggplot() + map_world +
  geom_point(
    data = ebird_data,
    aes(x = longitude,
        y = latitude,
        colour = "species"),
    alpha = 0.6,
    size = 2
  ) +
  scale_color_brewer(palette = "Dark2") +
  theme_classic() +
  ylab(expression("Latitude (" * degree * ")")) +
  xlab(expression("Longitude (" * degree * ")")) +
  theme(legend.position = "top",
        legend.title = element_text(colour = "Red", size = 5, face = "bold"))



# plot ------------------------------------------------------------

ggplot(data = ebird_data) +
  geom_polygon(mapping = aes(y = lat, x = long, group = group),
               data = map_data("state")) +
  geom_hex(mapping = aes(y = latitude, x = longitude)) +
  labs(y = "lat") + facet_wrap(~ month(observation_date)) +
  scale_fill_viridis_c()


map_data("state")
# Count by state ----------------------------------------------------------

count(ebird_data, state)
ggplot(data = ebird_data) +
  geom_bar(mapping = aes(x = fct_infreq(state)), fill = "#C5351B", 
           width = .3) +
  labs(x = "States", y = "Frequency (number of obs)") +
  scale_y_continuous(limits = c(0, 25000), expand = expansion(mult = 0)) +
  theme_classic(base_size = 6) +
  theme(
    axis.title = element_text(face = "bold"),
    axis.text = element_text(color = "black", size = rel(1)),
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.ticks.x = element_blank())

# summarise ebird_data ----------------------------------------------------

glimpse(ebird_data)
select_St_Vars <- select(ebird_data, latitude, longitude, locality_type)
select_St_Vars

summarise(
  select_St_Vars,
  sample_size = n(),
  mean = (latitude),
  max = (latitude),
  median = (latitude),
  sem = mean + sqrt(sample_size)
)

summarise(
  select_St_Vars,
  sample_size = n(),
  mean = (longitude),
  max = (longitude),
  median = (longitude),
  sem = mean + sqrt(sample_size)
)


# group variables ---------------------------------------------------------

select_St_Vars_grouped <- group_by(ebird_data, latitude, longitude, locality_type)
select_St_Vars_grouped

ebird_data_summarized <-
  summarise(
    select_St_Vars_grouped,
    sample_size = n(),
    mean = mean(latitude),
    sd = sd(latitude),
    var = var(latitude),
    stderr = sd / sqrt(sample_size),
    ci_upper = mean + 2 * stderr,
    ci_lower = mean - 2 * stderr
  )

# Pick a state then count per county obs ----------------------------------

MN_birds <- filter(ebird_data, state == "Minnesota")

ggplot(data = MN_birds, mapping = aes(y = latitude, x = longitude)) +
  geom_boxplot(alpha = 0) +
  geom_jitter(alpha = 0.3, color = "Red")

count(MN_birds, county)
ggplot(data = MN_birds) +
  geom_bar(mapping = aes(x = fct_infreq(county)), fill = "#C5351B", 
           width = .3) +
  labs(x = "County", y = "Frequency (number of birds)") +
  scale_y_continuous(limits = c(0, 1250), expand = expansion(mult = 0)) +
  theme_classic(base_size = 12) +
  theme(
    axis.title = element_text(face = "bold"),
    axis.text = element_text(color = "black", size = rel(0.5)),
    axis.text.x = element_text(angle = 75, hjust = 1.2),
    axis.ticks.x = element_blank()
  )

# observations in Clay county since 2000 ----------------------------------


Clay_birds <- filter(MN_birds, county == "Clay")

ggplot(data = Clay_birds, mapping = aes(x = observation_date)) +
  geom_histogram(alpha = 0.3, color = "purple")


Clay_filter_time <- filter(Clay_birds, observation_date > "2020-01-01")
Clay_filter_time


ggplot(data = Clay_filter_time, mapping = aes(x = observation_date)) +
  geom_histogram(alpha = 0.3, color = "purple")


auk_breeding <- Clay_birds %>% select(time_observations_started, duration_minutes)
auk_breeding_1 <- Clay_birds %>%
  mutate(Duration = as.numeric(duration_minutes))

# convert time observation to hours/minutes,seconds -----------------------

time_to_decimal <- function(x) {
  x <- hms(x, quiet = TRUE)
  hour(x) + minute(x) / 60 + second(x) / 3600}

Clay_birds <- Clay_birds %>% 
  mutate(
    # convert X to NA
    observation_count = if_else(observation_count == "X", 
                                NA_character_, observation_count),
    observation_count = as.integer(observation_count),
    # effort_distance_km to 0 for non-travelling counts
    effort_distance_km = if_else(protocol_type != "Traveling", 
                                 0, effort_distance_km),
    # convert time to decimal hours since midnight
    time_observations_started = time_to_decimal(time_observations_started),
    # split date into year and day of year
    year = year(observation_date),
    day_of_year = yday(observation_date))

# additional filtering
Clay_birds_filtered <- Clay_birds %>% 
  filter(
    # effort filters
    duration_minutes <= 5 * 60,
    effort_distance_km <= 5,
    # last 5 years of data
    year >= 2015,
    # 10 or fewer observers
    number_observers <= 5)

breaks <- 0:24
labels <- breaks[-length(breaks)] + diff(breaks) / 2
Clay_birds_tod <- Clay_birds %>% 
  mutate(tod_bins = cut(time_observations_started, 
                        breaks = breaks, 
                        labels = labels,
                        include.lowest = TRUE),
         tod_bins = as.numeric(as.character(tod_bins))) %>% 
  group_by(tod_bins) %>% 
  summarise(n_checklists = n(),
            n_detected = sum(number_observers),
            det_freq = mean(number_observers))
    


# Create Histogram --------------------------------------------------------

Graph_Hist <- ggplot(Clay_birds_tod) +
  aes(x = tod_bins, y = n_checklists) +
  geom_segment(aes(xend = tod_bins, y = 1, yend = n_checklists),
               color = "Skyblue") +
  geom_point() +
  scale_x_continuous(breaks = seq(0, 30, by = 5), limits = c(0, 30)) +
  scale_y_continuous(labels = scales::comma) +
  labs(x = "Hours since midnight",
       y = "# checklists",
       title = "observation start times/ high to low alert")
  
## graph hist

grid.arrange(Graph_Hist)


# observations occurance ---------------------------------------------------------

ggplot(data = Clay_birds, aes(x = observation_date , y = longitude)) +
  geom_point() +
  labs(x = "Date")

...






