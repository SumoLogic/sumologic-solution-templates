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
./scripts/update_sdo_variable deployment $sumologic_deployment_region

# Make sure we only have to deal with lowercase region values
sumologic_deployment_region=`echo "$sumologic_deployment_region" | awk '{print tolower($0)}'`

case $sumologic_deployment_region  in
  "us1")
    sumologic_api_endpoint="https://service.sumologic.com"
    ;;
  "us2")
    sumologic_api_endpoint="https://service.us2.sumologic.com"
    ;;
  "jp")
    sumologic_api_endpoint="https://service.jp.sumologic.com"
    ;;
  "in")
    sumologic_api_endpoint="https://service.in.sumologic.com"
    ;;
  "fed")
    sumologic_api_endpoint="https://service.fed.sumologic.com"
    ;;
  "eu")
    sumologic_api_endpoint="https://service.eu.sumologic.com"
    ;;
  "de")
    sumologic_api_endpoint="https://service.de.sumologic.com"
    ;;
  "ca")
    sumologic_api_endpoint="https://service.ca.sumologic.com"
    ;;
  "au")
    sumologic_api_endpoint="https://service.au.sumologic.com"
    ;;
esac

./scripts/update_sdo_variable sumo_api_endpoint $sumologic_api_endpoint
