####### BELOW ARE REQUIRED PARAMETERS FOR TERRAFORM SCRIPT #######
# Visit - https://help.sumologic.com/Solutions/AWS_Observability_Solution/03_Set_Up_the_AWS_Observability_Solution#sumo-logic-access-configuration-required
sumologic_environment     = "<YOUR SUMO DEPLOYMENT>"   # Please replace <YOUR SUMO DEPLOYMENT> (including brackets) with au, ca, de, eu, jp, us2, in, fed or us1.
sumologic_access_id       = "<YOUR SUMO ACCESS ID>"    # Please replace <YOUR SUMO ACCESS ID> (including brackets) with your Sumo Logic Access ID.
sumologic_access_key      = "<YOUR SUMO ACCESS KEY>"   # Please replace <YOUR SUMO ACCESS KEY> (including brackets) with your Sumo Logic Access KEY.
sumologic_organization_id = "<YOUR SUMO ORG ID>"       # Please replace <YOUR SUMO ORG ID> (including brackets) with your Sumo Logic Organization ID.
aws_account_alias         = "<YOUR AWS ACCOUNT ALIAS>" # Please replace <YOUR AWS ACCOUNT ALIAS> with an AWS account alias for identification in Sumo Logic Explorer View, metrics and logs.
sumologic_folder_installation_location = "<YOUR APP FOLDER LOCATION>" # Please replace <YOUR APP FOLDER LOCATION> with your preferred folder installation location, either of "Personal Folder" or "Admin Recommended Folder". Default is "Personal Folder".
sumologic_folder_share_with_org = true #Please replace true with false if you don't want to share content with the entire org.