required_ggplot2_version = "3.0.0"

if (packageVersion("ggplot2") < required_ggplot2_version) {
  stop(paste(
    "ggplot2 version",
    packageVersion("ggplot2"),
    "detected; please upgrade to at least",
    required_ggplot2_version
  ))
}

fraction_to_percent_format = function(frac, digits = 1) {
  paste0(format(round(frac * 100, digits), nsmall = digits), "%")
}

percent_formatter = function(x) {
  scales::percent(x, accuracy = 1)
}

points_formatter = function(x) {
  scales::comma(x, accuracy = 0.01)
}

short_three_seasons = c("1994-95", "1995-96", "1996-97")
