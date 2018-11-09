library(shiny)

shinyServer(function(input, output, session) {
  bigquery_project_id = reactive({
    input$bigquery_project_id
  })

  output$bigquery_notice = renderUI({
    if (bigquery_project_id() == "") {
      h2("Enter your BigQuery project info to get started")
    }
  })

  players = reactive({
    req(bigquery_project_id())

    withProgress({
      fetch_all_players(bigquery_project_id())
    }, message = "Fetching players data...")
  })

  update_players_input = observe({
    req(players())

    current_selection = input$player_name

    updateSelectInput(
      session,
      "player_name",
      choices = c("Enter a player..." = "", players()$name),
      selected = current_selection
    )
  })

  current_player = reactive({
    req(bigquery_project_id(), input$player_name)
    filter(players(), lower_name == tolower(input$player_name))
  })

  current_player_seasons = reactive({
    req(shots())
    shots()$season %>% unique() %>% sort()
  })

  court_theme = reactive({
    req(input$court_theme)
    court_themes[[tolower(input$court_theme)]]
  })

  court_plot = reactive({
    req(court_theme())
    plot_court(court_theme = court_theme())
  })

  current_seasons = reactive({
    if (is.null(input$season_filter)) {
      current_player_seasons()
    } else {
      input$season_filter
    }
  })

  update_season_input = observe({
    updateSelectInput(session,
                      "season_filter",
                      choices = rev(current_player_seasons()),
                      selected = NULL)
  })

  shots = reactive({
    req(current_player(), bigquery_project_id())
    fetch_shots_by_player_id(current_player()$player_id, bigquery_project_id())
  })

  filtered_shots = reactive({
    req(input$shot_result_filter, shots())

    filter(shots(),
      input$shot_result_filter == "all" | shot_made_flag == input$shot_result_filter,
      shot_zone_basic != "Backcourt",
      is.null(input$shot_zone_basic_filter) | shot_zone_basic %in% input$shot_zone_basic_filter,
      is.null(input$shot_zone_angle_filter) | shot_zone_area %in% input$shot_zone_angle_filter,
      is.null(input$shot_distance_filter) | shot_zone_range %in% input$shot_distance_filter,
      is.null(input$season_filter) | season %in% input$season_filter,
      is.na(input$date_range[1]) | game_date >= input$date_range[1],
      is.na(input$date_range[2]) | game_date <= input$date_range[2]
    )
  })

  hexbin_data = reactive({
    req(filtered_shots(), shots(), hexbinwidths(), input$hex_radius)

    calculate_hexbins_from_shots(filtered_shots(),
                                 binwidths = hexbinwidths(),
                                 min_radius_factor = input$hex_radius)
  })

  output$hexbinwidth_slider = renderUI({
    req(input$chart_type == "Hexagonal")

    sliderInput("hexbinwidth",
                "Hexagon Size (feet)",
                min = 0.5,
                max = 4,
                value = 1.5,
                step = 0.25)
  })

  hexbinwidths = reactive({
    req(input$hexbinwidth)
    rep(input$hexbinwidth, 2)
  })

  output$hex_radius_slider = renderUI({
    req(input$chart_type == "Hexagonal")

    sliderInput("hex_radius",
                "Min Hexagon Size Adjustment",
                min = 0,
                max = 1,
                value = 0.4,
                step = 0.05)
  })

  alpha_range = reactive({
    req(input$chart_type == "Hexagonal", input$hex_radius)
    max_alpha = 0.98
    min_alpha = max_alpha - 0.25 * input$hex_radius
    c(min_alpha, max_alpha)
  })

  output$hex_metric_buttons = renderUI({
    req(input$chart_type == "Hexagonal")

    selectInput("hex_metric",
                "Hexagon Colors",
                choices = c("FG%" = "bounded_fg_pct",
                            "Points Per Shot" = "bounded_points_per_shot"),
                selected = "bounded_fg_pct",
                selectize = FALSE)
  })

  output$scatter_size_slider = renderUI({
    req(input$chart_type == "Scatter")

    sliderInput("scatter_size",
                "Dot size",
                min = 1,
                max = 10,
                value = 4,
                step = 0.5)
  })

  output$scatter_alpha_slider = renderUI({
    req(input$chart_type == "Scatter")

    sliderInput("scatter_alpha",
                "Opacity",
                min = 0.01,
                max = 1,
                value = 0.7,
                step = 0.01)
  })

  shot_chart = reactive({
    req(filtered_shots(), current_player(), input$chart_type, court_plot())

    filters_applied()

    if (input$chart_type == "Hexagonal") {
      req(input$hex_metric, alpha_range())

      generate_hex_chart(
        hex_data = hexbin_data(),
        base_court = court_plot(),
        court_theme = court_theme(),
        metric = sym(input$hex_metric),
        alpha_range = alpha_range()
      )
    } else if (input$chart_type == "Scatter") {
      req(input$scatter_alpha, input$scatter_size)

      generate_scatter_chart(
        filtered_shots(),
        base_court = court_plot(),
        court_theme = court_theme(),
        alpha = input$scatter_alpha,
        size = input$scatter_size
      )
    } else if (input$chart_type == "Heat Map") {
      generate_heatmap_chart(
        filtered_shots(),
        base_court = court_plot(),
        court_theme = court_theme()
      )
    } else {
      stop("invalid chart type")
    }
  })

  output$shot_chart_css = renderUI({
    req(court_theme())
    tags$style(paste0(
      ".shot-chart-container {",
        "background-color: ", court_theme()$court, "; ",
        "color: ", court_theme()$text,
      "}"
    ))
  })

  output$chart_header_player = renderText({
    req(current_player())
    current_player()$name
  })

  output$chart_header_info = renderText({
    req(shots())
    paste(current_seasons(), collapse = ", ")
  })

  output$chart_header_team = renderText({
    req(shots())
    current_player()$team
  })

  output$shot_chart_footer = renderUI({
    req(shot_chart())

    tags$div(
      "Data via Sportradar on Google BigQuery",
      tags$br(),
      "toddwschneider.com/ballr"
    )
  })

  output$download_link = renderUI({
    req(shot_chart())

    filename_parts = c(
      current_player()$name,
      "Shot Chart",
      input$chart_type
    )
    fname = paste0(gsub("_", "-", gsub(" ", "-", tolower(filename_parts))), collapse = "-")

    tags$a("Download Chart",
           href = "#",
           class = "download-shot-chart",
           "data-filename" = paste0(fname, ".png"))
  })

  output$court = renderPlot({
    req(shot_chart())
    withProgress({
      shot_chart()
    }, message = "Calculating...")
  }, height = 600, width = 800, bg = "transparent")

  filters_applied = reactive({
    req(filtered_shots())
    filters = list()

    if (!is.null(input$shot_zone_basic_filter)) {
      filters[["Zone"]] = paste("Zone:", paste(input$shot_zone_basic_filter, collapse = ", "))
    }

    if (!is.null(input$shot_zone_angle_filter)) {
      filters[["Angle"]] = paste("Angle:", paste(input$shot_zone_angle_filter, collapse = ", "))
    }

    if (!is.null(input$shot_distance_filter)) {
      filters[["Distance"]] = paste("Distance:", paste(input$shot_distance_filter, collapse = ", "))
    }

    if (input$shot_result_filter != "all") {
      filters[["Result"]] = paste("Result:", input$shot_result_filter)
    }

    if (!is.na(input$date_range[1]) | !is.na(input$date_range[2])) {
      dates = format(input$date_range, "%m/%d/%y")
      dates[is.na(dates)] = ""

      filters[["Dates"]] = paste("Dates:", paste(dates, collapse = "–"))
    }

    filters
  })

  output$shot_filters_applied = renderUI({
    req(length(filters_applied()) > 0)

    div(class = "shot-filters",
      tags$h5("Shot Filters Applied"),
      lapply(filters_applied(), function(text) {
        div(text)
      })
    )
  })

  output$summary_stats_header = renderText({
    req(current_player())
    paste(current_player()$name, "Summary Stats")
  })

  output$summary_stats = renderUI({
    req(filtered_shots(), shots())
    req(nrow(filtered_shots()) > 0)

    player_zone = filtered_shots() %>%
      group_by(shot_zone_basic) %>%
      summarize(fgm = sum(shot_made_numeric),
                fga = n(),
                pct = mean(shot_made_numeric),
                pct_as_text = fraction_to_percent_format(pct),
                points_per_shot = mean(shot_value * shot_made_numeric)) %>%
      arrange(desc(fga), desc(fgm)) %>%
      ungroup()

    # NCAA data does not include league averages
    merged = player_zone

    overall = summarize(merged,
      total_fgm = sum(fgm),
      total_fga = sum(fga),
      pct = total_fgm / total_fga,
      pct_as_text = fraction_to_percent_format(pct),
      points_per_shot = sum(points_per_shot * fga) / sum(fga)
    )

    html = list(div(class = "row headers",
      span(class = "col-xs-4 col-md-3 zone-label", "Zone"),
      span(class = "col-xs-2 numeric", "FGM"),
      span(class = "col-xs-2 numeric", "FGA"),
      span(class = "col-xs-2 numeric", "FG%"),
      span(class = "col-xs-2 numeric", "Pts/Shot")
    ))

    for (i in 1:nrow(merged)) {
      html[[i + 2]] = div(class = paste("row", ifelse(i %% 2 == 0, "even", "odd")),
        span(class = "col-xs-4 col-md-3 zone-label", merged$shot_zone_basic[i]),
        span(class = "col-xs-2 numeric", merged$fgm[i]),
        span(class = "col-xs-2 numeric", merged$fga[i]),
        span(class = "col-xs-2 numeric", merged$pct_as_text[i]),
        span(class = "col-xs-2 numeric", round(merged$points_per_shot[i], 2))
      )
    }

    html[[length(html) + 1]] = div(class = "row overall",
      span(class = "col-xs-4 col-md-3 zone-label", "Overall"),
      span(class = "col-xs-2 numeric", overall$total_fgm),
      span(class = "col-xs-2 numeric", overall$total_fga),
      span(class = "col-xs-2 numeric", overall$pct_as_text),
      span(class = "col-xs-2 numeric", round(overall$points_per_shot, 2))
    )

    html
  })
})
