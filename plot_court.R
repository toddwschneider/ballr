circle_points = function(center = c(0, 0), radius = 1, npoints = 360) {
  angles = seq(0, 2 * pi, length.out = npoints)
  return(data_frame(x = center[1] + radius * cos(angles),
                    y = center[2] + radius * sin(angles)))
}

theme_court = function(base_size = 16) {
  theme_bw(base_size) +
    theme(
      text = element_text(color = "#f0f0f0"),
      plot.background = element_rect(fill = bg_color, color = bg_color),
      panel.background = element_rect(fill = bg_color, color = bg_color),
      panel.grid = element_blank(),
      panel.border = element_blank(),
      axis.text = element_blank(),
      axis.title = element_blank(),
      axis.ticks.length = unit(0, "lines"),
      legend.background = element_rect(fill = bg_color, color = bg_color),
      legend.position = "bottom",
      legend.key = element_blank(),
      legend.text = element_text(size = rel(1.0))
    )
}

width = 50
height = 94 / 2
key_height = 19
inner_key_width = 12
outer_key_width = 16
backboard_width = 6
backboard_offset = 4
neck_length = 0.5
hoop_radius = 0.75
hoop_center_y = backboard_offset + neck_length + hoop_radius
three_point_radius = 23.75
three_point_side_radius = 22
three_point_side_height = 14

short_three_radius = 22
short_three_seasons = c("1994-95", "1995-96", "1996-97")

court_points = data_frame(
  x = c(width / 2, width / 2, -width / 2, -width / 2, width / 2),
  y = c(height, 0, 0, height, height),
  desc = "perimeter"
)

court_points = bind_rows(court_points , data_frame(
  x = c(outer_key_width / 2, outer_key_width / 2, -outer_key_width / 2, -outer_key_width / 2),
  y = c(0, key_height, key_height, 0),
  desc = "outer_key"
))

court_points = bind_rows(court_points , data_frame(
  x = c(-backboard_width / 2, backboard_width / 2),
  y = c(backboard_offset, backboard_offset),
  desc = "backboard"
))

court_points = bind_rows(court_points , data_frame(
  x = c(0, 0), y = c(backboard_offset, backboard_offset + neck_length), desc = "neck"
))

foul_circle = circle_points(center = c(0, key_height), radius = inner_key_width / 2)

foul_circle_top = filter(foul_circle, y > key_height) %>%
  mutate(desc = "foul_circle_top")

foul_circle_bottom = filter(foul_circle, y < key_height) %>%
  mutate(
    angle = atan((y - key_height) / x) * 180 / pi,
    angle_group = floor((angle - 5.625) / 11.25),
    desc = paste0("foul_circle_bottom_", angle_group)
  ) %>%
  filter(angle_group %% 2 == 0) %>%
  select(x, y, desc)

hoop = circle_points(center = c(0, hoop_center_y), radius = hoop_radius) %>%
  mutate(desc = "hoop")

restricted = circle_points(center = c(0, hoop_center_y), radius = 4) %>%
  filter(y >= hoop_center_y) %>%
  mutate(desc = "restricted")

three_point_circle = circle_points(center = c(0, hoop_center_y), radius = three_point_radius) %>%
  filter(y >= three_point_side_height)
short_three_circle = circle_points(center = c(0, hoop_center_y), radius = short_three_radius) %>%
  filter(y >= hoop_center_y)

three_point_line = data_frame(
  x = c(three_point_side_radius, three_point_side_radius, three_point_circle$x, -three_point_side_radius, -three_point_side_radius),
  y = c(0, three_point_side_height, three_point_circle$y, three_point_side_height, 0),
  desc = "three_point_line"
)

short_three_line = data_frame(
  x = c(three_point_side_radius, three_point_side_radius, short_three_circle$x, -three_point_side_radius, -three_point_side_radius),
  y = c(0, hoop_center_y, short_three_circle$y, hoop_center_y, 0),
  desc = "short_three_line"
)

court_without_three = bind_rows(court_points , foul_circle_top, foul_circle_bottom, hoop, restricted)

court_points = bind_rows(court_without_three, three_point_line)
court_points = mutate(court_points , dash = (desc == "foul_circle_bottom"))

short_three_court_points = bind_rows(court_without_three, short_three_line)
short_three_court_points = mutate(short_three_court_points , dash = (desc == "foul_circle_bottom"))

court = ggplot() +
  geom_path(data = court_points,
            aes(x = x, y = y, group = desc),
            color = "#999999") +
  coord_fixed(ylim = c(0, 35), xlim = c(-25, 25)) +
  theme_court(base_size = 22)

short_three_court = ggplot() +
  geom_path(data = short_three_court_points,
            aes(x = x, y = y, group = desc),
            color = "#999999") +
  coord_fixed(ylim = c(0, 35), xlim = c(-25, 25)) +
  theme_court(base_size = 22)
