# BallR: Interactive NBA Shot Charts with R and Shiny

[BallR](http://toddwschneider.com/posts/ballr-interactive-nba-shot-charts-with-r-and-shiny/) uses the [NBA Stats API](http://stats.nba.com/) to visualize every shot taken by a player during an NBA season dating back to 1996.

[See this post for more info](http://toddwschneider.com/posts/ballr-interactive-nba-shot-charts-with-r-and-shiny/)

See also [the college branch of this repo](https://github.com/toddwschneider/ballr/tree/college) for men's college basketball shot charts.

## Run your own local version

You can run BallR on your own machine by pasting the following code into the R console (you'll have to [install R](https://cran.rstudio.com/) first):

```R
packages = c("shiny", "ggplot2", "hexbin", "dplyr", "httr", "jsonlite")
install.packages(packages, repos = "https://cran.rstudio.com/")
library(shiny)
runGitHub("ballr", "toddwschneider")
```

## Screenshot

[![ballr](https://cloud.githubusercontent.com/assets/70271/13547819/b74dca58-e2ae-11e5-8f00-7c3c768e77e3.png)](http://toddwschneider.com/posts/ballr-interactive-nba-shot-charts-with-r-and-shiny/)

There are three chart types to choose from: **hexagonal**, **scatter**, and **heat map**

### Hexagonal

Hexagonal charts, which are influenced by the work of [Kirk Goldsberry at Grantland](https://grantland.com/contributors/kirk-goldsberry/), use R's `hexbin` package to bin shots into hexagonal regions. The size and opacity of each hexagon are proportional to the number of shots taken within that region, and the color of each hexagon represents your choice of metric, which can be one of:

- FG% vs. league average
- FG%
- Points per shot

There are two sliders to adjust the maximum hexagon sizes, and also the variability of sizes across hexagons, e.g. [here's the same Stephen Curry chart](https://cloud.githubusercontent.com/assets/70271/13547845/63f4101e-e2af-11e5-9a57-13a8a61b367a.png) but with larger hexagons, and plotting points per shot as the color metric.

Note that the color metrics are not plotted at the individual hexagon level, but at the court region level, e.g. all hexagons on the left side of the court that are 16-24 feet from the basket will have the same color. If BallR were extended to, say, chart all shots for an entire team, then it might make sense to assign colors at the hexagon-level, but for single players that tends to produce excessive noise.

### Scatter

Scatter charts are the most straightforward option: they show the location of each individual shot, with color-coding for makes and misses

![scatter](https://cloud.githubusercontent.com/assets/70271/13382173/dfae7f46-de3b-11e5-9ca6-1e2740904b60.png)

### Heat map

Heat map charts use [two-dimensional kernel density estimation](https://en.wikipedia.org/wiki/Multivariate_kernel_density_estimation) to show the distribution of shot attempts across the court.

Anecdotally I've found that heat maps often show, unsurprisingly, that most shot attempts are taken in the restricted area near the basket. It might be more interesting to filter out restricted area shots when generating heat maps, for example here's the heat map of Stephen Curry's shot attempts *excluding* shots from within the restricted area:

![heat map excluding restricted area](https://cloud.githubusercontent.com/assets/70271/13588733/23896d06-e4a0-11e5-887e-f31c636de422.png)

### Filters

BallR lets you filter shots along a few dimensions (zone, angle, distance, made/missed) by adjusting the inputs in the sidebar. When you apply filters, the shot chart and summary stats update automatically to reflect whatever subset of shots you have chosen.

### Data

The data comes directly from the NBA Stats API via the `shotchartdetail` endpoint. See [fetch_shots.R](fetch_shots.R) for the API call itself. The player select input lets you choose any player and season back to 1996, so you can compare, for example, Michael Jordan of 1996 to LeBron James of 2012.

### See also: NBA Shots DB

NBA Shots DB is a Rails app that populates a PostgreSQL database with every NBA shot attempt since 1996 (4.5 million shots and growing).

https://github.com/toddwschneider/nba-shots-db

BallR does not interact with NBA Shots DB yet, but that might change in the future.

### Acknowledgments

Posts by [Savvas Tjortjoglou](http://savvastjortjoglou.com/nba-shot-sharts.html) and [Eduardo Maia](http://thedatagame.com.au/2015/09/27/how-to-create-nba-shot-charts-in-r/) about making NBA shot charts in Python and R, respectively, served as useful resources

## Questions/issues/contact

todd@toddwschneider.com, or open a GitHub issue
