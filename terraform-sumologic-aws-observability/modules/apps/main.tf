resource "sumologic_app" "apps" {
  for_each = {
    for app in local.installation_apps_list : app.name => app
  }
  uuid    = each.value.uuid
  version = each.value.version
  parameters = each.value.parameters
}

# ********************** Create Explore Hierarchy ********************** #
resource "sumologic_hierarchy" "awso_hierarchy" {
  name = "AWS Observability"
  level {
    entity_type = "account"
    next_level {
      entity_type = "region"
      next_level {
        entity_type = "namespace"
        next_levels_with_conditions {
          condition = "AWS/ApplicationElb"
          level {
              entity_type = "loadbalancer"
            }
          }
        next_levels_with_conditions {
          condition = "AWS/ApiGateway"
          level {
              entity_type = "apiname"
            }
          }
        next_levels_with_conditions {
          condition = "AWS/DynamoDB"
          level {
              entity_type = "tablename"
            }
          }
        next_levels_with_conditions {
          condition = "AWS/EC2"
          level {
              entity_type = "instanceid"
            }
          }
        next_levels_with_conditions {
          condition = "AWS/RDS"
          level {
              entity_type = "dbidentifier"
            }
          }
        next_levels_with_conditions {
          condition = "AWS/Lambda"
          level {
              entity_type = "functionname"
            }
          }
        next_levels_with_conditions {
          condition = "AWS/ECS"
          level {
              entity_type = "clustername"
            }
          }
        next_levels_with_conditions {
          condition = "AWS/ElastiCache"
          level {
              entity_type = "cacheclusterid"
            }
          }
        next_levels_with_conditions {
          condition = "AWS/ELB"
          level {
              entity_type = "loadbalancername"
            }
          }
        next_levels_with_conditions {
          condition = "AWS/NetworkELB"
          level {
              entity_type = "networkloadbalancer"
            }
          }
        next_levels_with_conditions {
          condition = "AWS/SNS"
          level {
              entity_type = "topicname"
            }
          }
        next_levels_with_conditions {
          condition = "AWS/SQS"
          level {
              entity_type = "queuename"
            }
          }
      }
    }
  }
}