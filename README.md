# College BallR: Interactive NCAA Men's Basketball Shot Charts with R and Shiny

College BallR uses [data provided by Sportradar on Google BigQuery](https://console.cloud.google.com/launcher/details/ncaa-bb-public/ncaa-basketball) to visualize NCAA men's basketball shots. It is a modification of the [NBA BallR app](https://github.com/toddwschneider/ballr).

You'll need to set up a Google BigQuery project in order to use College BallR. Note that BigQuery currently provides some free operations each month, but if you go over those limits then you will be charged. See here for more: https://cloud.google.com/bigquery/pricing

## Notes

College BallR was hacked together fairly quickly from NBA BallR and should be considered experimental.

The Sportradar BigQuery API is considerably more flexible than the NBA Stats API, which means that with more work, College BallR should be able to support shot charts by team, conference, mascot name, and many other dimensions. For now though it only support shot charts by player.

## Run your own local version

You can run College BallR on your own machine by pasting the following code into the R console (you'll have to [install R](https://cran.rstudio.com/) first):

```R
packages = c("shiny", "ggplot2", "hexbin", "dplyr", "httr", "jsonlite", "bigrquery", "lubridate")
install.packages(packages, repos = "https://cran.rstudio.com/")
library(shiny)
runGitHub("ballr", "toddwschneider", ref = "college")
```

Enter your BigQuery credentials at the top of the sidebar. If it's your first time running the app, switch back to your R console and follow the OAuth prompt on screen. Once that's complete, it takes a few seconds for the app to fetch data from BigQuery, then you should be good to go.

## Screenshot

![college ballr](https://user-images.githubusercontent.com/70271/37571037-fc316b7a-2acd-11e8-83f7-e3a640f72b6b.png)

There are three chart types to choose from: **hexagonal**, **scatter**, and **heat map**. Read more about them on [the NBA version's README page](https://github.com/toddwschneider/ballr).

## Questions/issues/contact

todd@toddwschneider.com, or open a GitHub issue
