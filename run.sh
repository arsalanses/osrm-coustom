#!/bin/bash

set -e

#######################################
# Section 1: Setup Docker container
#######################################

read -p "Enter the URL of the pbf file to download (empty allowed):[iran-latest.osm.pbf] " file_url

download_file() {
    if [ -n "$file_url" ]; then
        wget "$file_url" -O custom-latest.osm.pbf
        cp custom-latest.osm.pbf driving/
        cp custom-latest.osm.pbf foot/
        cp custom-latest.osm.pbf motorcycle/
    else
        wget "https://download.geofabrik.de/asia/iran-latest.osm.pbf" -O custom-latest.osm.pbf
        cp custom-latest.osm.pbf driving/
        cp custom-latest.osm.pbf foot/
        cp custom-latest.osm.pbf motorcycle/
    fi
}

build_image() {
    docker compose build osrm-driving
    docker compose build osrm-foot
    docker compose build osrm-motorcycle
}

run_container() {
    docker compose up -d --force-recreate
}

handle_error() {
    echo "An error occurred during the script execution."
    echo "Exiting..."
    exit 1
}

trap 'handle_error' ERR

echo "Downloading the file..."
download_file

echo "Starting the Docker build..."
build_image

echo "Starting the Docker container..."
run_container

#######################################
# Section 2: Send a Request to Backends
#######################################

if ! command -v jq &> /dev/null; then
    read -p "jq is required for this script. Do you want to install it?[apt] (y/n) " choice
    if [[ $choice == [Yy] ]]; then
        sudo apt-get install -y jq
    else
        echo "jq is not installed. Please install jq to continue."
        exit 1
    fi
fi

read -p "Enter the origin for OSRM (empty allowed):[51.42838,35.80697] " origin
read -p "Enter the destination for OSRM (empty allowed):[51.42088,35.68590] " destination

default_origin="51.42838,35.80697"
default_destination="51.42088,35.68590"

if [[ -z "$origin" ]]; then
    origin="$default_origin"
fi

if [[ -z "$destination" ]]; then
    destination="$default_destination"
fi

modes=("driving" "foot" "bike")
ports=("5000" "5001" "5002")

for ((i=0; i<${#modes[@]}; i++)); do
    mode="${modes[i]}"
    port="${ports[i]}"
    response=$(curl -s "http://127.0.0.1:$port/route/v1/driving/$origin;$destination?steps=false")

    distance=$(echo "$response" | jq -r '.routes[0].distance')
    duration=$(echo "$response" | jq -r '.routes[0].duration')

    echo "Transportation mode: $mode"
    echo "Distance: $distance meters"
    echo "Duration: $duration seconds"
    echo "-------------------------"

    echo "$origin;$destination" >> output.txt
    echo "Transportation mode: $mode" >> output.txt
    echo "Distance: $distance meters" >> output.txt
    echo "Duration: $duration seconds" >> output.txt
    echo "-------------------------" >> output.txt

done
