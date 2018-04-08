library(shiny)
library(ggplot2)
library(hexbin)
library(dplyr)
library(httr)
library(jsonlite)

source("helpers.R")
source("plot_court.R")
source("players_data.R")
source("fetch_shots.R")
source("hex_chart.R")
source("scatter_chart.R")
source("heatmap_chart.R")

shinyUI(
  fixedPage(
    theme = "flatly.css",
    title = "BallR: Interactive NBA Shot Charts with R and Shiny",

    tags$head(
      tags$link(rel = "apple-touch-icon", href = "basketball.png"),
      tags$link(rel = "icon", href = "basketball.png"),
      tags$link(rel = "stylesheet", type = "text/css", href = "shared/selectize/css/selectize.bootstrap3.css"),
      tags$link(rel = "stylesheet", type = "text/css", href = "https://cdnjs.cloudflare.com/ajax/libs/bootstrap-select/1.10.0/css/bootstrap-select.min.css"),
      tags$link(rel = "stylesheet", type = "text/css", href = "custom_styles.css"),
      tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/html2canvas/0.4.1/html2canvas.min.js"),
      tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/bootstrap-select/1.10.0/js/bootstrap-select.min.js"),
      tags$script(src = "shared/selectize/js/selectize.min.js"),
      tags$script(src = "ballr.js"),
      includeScript("www/google-analytics.js")
    ),

    HTML('
      <nav class="navbar navbar-default navbar-static-top">
        <div class="container">
          <div>
            <ul class="nav navbar-nav col-xs-12">
              <li class="col-xs-8 col-md-9">
                <a href="#">BallR<span class="hidden-xs">: Interactive NBA Shot Charts</span></a>
              </li>
              <li class="col-xs-4 col-md-3 github-link">
                <a href="https://github.com/toddwschneider/ballr" target="_blank">
                  <span class="hidden-xs">Code on </span>GitHub
                </a>
              </li>
            </ul>
          </div>
        </div>
      </nav>
    '),

    fixedRow(class = "primary-content",
      div(class = "col-sm-8 col-md-9",
        div(class = "shot-chart-container",
          div(class = "shot-chart-header",
            h2(textOutput("chart_header_player")),
            h4(textOutput("chart_header_info")),
            h4(textOutput("chart_header_team"))
          ),

          plotOutput("court", height = "auto"),

          uiOutput("shot_filters_applied"),

          uiOutput("shot_chart_footer")
        ),

        div(class = "download-link-container",
          uiOutput("download_link")
        ),

        h3(textOutput("summary_stats_header")),
        uiOutput("summary_stats")
      ),

      div(class = "col-sm-4 col-md-3",
        div(class = "shot-chart-inputs",
          uiOutput("player_photo"),

          selectInput(inputId = "player_name",
                      label = "Player",
                      choices = c("Enter a player..." = "", available_players$name),
                      selected = default_player$name,
                      selectize = FALSE),

          selectInput(inputId = "season",
                      label = "Season",
                      choices = rev(default_seasons),
                      selected = default_season,
                      selectize = FALSE),

          dateRangeInput(inputId = "date_range",
                         label = "Date range",
                         start = FALSE,
                         end = FALSE),

          radioButtons(inputId = "chart_type",
                       label = "Chart Type",
                       choices = c("Hexagonal", "Scatter", "Heat Map"),
                       selected = "Hexagonal"),

          uiOutput("hex_metric_buttons"),
          uiOutput("hexbinwidth_slider"),
          uiOutput("hex_radius_slider"),

          h4("Filters"),

          selectInput(inputId = "shot_zone_basic_filter",
                      label = "Shot Zones",
                      choices = c("Above the Break 3",
                                  "Left Corner 3",
                                  "Right Corner 3",
                                  "Mid-Range",
                                  "In The Paint (Non-RA)",
                                  "Restricted Area"),
                      multiple = TRUE,
                      selectize = FALSE),

          selectInput(inputId = "shot_zone_angle_filter",
                      label = "Shot Angles",
                      choices = c("Left Side" = "Left Side(L)",
                                  "Left Center" = "Left Side Center(LC)",
                                  "Center" = "Center(C)",
                                  "Right Center" = "Right Side Center(RC)",
                                  "Right Side" = "Right Side(R)"),
                      multiple = TRUE,
                      selectize = FALSE),

          selectInput(inputId = "shot_distance_filter",
                      label = "Shot Distances",
                      choices = c("0-8 ft" = "Less Than 8 ft.",
                                  "8-16 ft" = "8-16 ft.",
                                  "16-24 ft" = "16-24 ft.",
                                  "24+ ft" = "24+ ft."),
                      multiple = TRUE,
                      selectize = FALSE),

          selectInput(inputId = "shot_result_filter",
                      label = "FG Made/Missed",
                      choices = c("All" = "all", "Made" = "made", "Missed" = "missed"),
                      selected = "all",
                      selectize = FALSE)
        )
      )
    )
  )
)
