library (osmdata)

if (!dir.exists ("data"))
    dir.create ("data")

if (!file.exists ("data/osm-ms-48155.Rds"))
{
    # 48155 sometimes returns a very small box, other times the full area, so ...
    bb <- c (7.632622, 51.9163722, 7.7231164, 51.9906058)
    #dat <- opq ("48155 de") %>%
    dat <- opq (bb) %>%
        add_osm_feature (key = "highway") %>%
        osmdata_sf (quiet = FALSE)
    saveRDS (dat, file = "data/osm-ms-48155.Rds")
}

if (!file.exists ("data/osm-promenade.Rds"))
{
    promenade <- opq ("münster de") %>%
        add_osm_feature (key = "highway") %>%
        add_osm_feature (key = "name", value = "Promenade", value_exact = FALSE) %>%
        osmdata_sf (quiet = FALSE)
    saveRDS (promenade, file = "data/osm-promenade.Rds")
}

if (!file.exists ("data/osm-ms-highways.Rds"))
{
    ms <- opq ("münster de") %>%
        add_osm_feature (key = "highway") %>%
        osmdata_sf (quiet = FALSE)
    saveRDS (ms, file = "data/osm-ms-highways.Rds")
}

if (!(file.exists ("data/dodgr-flows-ms.Rds") &
      file.exists ("data/dodgr-flows-ms90.Rds") &
      file.exists ("data/dodgr-flows-ms80.Rds") &
      file.exists ("data/dodgr-flows-ms70.Rds")))
{
    ms <- readRDS ("data/osm-ms-highways.Rds")
    library (dodgr)
    ms <- osm_poly2line (ms)
    # get OSM way IDs for promenade
    index <- grep ("promenade", ms$osm_lines$name, ignore.case = TRUE)
    kp <- grep ("kanal", ms$osm_lines$name, ignore.case = TRUE)
    index <- index [!index %in% kp]
    ids <- ms$osm_lines$osm_id [index] %>% as.character ()
    index <- which (g$way_id %in% ids)

    g0 <- weight_streetnet (ms$osm_lines, wt_profile = "bicycle")
    v <- dodgr_vertices (g)
    pts <- sample (v$id, size = 1000)
    flowmat <- matrix (1, nrow = 1000, ncol = 1000)
    if (!file.exists ("data/dodgr-flows-ms.Rds"))
    {
        message ("Aggregating flows with promenade = 100%")
        f <- dodgr_flows_aggregate (g0, from = pts, to = pts, flows = flowmat)
        saveRDS (f, file = "data/dodgr-flows-ms.Rds")
    }

    if (!file.exists ("data/dodgr-flows-ms90.Rds"))
    {
        message ("Aggregating flows with promenade = 90%")
        f <- dodgr_flows_aggregate (g0, from = pts, to = pts, flows = flowmat)
        g <- g0
        g$d_weighted [index] <- g$d [index] * 0.9
        f <- dodgr_flows_aggregate (g, from = pts, to = pts, flows = flowmat)
        saveRDS (f, file = "data/dodgr-flows-ms90.Rds")
    }

    if (!file.exists ("data/dodgr-flows-ms80.Rds"))
    {
        message ("Aggregating flows with promenade = 80%")
        g <- g0
        g$d_weighted [index] <- g$d [index] * 0.8
        f <- dodgr_flows_aggregate (g, from = pts, to = pts, flows = flowmat)
        saveRDS (f, file = "data/dodgr-flows-ms80.Rds")
    }

    if (!file.exists ("data/dodgr-flows-ms70.Rds"))
    {
        message ("Aggregating flows with promenade = 80%")
        g <- g0
        g$d_weighted [index] <- g$d [index] * 0.7
        f <- dodgr_flows_aggregate (g, from = pts, to = pts, flows = flowmat)
        saveRDS (f, file = "data/dodgr-flows-ms70.Rds")
    }
}

if (!file.exists ("data/dodgr-exposure-ms.Rds"))
{
    ms <- readRDS ("data/osm-ms-highways.Rds")
    ms <- osm_poly2line (ms)

    # get OSM way IDs for Ring, which are all secondary
    index_ring <- which (grepl ("ring", ms$osm_lines$name, ignore.case = TRUE) &
                         ms$osm_lines$highway == "secondary")
    index_sg <- which (grepl ("am stadtgraben", ms$osm_lines$name, ignore.case = TRUE) &
                       ms$osm_lines$highway == "primary")
    index_sp <- which (grepl ("schlossplatz", ms$osm_lines$name, ignore.case = TRUE) &
                       ms$osm_lines$highway == "primary")
    index_nt <- which (grepl ("neutor", ms$osm_lines$name, ignore.case = TRUE) &
                       ms$osm_lines$highway == "primary")
    index_st <- which (grepl ("steinfurter", ms$osm_lines$name, ignore.case = TRUE) &
                       ms$osm_lines$highway == "primary")
    index_s <- unique (c (index_sg, index_sp, index_nt, index_st))
    ids_ring <- ms$osm_lines$osm_id [index_ring]
    ids_s <- ms$osm_lines$osm_id [unique (c (index_sg, index_sp, index_nt, index_st))]

    # functions from flowlayers:
    dist_to_lonlat_range <- function (verts, d = 20)
    {
        xy0 <- c (mean (verts$x), mean (verts$y))
        names (xy0) <- c ("x", "y")
        minf <- function (a, xy0) { abs (geodist::geodist (xy0, xy0 + a) - d) }
        optimise (minf, c (0, 0.1), xy0)$minimum
    }

    disperse_flows <- function (graph, d = 20)
    {
        # This actually works by mapping flows to vertices, and then applying a
        # Gaussian kernel to those points, before re-mapping them back to edges
        v <- dodgr::dodgr_vertices (graph)
        sig <- dist_to_lonlat_range (v, d)

        indxf <- match (v$id, graph$from_id)
        indxt <- match (v$id, graph$to_id)
        indxf [is.na (indxf)] <- indxt [is.na (indxf)]
        indxt [is.na (indxt)] <- indxf [is.na (indxt)]
        v$flow <- apply (cbind (graph$flow [indxf], graph$flow [indxt]), 1, max)

        # warnings are issued here if any (x, y) are duplicated
        xy <- suppressWarnings (spatstat::ppp (v$x, v$y, range (v$x), range (v$y)))
        d <- spatstat::density.ppp (xy, weights = v$flow, sigma = sig, at = "points")
        vsum <- sum (v$flow)
        d <- d * vsum / sum (d)
        indx <- which (d > v$flow)
        v$flow [indx] <- d [indx]
        v$flow <- v$flow * vsum / sum (v$flow)

        # Then map those vertex values back onto the graph
        indxf <- match (graph$from_id, v$id)
        indxt <- match (graph$to_id, v$id)
        fmax <- apply (cbind (v$flow [indxf], v$flow [indxt]), 1, max)
        fsum <- sum (graph$flow)
        fmax <- fmax * fsum / sum (graph$flow)
        indx <- which (fmax > graph$flow)
        # That again imbalances the flow of the graph, so needs to be standardised
        # back to original sum again
        fsum <- sum (graph$flow)
        graph$flow [indx] <- fmax [indx]
        graph$flow <- graph$flow * fsum / sum (graph$flow)

        return (graph)
    }

    gv <- weight_streetnet (ms$osm_lines, wt_profile = "motorcar")
    rrr <- 4 
    # A random value to positively bias the outer Ring while negatively biasing
    # the inner city streets. This is a hack-job and implementing he effect of
    # traffic lights in the inner city.
    index <- match (ids_ring, gv$way_id)
    gv$d_weighted [index] <- gv$d [index] / rrr
    index <- match (ids_s, gv$way_id)
    gv$d_weighted [index] <- gv$d [index] * rrr
    gc <- dodgr_contract_graph (gv)
    v <- dodgr_vertices (gc$graph)
    pts <- sample (v$id, size = 1000)
    message ("aggregating vehicular flows ... ", appendLF = FALSE)
    fv <- dodgr_flows_aggregate (gv, from = pts, to = pts,
                                 flow = matrix (1, nrow = 1000, ncol = 1000))
    message ("done\ndispersing ... ", appendLF = FALSE)
    fvd <- disperse_flows (fv, 20) %>%
        merge_directed_flows ()
    fv <- merge_directed_flows (fv)
    message ("done")

    f <- readRDS ("data/dodgr-flows-ms70.Rds") %>%
        merge_directed_flows ()
    f <- f [which (f$edge_id %in% fvd$edge_id), ]
    indx1 <- match (f$edge_id, fvd$edge_id)
    indx2 <- match (fvd$edge_id [indx1], f$edge_id)
    f$flow <- f$flow / max (f$flow)
    fvd$flow <- fvd$flow / max (fvd$flow)
    f$flow <- f$flow * fvd$flow [indx1] [indx2]
    saveRDS (f, file = "data/dodgr-exposure-ms.Rds")
}
