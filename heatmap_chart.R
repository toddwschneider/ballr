generate_heatmap_chart = function(shots, base_court, court_theme = court_themes$dark) {
  base_court +
    stat_density_2d(
      data = shots,
      aes(x = loc_x, y = loc_y, fill = stat(density / max(density))),
      geom = "raster", contour = FALSE, interpolate = TRUE, n = 200
    ) +
    geom_path(
      data = court_points,
      aes(x = x, y = y, group = desc),
      color = court_theme$lines
    ) +
    scale_fill_viridis_c(
      "Shot Frequency    ",
      limits = c(0, 1),
      breaks = c(0, 1),
      labels = c("lower", "higher"),
      option = "inferno",
      guide = guide_colorbar(barwidth = 15)
    ) +
    theme(legend.text = element_text(size = rel(0.6)))
}
