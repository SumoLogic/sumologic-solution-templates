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
