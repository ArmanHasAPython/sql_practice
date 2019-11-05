#!/bin/bash

echo "Start downloading data"

# make raw_data dir
mkdir raw_data

# create raw_data/ README
echo $'# Raw Data\n\nThis directory will store raw data.\n' > raw_data/README.md

# make write_data dir
mkdir write_data

# create write_data/ README
echo $'# Write Data\n\nThis directory will store data created by us.\n' > write_data/README.md

# switch into the raw_data dir
cd raw_data/

# download 2017 IL jobs data
wget https://lehd.ces.census.gov/data/lodes/LODES7/il/wac/il_wac_S000_JT00_2017.csv.gz

# decompress the 2017 IL jobs data
# note: this will delete the original .csv.gz file
gunzip il_wac_S000_JT00_2017.csv.gz

# download 2017 IL jobs geographic crosswalk file
wget https://lehd.ces.census.gov/data/lodes/LODES7/il/il_xwalk.csv.gz

# decompress the 2017 IL jobs crosswalk file
# note: this will delete the original .csv.gz file
gunzip il_xwalk.csv.gz

# download CPS SY1819 profiles
wget https://github.com/cenuno/exploring_chicago_data/raw/master/write_data/cps_sy1819_cca.csv

# download CPS dropout data
wget -O cps_dropout_rate_2011_2019.xls https://cps.edu/Performance/Documents/DataFiles/Metrics_CohortGraduationDropoutAdjusted_SchoolLevel_2011to2019.xls

# transform the second sheet into a .csv file
# note: due to the way the .xls file is organized, there are redundant
#       column names. Ignore the warning messages.
in2csv cps_dropout_rate_2011_2019.xls --sheet="School 5 Year Cohort Rates" \
--skip-lines=2 | csvcut -c 1,2,3,4,5,6,7,8,9,10,11,12 \
> cps_dropout_rate_2011_2019.csv

# transform the dropout rate data from wide to long
python ../python/reshape_dropout.py

# download Chicago 2019 crimes
wget -O crimes_2019.csv https://data.cityofchicago.org/api/views/w98m-zvie/rows.csv?accessType=DOWNLOAD

# download 2010 chicago census tracts
wget -O census_tracts_2010.csv https://data.cityofchicago.org/api/views/74p9-q2aq/rows.csv?accessType=DOWNLOAD

# download current chicago community areas
wget -O community_areas.csv https://data.cityofchicago.org/api/views/igwz-8jzy/rows.csv?accessType=DOWNLOAD

# download chicago food inspection file
wget -O food_inspections.csv https://data.cityofchicago.org/api/views/4ijn-s7e5/rows.csv?accessType=DOWNLOAD

# add all the .csv files to one SQLite database
csvs-to-sqlite il_wac_S000_JT00_2017.csv il_xwalk.csv census_tracts_2010.csv \
../write_data/cps_dropout_rate_2011_2019.csv \
crimes_2019.csv food_inspections.csv community_areas.csv \
cps_sy1819_cca.csv ../write_data/chicago.db

# switch to write_data/ dir
cd ../write_data/

# create a new psql database
createdb chicago

# transfer SQLite database to the chicago PostgreSQL database
pgloader chicago.db postgresql:///chicago

echo "Finished downloading data"
