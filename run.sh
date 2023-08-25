#!/bin/bash

set -e

#######################################
# Section 1: Setup Docker container
#######################################

image_name="osrm-backend-custom"
image_tag="latest"
read -p "Enter the URL of the pbf file to download (empty allowed):[IRAN] " file_url

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
    docker compose build
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

sleep 5

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

origin="51.42838,35.80697"
destination="51.42088,35.68590"

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
done
