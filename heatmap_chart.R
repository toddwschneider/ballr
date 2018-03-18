generate_heatmap_chart = function(shots) {
  court +
    stat_density_2d(
      data = shots,
      aes(x = loc_x, y = loc_y,
          fill = ..density..),
      geom = "raster", contour = FALSE, interpolate = TRUE, n = 200
    ) +
    geom_path(data = court_points,
              aes(x = x, y = y, group = desc, linetype = dash),
              color = "#999999") +
    scale_fill_gradientn(colors = inferno_colors, guide = FALSE ) +
    scale_colour_gradientn("Shot frequency    ",
                           limits = c(0, 1),
                           breaks = c(0, 1),
                           labels = c("lower", "higher"),
                           colours = inferno_colors,
                           guide = guide_colorbar(barwidth = 15)) +
    theme(legend.text = element_text(size = rel(0.6)))
}
