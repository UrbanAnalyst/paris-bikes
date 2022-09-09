
#' Calculate centrality on a street network for a specified mode of travel
#'
#' @param network Full path to file produced by \link{pb_get_network} function,
#' as an Open Street Map network in 'silicate' (SC) format.
#' @param elev_file Local path to a 'geotiff' file of elevation data covering
#' the geographical area of the network, and downloaded as explained in the
#' \pkg{osmdata} function 'osm_elevation'.
#' @param mode One of "foot", "bicycle", "moped", "motorcycle", or "motorcar"
#' @param estimate If `TRUE`, calculate an initial estimate of how long the
#' centrality calculation is likely to take.
#' @return A \pkg{dodgr} 'street_network' object including a "centrality"
#' column.
#'
#' @note The centrality calculation is run in parallel, and can not be
#' interrupted once it has begun. It is recommended to use `estimate = TRUE`,
#' after which an interactive prompt will allow the calculation to proceed.
#' Calculations may only be stopped by killing the R process.
#' @export
pb_centrality <- function (network, elev_file, mode = "bicycle", estimate = TRUE) {

    modes <- unique (dodgr::weighting_profiles$weighting_profiles$name)
    mode <- match.arg (mode, modes)


    if (!file.exists (network)) {
        stop ("File [", network, "] does not exist")
    }
    if (!file.exists (elev_file)) {
        stop ("File [", elev_file, "] does not exist")
    }

    message (cli::symbol$play, cli::col_green (" Loading network"),
             appendLF = FALSE)
    dat <- readRDS (network)
    message ("\r", cli::col_green (cli::symbol$tick, " Loaded network   "))

    message (cli::symbol$play, cli::col_green (" Extracting elevation data"),
             appendLF = FALSE)
    dat <- osmdata::osm_elevation (dat, elev_file)
    message ("\r", cli::col_green (cli::symbol$tick,
        " Extracted elevation data   "))

    message (cli::symbol$play,
             cli::col_green (" Weighting street network for bicycle routing"),
             appendLF = FALSE)
    graph <- dodgr::weight_streetnet (dat, wt_profile = mode)
    px <- attr (graph, "px")
    while (px$is_alive ()) {
        px$wait ()
    }
    message ("\r", cli::col_green (cli::symbol$tick,
        " Weighted street network for bicycle routing   "))


    if (estimate) {
        check <- dodgr::estimate_centrality_time (graph)
        ans <- readline ("Continue (y/n)")
        if (tolower (substr (ans, 1, 1)) != "y") {
            stop ("Okay, stopping now.")
        }
    }

    graph <- dodgr::dodgr_centrality (
        graph,
        column = "time_weighted",
        check_graph = FALSE,
        dist_threshold = 10000)

    return (graph)
}
