#' Get an OSM network for a nominated location in 'silicate' (SC) format
#'
#' This function is especially intended for large cities for which overpass will
#' generally not deliver the whole network in one dump, and so divides
#' everything up into the requisite sequences of key-value pairs, and
#' reassembles the entire network at the end.
#'
#' @param location Name of location, passed to Nominatim server.
#' @param path Local path where network is to be saved. Final name will be the
#' first component of 'location', with '-sc.Rds' appended.
#' @export
pb_get_network <- function (location = "Paris France", path) {

    path <- normalizePath (path, mustWork = TRUE)

    loc_short <- regmatches (location, regexpr ("^[[:alpha:]]+", location))
    loc_short <- tolower (loc_short)

    bb <- osmdata::getbb (location)
    
    chk <- download_network_parts (bb, loc_short, path)

    if (!chk & interactive ()) {
        cli::cli_alert_danger ("Not all network parks were successfully downloaded")
        ans <- readline ("Do you want to continue (y/n)? ")
        if (tolower (substr (ans, 1, 1)) != "y") {
            stop ("Stopping; please run 'pb_get_network()' again", call. = FALSE)
        }
    }

    dat <- recombine_network_parts (path)

    fname <- file.path (path, paste0 (loc_short, "-sc.Rds"))
    saveRDS (dat, fname)
    cli::cli_alert_info ("File saved to [{fname}]")

    return (dat)
}

#' List OSM features
#'
#' fts list from dodgr-streetnet.R, without highway, because those key-val pairs
#' are done separately.
#' @noRd
pb_list_osm_features <- function () {

    c (
       #"\"highway\"",
       "restriction",
       "access",
       "bicycle",
       "foot",
       "motorcar",
       "motor_vehicle",
       "vehicle",
       "toll"
    )
}

#' List values for OSM highway tags
#' @noRd
pb_list_osm_highways <- function () {

    c (
        "motorway",
        "motorway_link",
        "trunk",
        "trunk_link",
        "bridleway",
        "cycleway",
        "footway",
        "living_street",
        "path",
        "pedestrian",
        "primary",
        "primary_link",
        "residential",
        "secondary",
        "secondary_link",
        "service",
        "steps",
        "tertiary",
        "tertiary_link",
        "track",
        "unclassified"
    )
}

download_network_parts <- function (bb, loc, path) {

    fts <- pb_list_osm_features ()
    hw_vals <- pb_list_osm_highways ()

    count <- 1
    n <- length (fts) + length (hw_vals)

    res <- TRUE

    for (f in fts) {

        message ("[", count, " / ", n, "]: ", f)
        count <- count + 1

        fname <- file.path (path, paste0 (loc, "-", f, ".Rds"))
        if (file.exists (fname)) {
            next
        }

        dat <- osmdata::opq (bb) |>
            osmdata::add_osm_feature (key = f) |>
            osmdata::osmdata_sc (quiet = FALSE)

        if (length (dat) == 8L) {
            saveRDS (dat, fname)
        } else {
            res <- FALSE
            cli::cli_alert_danger ("Downloading feature '{f}' failed; please re-run this function again")
        }
    }

    for (v in hw_vals) {

        message ("[", count, " / ", n, "]: highway:", v)
        count <- count + 1

        fname <- file.path (path, paste0 ("paris-hw-", v, ".Rds"))
        if (file.exists (fname)) {
            next
        }

        dat <- osmdata::opq (bb) |>
            osmdata::add_osm_feature (key = "highway", value = v) |>
            osmdata::osmdata_sc (quiet = TRUE)

        if (length (dat) == 8L) {
            saveRDS (dat, fname)
        } else {
            res <- FALSE
            cli::cli_alert_danger ("Downloading highway value '{v}' failed; please re-run this function again")
        }
    }

    invisible (res)
}

recombine_network_parts <- function (path) {

    cli::cli_alert_info ("Recombining network parts")

    flist <- list.files (path, full.names = TRUE, pattern = "\\.Rds$")
    ftarget <- grep ("\\-sc\\.Rds$", flist, value = TRUE)
    if (length (ftarget) > 0L) {
        cli::cli_alert_warning ("File '{ftarget}' already exists")
        ans <- readline ("Overwrite (y/n)? ")
        if (tolower (substr (ans, 1, 1)) != "y") {
            stop ("Stopping now without overwriting that file.")
        }
        flist <- flist [which (!flist == ftarget)]
    }

    dat <- readRDS (flist [1])
    flist <- flist [-1]

    count <- 1L
    for (f in flist) {

        message ("\r", count, " / ", length (flist), appendLF = FALSE)
        count <- count + 1L

        i <- readRDS (f)

        dat$nodes <- rbind (dat$nodes, i$nodes)
        dat$relation_members <- rbind (dat$relation_members, i$relation_members)
        dat$relation_properties <-
            rbind (dat$relation_properties, i$relation_properties)
        dat$object <- rbind (dat$object, i$object)
        dat$object_link_edge <- rbind (dat$object_link_edge, i$object_link_edge)
        dat$edge <- rbind (dat$edge, i$edge)
        dat$vertex <- rbind (dat$vertex, i$vertex)
    }
    message ("")

    dat$nodes <- unique (dat$nodes)
    dat$relation_members <- unique (dat$relation_members)
    dat$relation_properties <- unique (dat$relation_properties)
    dat$object <- unique (dat$object)
    dat$object_link_edge <- unique (dat$object_link_edge)
    dat$edge <- unique (dat$edge)
    dat$vertex <- unique (dat$vertex)

    return (dat)
}
