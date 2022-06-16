# common fields
resource "sumologic_field" "account" {
    data_type  = "String"
    field_name = "account"
    state      = "Enabled"
}

# common fields
resource "sumologic_field" "region" {
    data_type  = "String"
    field_name = "region"
    state      = "Enabled"
}

# common fields
resource "sumologic_field" "accountid" {
    data_type  = "String"
    field_name = "accountid"
    state      = "Enabled"
}

# common fields
resource "sumologic_field" "namespace" {
    data_type  = "String"
    field_name = "namespace"
    state      = "Enabled"
}

# Used in ALB
resource "sumologic_field" "loadbalancer" {
    data_type  = "String"
    field_name = "loadbalancer"
    state      = "Enabled"
}

# Used in Classic LB
resource "sumologic_field" "loadbalancername" {
    data_type  = "String"
    field_name = "loadbalancername"
    state      = "Enabled"
}

# Used in API gateway
resource "sumologic_field" "apiname" {
    data_type  = "String"
    field_name = "apiname"
    state      = "Enabled"
}

# Used in DynamoDB
resource "sumologic_field" "tablename" {
    data_type  = "String"
    field_name = "tablename"
    state      = "Enabled"
}

# Used in EC2
resource "sumologic_field" "instanceid" {
    data_type  = "String"
    field_name = "instanceid"
    state      = "Enabled"
}

# Used in ECS
resource "sumologic_field" "clustername" {
    data_type  = "String"
    field_name = "clustername"
    state      = "Enabled"
}

# Used in Elasticache
resource "sumologic_field" "cacheclusterid" {
    data_type  = "String"
    field_name = "cacheclusterid"
    state      = "Enabled"
}

# Used in Lambda
resource "sumologic_field" "functionname" {
    data_type  = "String"
    field_name = "functionname"
    state      = "Enabled"
}

# Used in NLB
resource "sumologic_field" "networkloadbalancer" {
    data_type  = "String"
    field_name = "networkloadbalancer"
    state      = "Enabled"
}

# Used in RDS
resource "sumologic_field" "dbidentifier" {
    data_type  = "String"
    field_name = "dbidentifier"
    state      = "Enabled"
}

# Used in SNS
resource "sumologic_field" "topicname" {
    data_type  = "String"
    field_name = "topicname"
    state      = "Enabled"
}