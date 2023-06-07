library(sf)
library(here)
library(rajudas)
library(tidyverse)
library(lwgeom)
library(glue)
library(geojsonio)


# path in -----------------------------------------------------------------
pathIn = here("data_raw/OGDEXT_GEM_1_STATISTIK_AUSTRIA_20230101/STATISTIK_AUSTRIA_GEM_20230101.shp")


# data -------------------------------------------------------------------
data = read_sf(pathIn) %>% st_transform(4326)

# split data --------------------------------------------------------------
dataEachGem = split(data, data$g_id)

# how squary --------------------------------------------------------------
shares = map(seq_along(dataEachGem), function(i){
  cat(i, "/", length(dataEachGem), "\r")

  #id
  gem = dataEachGem[[i]]
  id = gem$g_id
  areaGem = st_area(gem)

  # rectangle ---------------------------------------------------------------
  # bounding box
  bb = st_bbox(gem) %>% st_as_sfc()
  # areas
  areaBB = st_area(bb)
  # how much area of the bb is covered by the shape?
  shareSquare = areaGem / areaBB


  # minimum enclosing circle ------------------------------------------------
  minimumCircle = st_minimum_bounding_circle(gem)
  areaMinimumCircle = st_area(minimumCircle)
  shareCircle = areaGem / areaMinimumCircle


  # paths -------------------------------------------------------------------
  opGem = makePath(here(glue("../../../js/2023/svelte/squaryGemeinden/src/assets/data/gemeinden/json/{id}.geojson")))
  opBB = makePath(here(glue("../../../js/2023/svelte/squaryGemeinden/src/assets/data/gemeinden/json/{id}_bb.geojson")))
  opCircle = makePath(here(glue("../../../js/2023/svelte/squaryGemeinden/src/assets/data/gemeinden/json/{id}_circle.geojson")))

  opGemTopo = makePath(here(glue("../../../js/2023/svelte/squaryGemeinden/src/assets/data/gemeinden/topojson/{id}.json")))
  opBBTopo = makePath(here(glue("../../../js/2023/svelte/squaryGemeinden/src/assets//data/gemeinden/topojson/{id}_bb.json")))
  opCircleTopo = makePath(here(glue("../../../js/2023/svelte/squaryGemeinden/src/assets/data/gemeinden/topojson/{id}_circle.json")))

  if(!file.exists(opGem)){
    write_sf(gem, opGem)
    write_sf(bb, opBB)
    write_sf(minimumCircle, opCircle)

    topojson_write(gem, file=opGemTopo, overwrite = T)
    topojson_write(bb, file=opBBTopo)
    topojson_write(minimumCircle, file=opCircleTopo)

  }

  l = list(
    name = gem$g_name,
    id = id,
    shareBB = shareSquare,
    shareCircle = shareCircle
  )

  return(l)

})



# make index object -------------------------------------------------------
library(jsonlite)
js = toJSON(data %>% st_drop_geometry(), pretty = T)
opJSON = "../../../js/2023/svelte/squaryGemeinden/static/data/gemeindenList.json"
write(js, opJSON)
















