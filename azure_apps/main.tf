#
# The below module is used to install apps, metric rules, Field extraction rules, Fields and Monitors.
# NOTE - The "azure-app-modules" should be installed per Sumo Logic organization.
#
module "azure-apps-module" {
    source      = "./azure-apps-module"
    access_id   = var.sumologic_access_id
    access_key  = var.sumologic_access_key
    environment = var.sumologic_environment
}