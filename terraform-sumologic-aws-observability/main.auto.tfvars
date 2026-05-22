####### BELOW ARE REQUIRED PARAMETERS FOR TERRAFORM SCRIPT #######
# Visit - https://help.sumologic.com/Solutions/AWS_Observability_Solution/03_Set_Up_the_AWS_Observability_Solution#sumo-logic-access-configuration-required
sumologic_environment     = "stag"                                                             # Please replace <YOUR SUMO DEPLOYMENT> (including brackets) with au, ca, ch, de, eu, esc, jp, us2, kr, fed or us1.
sumologic_access_id       = "su1l9BLvK1YI4o"                                                   # Please replace <YOUR SUMO ACCESS ID> (including brackets) with your Sumo Logic Access ID.
sumologic_access_key      = "J8VaDSz3b6n8LLwprz7lXJCX1mo9TQhdSLiG4qsh9tkI10tIV7qEXTlmQVb6UEYa" # Please replace <YOUR SUMO ACCESS KEY> (including brackets) with your Sumo Logic Access KEY.
sumologic_organization_id = "0000000000000475"                                                 # Please replace <YOUR SUMO ORG ID> (including brackets) with your Sumo Logic Organization ID.
aws_account_alias         = "akhil3x"
sumologic_environment_base_url = "https://stag-api.sumologic.net/api/" # Please replace <YOUR AWS ACCOUNT ALIAS> with an AWS account alias for identification in Sumo Logic Explorer View, metrics and logs.