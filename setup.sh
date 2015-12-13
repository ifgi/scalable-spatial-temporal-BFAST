#!/bin/bash
docker stop sstbfast1
docker rm sstbfast1
docker rmi sstbfast_img
docker build --rm=true --tag="sstbfast_img" .

docker run -d --name="sstbfast1" -p 49905:22 -p 49906:8083 --expose=5432 --expose=1239 --expose=8083 sstbfast_img


# docker run -d --name="sstbfast1" -p 49905:22 -p 49906:8083 --expose=5432 --expose=1239 --expose=8083 -v /data/bliss/MODIS/e4ftl01.cr.usgs.gov:/home/scidb/e4ftl01.cr.usgs.gov sstbfast_img
