library(giscoR)
library(sf)
library(here)
library(glue)
library(rajudas)
library(lwgeom)
library(geojsonio)
library(tidyverse)
library(eurostat)
library(googleLanguageR)
googleLanguageR::gl_auth("~/.ssh/googletranslate.json")


# download eu countries ---------------------------------------------------
eu_countries = eurostat::get_eurostat_geospatial()

# only get nuts level 0 ---------------------------------------------------
eu = eu_countries %>%
  filter(
    LEVL_CODE == 0
  ) %>% janitor::clean_names()



# get only eu countries ---------------------------------------------------
eu_27 = eurostat::eu_countries

eu_27_geo = left_join(eu_27, eu, join_by(code == id)) %>%
  st_as_sf()


# split countries ---------------------------------------------------------
countriesEUSplit = split(eu_27_geo, eu_27_geo$code)


# set cache dir
force = F
baseDir = here("data_raw/lau/")

walk(seq_along(countriesEUSplit), function(i) {
  cat(i, "/", length(countriesEUSplit), "\r")

  country = countriesEUSplit[[i]]
  countryId = names(countriesEUSplit)[[i]]

  # download the communes
  print(glue("Downloading for: {countryId}"))

  op = makePath(here(
    glue(
      "data_raw/gisco/communes/{countryId}/{countryId}_communes.fgb"
    )
  ))
  if (!file.exists(op) | force) {
    unlink(op)
    communes = giscoR::gisco_get_communes(country = countryId,
                                          epsg = "3035") %>% janitor::clean_names()
    st_write(communes, op)
  } else{
    communes = read_sf(op)
  }


  # split country
  communsSplit = split(communes, communes[["id"]])

  dirCountry = here(baseDir, glue("{countryId}"))
    shares = map(seq_along(communsSplit), function(j) {


      #id
      gem = communsSplit[[j]] %>% mutate(type="gem") %>% st_transform(3857)
      id = gem$id[[1]]

        path = makePath(here(baseDir,
                             glue("{countryId}/{id}")))

        pathGeoJson = glue("{path}.geojson")

        if(file.exists(pathGeoJson)) return()

      # rename the geometry column to x
      idx_geom_col = which(str_detect(map(gem, ~class(.x)[[1]]) %>% unlist, "sf"))
      st_geometry(gem) = "x"

      # the area of the gemeinde
      areaGem = st_area(gem)

      # rectangle ---------------------------------------------------------------
      # bounding box
      bbCoords = st_bbox(gem)
      bb = bbCoords %>% st_as_sfc() %>% st_as_sf() %>% mutate(type="bb")
      bbWidth = bbCoords[4] - bbCoords[2]
      bbHeight = bbCoords[3] - bbCoords[1]
      bbAspectRatio =   bbHeight / bbWidth


      # areas
      areaBB = st_area(bb)
      # how much area of the bb is covered by the shape?
      shareSquare = as.numeric(areaGem / areaBB)


      # minimum enclosing circle ------------------------------------------------
      minimumCircle = st_minimum_bounding_circle(gem) %>% st_geometry() %>% st_as_sf() %>% mutate(type="circle")
      areaMinimumCircle = st_area(minimumCircle)
      shareCircle = as.numeric(areaGem / areaMinimumCircle)


      # make one bb for all the featues -----------------------------------------
      bbGeom = st_geometry(bb) %>% st_as_sf()
      circleGeom = st_geometry(minimumCircle) %>% st_as_sf()
      circleBB = bind_rows(bbGeom, circleGeom) %>% st_union() %>% st_as_sf() %>% mutate(type="all")



      dfAll = bind_rows(
        gem = gem,
        bb = bb,
        circle = minimumCircle,
        all = circleBB
      ) %>%
        tidyr::fill(names(.)) %>% st_transform(4326)


      dfAll  = dfAll %>%
        select(id,
               comm_id,
               comm_name,
               type) %>%
        mutate(shareBB = shareSquare,
               shareCircle = shareCircle,
               bbWidth,
               bbHeight)

        # unlink(pathGeoJson)
        write_sf(dfAll, pathGeoJson)


    })

})
