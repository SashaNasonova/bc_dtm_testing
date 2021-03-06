# Copyright 2021 Province of British Columbia
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.


library(raster)
library(sf)
library(bcdata)
library(bcmaps)
library(dplyr)
library(rvest)


## Load in eDTM layer (from sync location)

data.dir <- "D:/Hengle_BCDEM30/Output"

data.files <- list.files(data.dir)

edtm <- raster(file.path(data.dir, data.files[1])) %>%

  
  

# download point data from geodetics survey
  geopt <- 
  "https://catalogue.data.gov.bc.ca/dataset/2edb1fd0-0767-44ac-be1d-57085c722922
    
  
  
  
  
  
  
  
  

  
  
  
# Function to read in CDED DATA     


#### SET: CACHE FOLDER ####
cachedir = "C:/Users/bevin/BCMAPSCACHE_DEM2/"
dir.create(cachedir)

#### SET: PROJECT FOLDER ####
projdir = "C:/Users/bevin/MyProjectFolder/"
dir.create(projdir)
filename = "PG_DEM_MOSAIC"

#### DEFINE YOUR AREA OF INTEREST AOI ####
my_aoi <- bcmaps::bc_cities() %>% filter(NAME == "Prince George") %>% st_buffer(5000)

##### DEFINE DOWNLOAD AND MOSAIC FUNCTION ####
cded <- function(my_aoi, 
                 cachefolder,
                 projectfolder,
                 exportname) {
  
  # CREATE CACHE DIRECTORY
  dir.create(cachefolder, showWarnings = F)
  # TILES THAT INTERSECT MY_AOI
  my_tiles <- bcdc_query_geodata("c50803db-7645-4da8-bce5-1bc5b501a7b3") %>% 
    dplyr::filter(INTERSECTS(my_aoi)) %>%
    collect()
  write_sf(my_tiles, "C:/Users/bevin/250.sqlite")
  print(paste("There area a total of", nrow(my_tiles), "250k tiles"))
  
  # GET LIST OF TILE NAMES
  my_tile_list <- my_tiles$MAP_TILE_DISPLAY_NAME
  
  # GET LINKS PER MAP SHEET
  vrtlist <- lapply(1:length(my_tile_list), function(j){
    # GET TILENAME OF INTEREST
    tilename=my_tile_list[j]
    # CREATE OUTPUT FOLDER FOR TILE
    dir.create(paste0(cachefolder, tilename), showWarnings = F)
    # MAKE LIST OF EXISTING TILES IN 
    tile_files <- list.files(paste0(cachefolder, tilename))
    
    #### HTTP STUFF ####
    
    # MAP SHEET FOLDER
    URL <- paste0("https://pub.data.gov.bc.ca/datasets/175624/",tilename,"/")
    # READ PAGE
    PAGE <- html_attr(html_nodes(read_html(URL), "a"), "href")
    # LIST OF ZIP
    LIST <- PAGE[grep(pattern = "dem.zip$", x = PAGE)]
    # LIST OF ZIP URLS
    ZIPS <- paste0(URL,LIST)
    
    #### DOWNLOAD MAGIC ####
    
    # DONWLOAD LIST
    subvrtlist <- lapply(1:length(LIST), function(i){
      if(sub(pattern = ".dem.zip", replacement = ".tif", LIST[i]) %in% tile_files){
        print(paste(tilename, "[", j, "of", nrow(my_tiles), "250k tiles ]", "start", i, "of", length(LIST), "files", "ALREADY EXISTS"))
        tile <- sub(".dem", ".tif", sub(".zip", "", paste0(cachefolder,tilename, "/", LIST[i])))
        tile
      }else{
        print(paste(tilename, "[", j, "of", nrow(my_tiles), "250k tiles ]", "start", i, "of", length(LIST), "files", "DOWNLOADING"))
        # Download
        download.file(ZIPS[i], destfile = paste0(cachefolder, tilename, "/", LIST[i]), quiet = T)
        # UNZIP
        unzip(paste0(cachefolder,tilename, "/", LIST[i]), exdir = paste0(cachefolder,tilename))
        # REMOVE ZIP
        file.remove(paste0(cachefolder,tilename, "/", LIST[i]))
        # TRANSLATE .DEM to .TIF
        sf::gdal_utils(util = "translate", 
                       source = sub(".zip", "", paste0(cachefolder,tilename, "/", LIST[i])), 
                       destination = sub(".dem", ".tif", sub(".zip", "", paste0(cachefolder,tilename, "/", LIST[i]))), 
                       options = c("-ot","Int16", 
                                   "-of", "GTiff"))
        # REMOVE .DEM
        file.remove(sub(".zip", "", paste0(cachefolder,tilename, "/", LIST[i])))
        
        tile <- sub(".dem", ".tif", sub(".zip", "", paste0(cachefolder,tilename, "/", LIST[i])))
        tile
      }})
    
    print(paste(round(100*j/nrow(my_tiles),0),"%"))    
    
    do.call(rbind, subvrtlist)
  })
  
  vrtlist <- do.call(rbind, vrtlist)
  
  # VRT of ALL VRTS  
  sf::gdal_utils(util = "buildvrt", 
                 source = vrtlist[,1], #list.files(path = paste0(cachefolder), pattern = "*.vrt$", full.names = T, recursive = F), 
                 destination = paste0(projectfolder,exportname, ".vrt"))
  
}  

#### OPTIONAL: BUILD OVERVIEWS FOR SPEED IN QGIS / ARCGIS #### 
# Takes time, but very helpful for pan/zoom speed 
#gdalUtils::gdaladdo(paste0(dir_proj,"/",filename, ".vrt"), levels = c(2,8,16))

#### RUN FUNCTION ####
system.time(cded(my_aoi = my_aoi,
                 cachefolder = cachedir,
                 projectfolder = projdir,
                 exportname = filename))


#### READ OUTPUT RASTER ####
system.time(dem <- stars::read_stars(paste0(projdir,"/",filename,".vrt"), proxy = T))

#### PLOT OUTPUT RASTER ####
system.time(plot(dem))








               