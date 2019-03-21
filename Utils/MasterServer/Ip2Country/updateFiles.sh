#!/usr/bin/env bash
#wget software77.net/geo-ip/?DL=1 -O ./IpToCountry.csv.gz
#gunzip -c IpToCountry.csv.gz > ./IpToCountry.csv

cd /var/www/kamremake.com/public_html/Ip2Country/data
wget http://country.io/names.json -O ./names.json
wget http://85.214.138.234/Ip2Country/data/ip2country.dat -O ./ip2country.dat
wget http://85.214.138.234/Ip2Country/data/test.dat -O ./test.dat
