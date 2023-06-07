library(here)
library(glue)
library(tidyverse)
library(jsonlite)


# dir ---------------------------------------------------------------------
dirI = here("data_raw/gemeinden/")
files = dir(dirI, "*", full.names = T, recursive = T)


# csv ---------------------------------------------------------------------
csvs = str_subset(files, ".*\\.csv")

# read data ---------------------------------------------------------------

# one df for each country.
# rows are gemeinden, ids, and shares
dfs = map(csvs, read_csv)

# bind all together
dfAll = bind_rows(dfs)



# make one files for the countries ----------------------------------------
countries = dfAll %>% group_by(country_id) %>% slice_head(n=1) %>% select(country_id)
jsonCountries = toJSON(countries)


countriesEU = giscoR::gisco_get_countries(region = "Europe") %>% select(country_id = CNTR_ID, country_name = CNTR_NAME) %>% st_drop_geometry()
jsonCountries = toJSON(countriesEU)

opJsonCountries = "../../../js/2023/svelte/squaryGemeinden/src/assets/data/countries.json"
write(jsonCountries, opJsonCountries)


# make one json for each country ------------------------------------------
dfAll %>% split(.$country_id) %>% iwalk(function(d, c){

  print(glue("Writing: {c}"))

  d = d %>% select(gem_id, country_id, name)

  jsonCountry = toJSON(d, pretty = T)
  opJsonCountry = glue("../../../js/2023/svelte/squaryGemeinden/static/data/{c}.json")
  unlink(opJsonCountry)
  write(jsonCountry, opJsonCountry)


})










