#!/bin/bash
set -e

###############################################################################
# This script  is meant to be used by users who need to quickly get the GitHub
# apps and supporting collectors, FERs, and webhooks set up without manual
# modification. The script quickly updates all the dependent variables needed
# to install the GitHub app catalog app, the HTTP collectors, FERs, and
# organization wide webhooks in the customer's GitHub account.
################################

# This is only temporarily necessary
# Once the bug that prevents TF
# to run without a gitlab token
# is fixed, this can be removed
if [ -e gitlab.tf ]; then
  mv gitlab.tf gitlab.tf.bak
fi

./scripts/update_sdo_variable install_jira_cloud          "none"
./scripts/update_sdo_variable install_jira_server         "none"
./scripts/update_sdo_variable install_bitbucket_cloud     "none"
./scripts/update_sdo_variable install_opsgenie            "none"
./scripts/update_sdo_variable install_pagerduty           "none"
./scripts/update_sdo_variable install_github              "all"
./scripts/update_sdo_variable install_gitlab              "none"
./scripts/update_sdo_variable install_jenkins             "none"
./scripts/update_sdo_variable install_sdo                 "none"
./scripts/update_sdo_variable install_circleci_SDO_plugin "none"
./scripts/update_sdo_variable install_circleci            "none"
./scripts/update_sdo_variable install_sumo_to_opsgenie_webhook        "false"
./scripts/update_sdo_variable install_sumo_to_jiracloud_webhook       "false"
./scripts/update_sdo_variable install_sumo_to_jiraserver_webhook      "false"
./scripts/update_sdo_variable install_sumo_to_jiraservicedesk_webhook "false"
./scripts/update_sdo_variable install_sumo_to_pagerduty_webhook       "false"

echo "In order to configure GitHub to send data to Sumo Logic, a webhook will be automatically"
echo "created in your GitHub organization. Alternatively, you can manually configure github.auto.tfvars"
echo "to create the webhooks on specific repositories."
echo ""
echo "Your pesonal access token will need the following permissions:"
echo "  - read:org"
echo "  - admin:repo_hook"
echo "  - admin:org_hook"
echo ""
echo "Go here to learn more about creating a GitHub personal acess token: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token"
echo ""

echo -n "GitHub Access Token: "
github_access_token=""
read -r github_access_token
./scripts/update_github_variable github_token $github_access_token

echo -n "GitHub Organization name: "
github_org=""
read -r github_org
./scripts/update_github_variable github_organization $github_org

## Have the users set up the Sumo Logic access keys
./scripts/set-sumologic-access-keys.sh

## Finally, set up Terraform
./scripts/prep-local-terraform.sh
