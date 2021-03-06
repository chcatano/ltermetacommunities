#Aldo Compagnoni June 2018
#NKL added data provenance
rm(list = ls(all = T))
options(stringsAsFactors = F)
library(dplyr)
library(tidyr)
library(stringi)

# https://doi.org/10.6073/pasta/239b3023d75d83e795a15b36fac702e2

# field methods
# http://www.cedarcreek.umn.edu/research/data/methods?e014

# read data directly from the portal (no idea why this is not in popler.....)
cdr_raw <- read.csv('https://portal.lternet.edu/nis/dataviewer?packageid=knb-lter-cdr.106.8&entityid=3405c2e271929b0c537492a9ddde102b',
                sep = '\t') 

# clean up dataset
cdr     <- cdr_raw %>% 
            # create site information
            mutate( SITE_ID = as.character(Field.num),
                    yr_mon  = paste(Year,Month,sep='_') ) %>% 
            # select only sites with continuous data
            subset( !(SITE_ID == '28' | SITE_ID == '11') ) %>% 
            # aggregate by species/month
            group_by( Year, Month, SITE_ID, Order, Family, Genus, Specific.epithet) %>% 
            # sum across all months in a year. 
            # Sampling mostly consistent, excet for 2003, when June and August samples were lost in SOME fields
            summarise( count = sum(X.Specimens, na.rm=T) ) %>% 
            ungroup %>% 
            rename( genus   = Genus,
                    species = Specific.epithet ) %>% 
            mutate( species = replace(species, species == 'undet', 'spp.')) %>% 
  
            # Fix taxonomic information
            # species to "Lump" to genus (too high proportion of IDs at the genus level only)
            mutate( species = replace(species, genus == 'Conocephalus', 'spp.'),
                    species = replace(species, genus == 'Scudderia', 'spp.'),
                    species = replace(species, genus == 'Tetrix', 'spp.') ) %>% 
            # remove genus-level IDs for Melanopus
            subset( !(genus == 'Melanoplus' & species == 'spp.') )

# look up the taxonomy 
taxa <- cdr_raw %>% 
          group_by( Year, Month, Field.num, Order, Family, Genus, Specific.epithet) %>% 
          summarise( count = sum(X.Specimens, na.rm=T) ) %>% 
          ungroup %>% 
          rename( genus   = Genus,
                  species = Specific.epithet) %>% 
          mutate( species = replace(species, species == 'undet', 'spp.')) %>% 
          group_by(genus, species) %>%
          summarise(total = sum(count) ) %>% 
          as.data.frame %>% 
          arrange(genus, species)
          
 
# write file out
write.csv(cdr, '~/Google Drive File Stream/My Drive/LTER Metacommunities/LTER-DATA/L3-aggregated_by_year_and_space/L3-cdr-grasshopper-compagnoni.csv', row.names=F)

