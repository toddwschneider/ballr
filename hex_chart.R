# from ggplot2 hexbin.R: https://github.com/hadley/ggplot2/blob/master/R/hexbin.R
hex_bounds <- function(x, binwidth) {
  c(
    plyr::round_any(min(x), binwidth, floor) - 1e-6,
    plyr::round_any(max(x), binwidth, ceiling) + 1e-6
  )
}

calculate_hex_coords = function(shots, binwidths) {
  xbnds = hex_bounds(shots$loc_x, binwidths[1])
  xbins = diff(xbnds) / binwidths[1]
  ybnds = hex_bounds(shots$loc_y, binwidths[2])
  ybins = diff(ybnds) / binwidths[2]

  hb = hexbin(
    x = shots$loc_x,
    y = shots$loc_y,
    xbins = xbins,
    xbnds = xbnds,
    ybnds = ybnds,
    shape = ybins / xbins,
    IDs = TRUE
  )

  shots = mutate(shots, hexbin_id = hb@cID)

  hexbin_stats = shots %>%
    group_by(hexbin_id) %>%
    summarize(
      hex_attempts = n(),
      hex_pct = mean(shot_made_numeric),
      hex_points_scored = sum(shot_made_numeric * shot_value),
      hex_points_per_shot = mean(shot_made_numeric * shot_value)
    )

  hexbin_ids_to_zones = shots %>%
    group_by(hexbin_id, shot_zone_range, shot_zone_area) %>%
    summarize(attempts = n()) %>%
    ungroup() %>%
    arrange(hexbin_id, desc(attempts)) %>%
    group_by(hexbin_id) %>%
    filter(row_number() == 1) %>%
    select(hexbin_id, shot_zone_range, shot_zone_area)

  hexbin_stats = inner_join(hexbin_stats, hexbin_ids_to_zones, by = "hexbin_id")

  # from hexbin package, see: https://github.com/edzer/hexbin
  sx = hb@xbins / diff(hb@xbnds)
  sy = (hb@xbins * hb@shape) / diff(hb@ybnds)
  dx = 1 / (2 * sx)
  dy = 1 / (2 * sqrt(3) * sy)
  origin_coords = hexcoords(dx, dy)

  hex_centers = hcell2xy(hb)

  hexbin_coords = bind_rows(lapply(1:hb@ncells, function(i) {
    data.frame(
      x = origin_coords$x + hex_centers$x[i],
      y = origin_coords$y + hex_centers$y[i],
      center_x = hex_centers$x[i],
      center_y = hex_centers$y[i],
      hexbin_id = hb@cell[i]
    )
  }))

  inner_join(hexbin_coords, hexbin_stats, by = "hexbin_id")
}

calculate_hexbins_from_shots = function(shots, binwidths = c(1, 1), min_radius_factor = 0.6, fg_pct_limits = c(0.2, 0.7), pps_limits = c(0.5, 1.5)) {
  if (nrow(shots) == 0) {
    return(list())
  }

  grouped_shots = group_by(shots, shot_zone_range, shot_zone_area)

  zone_stats = grouped_shots %>%
    summarize(
      zone_attempts = n(),
      zone_pct = mean(shot_made_numeric),
      zone_points_scored = sum(shot_made_numeric * shot_value),
      zone_points_per_shot = mean(shot_made_numeric * shot_value)
    )

  hex_data = calculate_hex_coords(shots, binwidths = binwidths)

  join_keys = c("shot_zone_area", "shot_zone_range")

  hex_data = hex_data %>%
    inner_join(zone_stats, by = join_keys)

  max_hex_attempts = max(hex_data$hex_attempts)

  hex_data = mutate(hex_data,
    radius_factor = min_radius_factor + (1 - min_radius_factor) * log(hex_attempts + 1) / log(max_hex_attempts + 1),
    adj_x = center_x + radius_factor * (x - center_x),
    adj_y = center_y + radius_factor * (y - center_y),
    bounded_fg_pct = pmin(pmax(zone_pct, fg_pct_limits[1]), fg_pct_limits[2]),
    bounded_points_per_shot = pmin(pmax(zone_points_per_shot, pps_limits[1]), pps_limits[2]))

  list(hex_data = hex_data, fg_pct_limits = fg_pct_limits, pps_limits = pps_limits)
}

generate_hex_chart = function(hex_data, metric = "bounded_fg_diff", alpha_range = c(0.85, 0.98)) {
  if (length(hex_data) == 0) {
    return(court)
  }

  if (metric == "bounded_fg_pct") {
    fill_limit = hex_data$fg_pct_limits
    fill_label = "FG%"
    label_formatter = scales::percent
  } else if (metric == "bounded_points_per_shot") {
    fill_limit = hex_data$pps_limits
    fill_label = "Points Per Shot"
    label_formatter = scales::comma
  } else {
    stop("invalid metric")
  }

  court +
    geom_polygon(data = hex_data$hex_data,
                 aes_string(x = "adj_x", y = "adj_y", group = "hexbin_id",
                            fill = metric, alpha = "hex_attempts"),
                 size = 0) +
         scale_fill_gradientn(paste0(fill_label, "   "),
                              colors = viridis_colors,
                              limit = fill_limit,
                              labels = label_formatter,
                              guide = guide_colorbar(barwidth = 15)) +
         scale_alpha_continuous(guide = FALSE, range = alpha_range, trans = "sqrt") +
         theme(legend.text = element_text(size = rel(0.6)))
}
