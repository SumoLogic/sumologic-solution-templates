#!/bin/bash
set -e

###############################################################################
# This script creates a tarball that is meant to be used by users who need to
# quickly get the GitHub apps and supporting collectors, FERs, and webhooks set
# up without manual modification. The tarball can be downloaded and quickly
# used by the user.
#
# The tarball contains terraform code as well as helper artifacts such as
# scripts.  This script modifies the existing SDO terraform script to just
# install the GitHub app catalog app, FERs, and GitHub webhooks. No other dev
# tools applications, including SDO, will be enabled.
#
#### ARGUMENTS #####
# This script accepts zero or one arguments which determines the version string
# used in creating the resulting tarball. If no arguments are given, the commit
# sha of the head commit is used as the version string. If one argument is given
# the argument's value will be used as the version string
###############################################################################

## SETTINGS ####################
pkg_base_directory=pkg2/github
tmp_build_directory=/tmp/github
################################

# This function sets variable values in the sumollogic.auto.tfvars file.
# It accepts exactly two arguments
#  1st - the name of the variable to set
#  2nd - the value of the variable
update_sumo_setting () {
  setting=$1
  value=$2

  setting_string=`grep "^$setting\s.*" $pkg_base_directory/sumologic.auto.tfvars`
  if [ "$setting_string" == "" ]; then
    echo "Could not find setting $setting in sumologic.auto.tfvars"
    exit 1
  fi

  new_string=`echo "$setting_string" | sed "s/\".*\"/\"$value\"/"`

  sed  -i "" "s/$setting_string/$new_string/" $pkg_base_directory/sumologic.auto.tfvars
}

## Prepare 
rm -rf $pkg_base_directory
mkdir -p $tmp_build_directory

parent_directory=`dirname $pkg_base_directory`
mkdir -p $parent_directory

# If an argument is passed to this
# script, use that as the version
# otherwise use the head commit
if [ "$1" != "" ]; then
  version="$1"
else
  version=`git rev-parse --short HEAD`
fi

## Build GitHub package
cp -a . $tmp_build_directory

mv $tmp_build_directory $pkg_base_directory

# This is only temporarily necessary
# Once the bug that prevents TF
# to run without a gitlab token
# is fixed, this can be removed
rm -rf $pkg_base_directory/gitlab.tf

update_sumo_setting install_jira_cloud          "none"
update_sumo_setting install_jira_server         "none"
update_sumo_setting install_bitbucket_cloud     "none"
update_sumo_setting install_opsgenie            "none"
update_sumo_setting install_pagerduty           "none"
update_sumo_setting install_github              "all"
update_sumo_setting install_gitlab              "none"
update_sumo_setting install_jenkins             "none"
update_sumo_setting install_sdo                 "none"
update_sumo_setting install_circleci_SDO_plugin "none"
update_sumo_setting install_circleci            "none"
update_sumo_setting install_sumo_to_opsgenie_webhook        "false"
update_sumo_setting install_sumo_to_jiracloud_webhook       "false"
update_sumo_setting install_sumo_to_jiraserver_webhook      "false"
update_sumo_setting install_sumo_to_jiraservicedesk_webhook "false"
update_sumo_setting install_sumo_to_pagerduty_webhook       "false"

tar -czf  "$parent_directory/github-${version}.tar.xzf" $pkg_base_directory

## Cleanup
rm -rf $pkg_base_directory
