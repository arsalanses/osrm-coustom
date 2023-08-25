FROM osrm/osrm-backend:v5.25.0

ARG OSM_FILE=custom-latest.osm.pbf
ARG OSRM_FILE=custom-latest.osrm

ENV OSM_FILE=$OSM_FILE
ENV OSRM_FILE=$OSRM_FILE

COPY ./$OSM_FILE data/

RUN osrm-extract -p /opt/foot.lua data/$OSM_FILE
RUN osrm-partition data/$OSRM_FILE
RUN osrm-customize data/$OSRM_FILE

EXPOSE 5001

CMD osrm-routed --algorithm mld data/$OSRM_FILE
