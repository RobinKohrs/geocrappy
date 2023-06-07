library(googleCloudStorageR)
library(tidyverse)
library(glue)
library(here)

gcs_auth(json_file = "~/.ssh/googletranslate.json")
gcs_global_bucket("gdatark")
bucket_info = gcs_get_bucket("gdatark")


# upload all the geodata --------------------------------------------------
dirGeo = here("data_raw/gemeinden")

all = dir(dirGeo, "*", full.names = T, recursive = T) %>% str_subset("geojson|csv")
# all = all %>% str_subset("AT")

writtenFilesPath = here("currentFile.txt")
writtenFiles = readLines(writtenFilesPath)

walk(seq_along(all), function(i) {
  cat(i, "/", length(all), "\r")
  p = all[[i]]
  fn = basename(p)
  if (i ==  1 && length(allFiles) == 0) {
    cat(glue("{fn}\n"), file = currentF, append = F)
  } else{
    cat(fn,
        file = currentF,
        sep = "\n",
        append = T)
  }
  name = str_match(p, "gemeinden/(.*)")[, 2]

  if (!fn %in% allFiles) {
    suppressMessages(gcs_upload(file = p, name = name))

  }
})









