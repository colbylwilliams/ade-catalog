#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

set -e # exit on error

trace() {
    echo -e "\n>>> $@ ..."
}

echo ""
echo "========================================"
echo "Running custom deploy script for Storage"
echo "========================================"
echo ""

trace "Using the following environment varibles"

echo "ADE_ACTION_OUTPUT: $ADE_ACTION_OUTPUT"
echo "ADE_ENVIRONMENT_SUBSCRIPTION_ID: $ADE_ENVIRONMENT_SUBSCRIPTION_ID"
echo "ADE_ENVIRONMENT_RESOURCE_GROUP_NAME: $ADE_ENVIRONMENT_RESOURCE_GROUP_NAME"
echo "ADE_CATALOG_ITEM_TEMPLATE: $ADE_CATALOG_ITEM_TEMPLATE"
echo "ADE_ACTION_PARAMETERS: $ADE_ACTION_PARAMETERS"

echo ""

deploymentName=$(date +"%Y-%m-%d-%H%M%S")
echo "deploymentName: $deploymentName"

storageContainer="logs"
echo "storageContainer: $storageContainer"

trace "Getting storage account name from action parameters"

storageAccount=$(echo $ADE_ACTION_PARAMETERS | jq -r '.name' )
echo "storageAccount: $storageAccount"

trace "formatting the action parameters as arm parameters"
deploymentParameters=$(echo "$ADE_ACTION_PARAMETERS" | jq --compact-output '{ "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#", "contentVersion": "1.0.0.0", "parameters": (to_entries | if length == 0 then {} else (map( { (.key): { "value": .value } } ) | add) end) }' )

echo "deploymentParameters: $deploymentParameters"

trace "Deploying environment template $ADE_CATALOG_ITEM_TEMPLATE"
deploymentOutput=$(az deployment group create --name "$deploymentName" \
                                              --subscription "$ADE_ENVIRONMENT_SUBSCRIPTION_ID" \
                                              --resource-group "$ADE_ENVIRONMENT_RESOURCE_GROUP_NAME" \
                                              --template-file "$ADE_CATALOG_ITEM_TEMPLATE" \
                                              --parameters "$deploymentParameters" )
echo "$deploymentOutput"

trace "Sleeping for 10 seconds..."

sleep 10
echo "Resuming"

trace "Creating storage account container $storageContainer in $storageAccount"
containerOutput=$(az storage container create --name "$storageContainer" \
                                              --account-name "$storageAccount" \
                                              --only-show-errors )
echo "$containerOutput"

trace "Uploading log file to $storageAccount: $ADE_ACTION_OUTPUT"
blobOutput=$(az storage blob upload --file "$ADE_ACTION_OUTPUT" \
                                    --account-name "$storageAccount" \
                                    --container-name "$storageContainer" \
                                    --only-show-errors )
echo "$blobOutput"

echo -e "\nDone."
