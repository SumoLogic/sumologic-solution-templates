#!/bin/bash
set -e

echo "-----------------------------------------------------------"
echo "Please provide your Sumo Logic access ID and key. To create one,"
echo "follow the instructions here: https://help.sumologic.com/Manage/Security/Access-Keys#manage-all-users%E2%80%99-access-keys-on-access-keys-page"
echo ""

echo -n "Sumo Logic Access ID: "
sumologic_access_id=""
read -r sumologic_access_id
./scripts/update_sdo_variable sumo_access_id $sumologic_access_id

echo -n "Sumo Logic Access Key: "
sumologic_access_key=""
read -r sumologic_access_key
./scripts/update_sdo_variable sumo_access_key $sumologic_access_key

echo -n "Sumo Logic Deployment Region: "
sumologic_deployment_region=""
read -r sumologic_deployment_region
# Make sure we only have to deal with lowercase region values
sumologic_deployment_region=`echo "$sumologic_deployment_region" | awk '{print tolower($0)}'`
./scripts/update_sdo_variable deployment $sumologic_deployment_region

case $sumologic_deployment_region  in
  "us1")
    sumologic_api_endpoint="https://api.sumologic.com/api/"
    ;;
  "us2")
    sumologic_api_endpoint="https://api.us2.sumologic.com/api/"
    ;;
  "jp")
    sumologic_api_endpoint="https://api.jp.sumologic.com/api/"
    ;;
  "in")
    sumologic_api_endpoint="https://api.in.sumologic.com/api/"
    ;;
  "fed")
    sumologic_api_endpoint="https://api.fed.sumologic.com/api/"
    ;;
  "eu")
    sumologic_api_endpoint="https://api.eu.sumologic.com/api/"
    ;;
  "de")
    sumologic_api_endpoint="https://api.de.sumologic.com/api/"
    ;;
  "ca")
    sumologic_api_endpoint="https://api.ca.sumologic.com/api/"
    ;;
  "au")
    sumologic_api_endpoint="https://api.au.sumologic.com/api/"
    ;;
esac

./scripts/update_sdo_variable sumo_api_endpoint $sumologic_api_endpoint
