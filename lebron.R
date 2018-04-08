lebron = find_player_by_name("LeBron James")
seasons = season_strings[as.character(2003:2015)]

all_shots = bind_rows(lapply(seasons, function(season) {
  fetch_shots_by_player_id_and_season(lebron$person_id, season)$player %>%
    mutate(season = season)
}))

###################
# filter to one user specified 'game_id'
###################

names(all_shots)
game_id_from_shiny_field = '0020300014'
shots_one_game = all_shots %>% 
  filter(game_id %in% game_id_from_shiny_field)
# head(shots_one_game)

###################

simplified_areas = c(
  "Center(C)" = "Center",
  "Left Side(L)" = "Left",
  "Left Side Center(LC)" = "Left",
  "Right Side(R)" = "Right",
  "Right Side Center(RC)" = "Right",
  "Back Court(BC)" = "Backcourt"
)

all_shots$simplified_area = simplified_areas[all_shots$shot_zone_area]

area = all_shots %>%
  filter(simplified_area != "Backcourt") %>%
  mutate(season = as.numeric(substr(season, 1, 4))) %>%
  group_by(season, simplified_area) %>%
  summarize(attempts = n()) %>%
  ungroup() %>%
  group_by(season) %>%
  mutate(frac = attempts / sum(attempts))

label_text = c("Center" = "Center", "Left" = "Left Side\n(his right)", "Right" = "Right Side\n(his left)")

ggplot(data = area, aes(x = season, y = frac, color = simplified_area)) +
  geom_line(size = 1) +
  scale_x_continuous("Season", breaks = seq(2003, 2015, by = 2)) +
  scale_y_continuous("% of shot attempts\n", labels = scales::percent) +
  scale_color_discrete("", guide = FALSE) +
  expand_limits(y = 0) +
  coord_cartesian(xlim = c(2003, 2017.5)) +
  ggtitle("LeBron James Shot Attempts by Court Area") +
  geom_text(data = filter(area, season == max(area$season)),
            aes(x = season + 0.25, y = frac, label = label_text[simplified_area]),
            size = 7, hjust = 0) +
  theme_bw(base_size = 22) +
  theme(
    text = element_text(color = "#f0f0f0"),
    panel.grid.major = element_line(size = 0.25, color = "#555555"),
    panel.grid.minor = element_line(size = 0.25, color = "#555555"),
    plot.background = element_rect(fill = bg_color, color = bg_color),
    panel.background = element_rect(fill = bg_color, color = bg_color)
  )

dist_fgp = all_shots %>%
  mutate(
    season = as.numeric(substr(season, 1, 4)),
    group = ifelse(season == 2015, "2015-16", "Prev 5 Seasons"),
    dist_bucket = cut(shot_distance, breaks = c(0, 1, 2, 4, 8, 12, 16, 20, 24, 32, 100), right = FALSE)
  ) %>%
  filter(season >= 2010) %>%
  group_by(group, dist_bucket) %>%
  summarize(fgp = mean(shot_made_numeric), attempts = n(), dist = mean(shot_distance)) %>%
  filter(attempts > 50)

ggplot(data = dist_fgp, aes(x = dist, y = fgp, color = group)) +
  geom_line(size=1) +
  scale_x_continuous("Shot distance (feet)") +
  scale_y_continuous("FG%", labels = scales::percent) +
  scale_color_discrete("", guide = FALSE) +
  expand_limits(y = 0.2) +
  coord_cartesian(xlim = c(0, 35)) +
  ggtitle("LeBron James FG% by Shot Distance") +
  geom_text(data = filter(dist_fgp, dist_bucket == "[24,32)"),
            aes(x = 26, y = fgp, label = group),
            size = 7, hjust = 0) +
  theme_bw(base_size = 22) +
  theme(
    text = element_text(color = "#f0f0f0"),
    panel.grid.major = element_line(size = 0.25, color = "#555555"),
    panel.grid.minor = element_line(size = 0.25, color = "#555555"),
    plot.background = element_rect(fill = bg_color, color = bg_color),
    panel.background = element_rect(fill = bg_color, color = bg_color)
  )
