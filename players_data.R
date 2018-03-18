default_player_name = "Trae Young"

fetch_all_players = function(bigquery_project_id) {
  players_sql = "
    SELECT
      player_id,
      player_full_name,
      team_market,
      team_name
    FROM [bigquery-public-data:ncaa_basketball.mbb_pbp_sr]
    WHERE type = 'fieldgoal'
      AND event_coord_x IS NOT NULL
      AND event_coord_y IS NOT NULL
    GROUP BY player_id, player_full_name, team_market, team_name
  "

  players_raw = query_exec(players_sql, bigquery_project_id) %>%
    as_data_frame()

  players_with_unique_names = players_raw %>%
    group_by(player_full_name) %>%
    summarize(
      n = n_distinct(player_id),
      team = paste0(paste(team_market, team_name), collapse = ", "),
      player_id = first(player_id)
    ) %>%
    ungroup() %>%
    filter(n == 1) %>%
    select(player_id, player_full_name, team)

  players_with_non_unique_names = players_raw %>%
    filter(!(player_id %in% players_with_unique_names$player_id)) %>%
    transmute(
      player_id = player_id,
      player_full_name = paste0(player_full_name, " (", team_market, ")"),
      team = paste(team_market, team_name)
    )

  players = bind_rows(players_with_unique_names, players_with_non_unique_names) %>%
    group_by(player_id) %>%
    arrange(player_full_name) %>%
    summarize(
      name = first(player_full_name),
      team = first(team)
    ) %>%
    ungroup() %>%
    mutate(lower_name = tolower(name)) %>%
    arrange(lower_name)

  return(players)
}
