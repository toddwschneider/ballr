fetch_shots_by_player_id = function(player_id, bigquery_project_id) {
  req(player_id, bigquery_project_id)

  shots_sql = paste0("
    SELECT
      tournament,
      tournament_type,
      period,
      elapsed_time_sec,
      team_basket,
      timestamp,
      event_coord_x,
      event_coord_y,
      event_type,
      type,
      shot_made,
      shot_type,
      shot_subtype,
      three_point_shot,
      points_scored
    FROM [bigquery-public-data:ncaa_basketball.mbb_pbp_sr]
    WHERE type = 'fieldgoal'
      AND event_coord_x IS NOT NULL
      AND event_coord_y IS NOT NULL
      AND player_id = '", player_id, "'
  ")

  shots_raw = query_exec(shots_sql, bigquery_project_id) %>%
    as_data_frame()

  shots = mutate(shots_raw,
    # convert all shots to same side of court
    event_coord_x = case_when(
      team_basket == "right" ~ (94 * 12) - event_coord_x,
      TRUE ~ event_coord_x
    ),
    event_coord_y = case_when(
      team_basket == "right" ~ (50 * 12) - event_coord_y,
      TRUE ~ event_coord_y
    ),

    # convert NCAA (x, y) coordinates to BallR (x, y) coordinates
    loc_x = 25 - (event_coord_y / 12),
    loc_y = (event_coord_x / 12),

    # approximate zones as provided by NBA Stats API
    shot_distance = sqrt(loc_x ^ 2 + (loc_y - hoop_center_y) ^ 2),
    shot_zone_range = case_when(
      shot_distance < 8 ~ "Less Than 8 ft.",
      shot_distance < 16 ~ "8-16 ft.",
      shot_distance < 24 ~ "16-24 ft.",
      TRUE ~ "24+ ft."
    ),
    shot_angle = acos(loc_x / shot_distance) * 180 / pi,
    shot_zone_area = case_when(
      shot_angle < 36 ~ "Right Side(R)",
      shot_angle < 72 ~ "Right Side Center(RC)",
      shot_angle < 108 ~ "Center(C)",
      shot_angle < 144 ~ "Left Side Center(LC)",
      TRUE ~ "Left Side(L)"
    ),
    shot_zone_basic = case_when(
      shot_distance > 40 ~ "Backcourt",
      shot_distance < 4 ~ "Restricted Area",
      loc_x > (-outer_key_width / 2) & loc_x < (outer_key_width / 2) & loc_y < key_height ~ "In The Paint (Non-RA)",
      three_point_shot & shot_angle < 36 ~ "Right Corner 3",
      three_point_shot & shot_angle > 144 ~ "Left Corner 3",
      three_point_shot ~ "Above the Break 3",
      TRUE ~ "Mid-Range"
    ),
    shot_made_numeric = as.numeric(shot_made),
    shot_made_flag = factor(shot_made, levels = c(TRUE, FALSE), labels = c("made", "missed")),
    shot_value = ifelse(three_point_shot, 3, 2),
    year = case_when(
      month(timestamp) <= 4 ~ year(timestamp) - 1,
      TRUE ~ year(timestamp)
    ),
    season = paste(year, substr(year + 1, 3, 4), sep = "-")
  )

  return(shots)
}
