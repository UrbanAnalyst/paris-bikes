<!-- README.md is generated from README.Rmd. Please edit that file -->

[![R build
status](https://github.com/UrbanAnalyst/paris-bikes/workflows/R-CMD-check/badge.svg)](https://github.com/UrbanAnalyst/paris-bikes/actions?query=workflow%3AR-CMD-check)
[![Project Status:
Concept](https://www.repostatus.org/badges/latest/concept.svg)](https://www.repostatus.org/#concept)

Tool to estimate bicycle flows throughout the network of metropolitan
Paris, France.

## How?

Start by installing and loading the package:

``` r
remotes::install_github ("UrbanAnalyst/paris-bikes")
library (parisbikes)
```

Then just two steps. First, get the street network of Paris (or
anywhere) from Open Street Map.

``` r
path <- "<local>/<directory>/<for>/<paris>/<data>"
pb_get_network (location = "Paris France", path)
```

That function will create a file called “paris-sc.Rds” in the location
specified by “path”. Then load the resultant network and use that to
calculate centrality:

``` r
dat <- readRDS ("/<path>/<to>/paris-sc.Rds")
network <- pb_centrality (dat, mode = "bicycle")
```

It is also possible to calculate centrality including the effects of
elevation changes, by specifying an additional “elev_file” parameter as
the path to a local ‘geotiff’ elevation file. See the function
documentation of `pb_centrality` for details.

## Visualising the results

The following code can be used to visualise the resultant network
centrality, using [the `mapdeck`
package](https://symbolixau.github.io/mapdeck/index.html) (which first
requires an API token, as explained in the documentation). The following
code rescales the centrality measures using a value of 3.71 derived
elsewhere to optimally match observed distributions of cycling densities
in Paris.

``` r
index <- which (network$centrality > 0)
network <- dodgr::merge_directed_graph (network [index, ])
network$flow <- network$centrality / max (network$centrality)
network$flow <- network$flow ^ (1 / 3.71)
network$width <- 5 * network$flow
```

The following lines will then open an interactive visualization of the
flow densities throughout Paris.

``` r
library (mapdeck)
mapdeck (style = mapdeck_style ()) %>%
    add_line (net, 
              origin = c (".vx0_x", ".vx0_y"),
              destination = c (".vx1_x", ".vx1_y"),
              stroke_colour = "flow",
              stroke_width = "width",
              stroke_opacity = "flow",
              palette = "matlab_like2",
              legend = TRUE)
```
