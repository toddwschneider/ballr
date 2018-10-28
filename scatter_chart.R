generate_scatter_chart = function(shots, base_court, court_theme = court_themes$dark, alpha = 0.8, size = 2.5) {
  base_court +
    geom_point(
      data = shots,
      aes(x = loc_x, y = loc_y, color = shot_made_flag),
      alpha = alpha, size = size
    ) +
    scale_color_manual(
      "",
      values = c(made = court_theme$made, missed = court_theme$missed)
    )
}
