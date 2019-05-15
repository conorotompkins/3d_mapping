library(rayshader)
library(geoviz)

#Set up the area you want to visualise (ggmap::geocode can help you do this straight from R but you'll need a Google API key)
lat <- 40.449828
long <- -79.944268
square_km <- 5

#Increase this to ~60 for a higher resolution (but slower) image
max_tiles <- 60

#Get elevation data from Mapzen
dem <- mapzen_dem(lat, long, square_km, max_tiles = max_tiles)

overlay_image <-
  slippy_overlay(
    dem,
    image_source = "stamen",
    image_type = "watercolor",
    png_opacity = 0.8,
    max_tiles = max_tiles
  )

# Or for a satellite image, use this block
# If you haven't got a mapbox key, go here first: https://docs.mapbox.com/help/glossary/access-token
mapbox_key <- "pk.eyJ1IjoiY29ub3JvdG9tcGtpbnMiLCJhIjoiY2p2b2MxeTNqMTg3ZjRhbnQwMTk0ZGt0ZyJ9.tfEDs2o7n8kKtHvcTneG_g"

#overlay_image <-
#  slippy_overlay(
#    dem,
#    image_source = "mapbox",
#    image_type = "satellite",
#    png_opacity = 0.6,
#    api_key = mapbox_key
#  )

sunangle <- 270

#Draw the rayshader scene
elmat = matrix(
  raster::extract(dem, raster::extent(dem), method = 'bilinear'),
  nrow = ncol(dem),
  ncol = nrow(dem)
)

scene <- elmat %>%
  sphere_shade(sunangle = sunangle, texture = "bw") %>%
  add_overlay(overlay_image) %>%
  #The next two lines create deep shadows but are slow to run at high quality
  add_shadow(
    ray_shade(
      elmat,
      anglebreaks = seq(30, 60),
      sunangle = sunangle,
      multicore = TRUE,
      lambert = FALSE,
      remove_edges = FALSE
    )
  ) %>%
  add_shadow(ambient_shade(elmat, multicore = TRUE, remove_edges = FALSE))

rayshader::plot_3d(
  scene,
  elmat,
  zscale = raster_zscale(dem),
  solid = FALSE,
  shadow = TRUE,
  shadowdepth = -150
)

rgl::view3d(theta = 90, phi = 20, zoom = 0.3, fov = 10)

rayshader::render_depth(
  focus = 0.5,
  fstop = 18,
  filename = "output/pgh.png"
)

save_3dprint("pgh_3d.stl", maxwidth = 2, unit = "in")
