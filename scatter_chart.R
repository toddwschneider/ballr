generate_scatter_chart = function(shots, alpha = 0.8, size = 2.5, use_short_three = FALSE) {
  if (use_short_three) {
    base_court = short_three_court
  } else {
    base_court = court
  }

  base_court +
    geom_point(
      data = shots,
      aes(x = loc_x, y = loc_y, color = shot_made_flag),
      alpha = alpha, size = size
    ) +
    scale_color_manual("", values = c(made = "#FDE725", missed = "#1F9D89"))
}
