# Script to open mapdeck tabs for actual presentation
library (mapdeck)
set_token (Sys.getenv ("MAPBOX_TOKEN"))

plot1map <- function (f)
{
    if (is.character (f)) # name of file
    {
        f <- readRDS (f)
        f <- dodgr::merge_directed_flows (f)
    }
    library (mapdeck)
    f$flow <- 20 * f$flow / max (f$flow)
    pal <- colorRampPalette (c ("lawngreen", "red"))
    loc <-  c (7.619786, 51.962)
    mapdeck (style = 'mapbox://styles/mapbox/dark-v9',
             pitch = 0,
             zoom = 14,
             location = loc) %>%
    add_line (data = f,
              layer_id = "ms-highways",
              origin = c("from_lon", "from_lat"),
              destination = c("to_lon", "to_lat"),
              stroke_colour = "flow",
              stroke_width = "flow",
              palette = pal)
}

plot1map ("data/dodgr-flows-ms70.Rds")
plot1map ("data/dodgr-exposure-ms.Rds")
