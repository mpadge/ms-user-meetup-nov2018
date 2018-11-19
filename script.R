library (osmdata)
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
