# Sumo Logic - SDP Terraform
# Configure Github credentials and parameters.

# https://github.com/settings/tokens
github_token = "<YOUR GITHUB TOKEN>"  # Please replace <YOUR GITHUB TOKEN> (including brackets) with your Github token.
github_organization = "<YOUR GITHUB ORGANIZATION>"  # Please replace <YOUR GITHUB ORGANIZATION> (including brackets) with your Github organization.
github_repository_names = ["<REPOSITORY1>","<REPOSITORY2>"] # Please replace <REPOSITORY1>, <REPOSITORY2> (including brackets) with your Github repositories. If no repositories are mentioned, no repo webhooks are created.
github_org_webhook_create = "false"
github_repo_webhook_create = "true"

# https://docs.github.com/en/developers/webhooks-and-events/webhook-events-and-payloads
github_repo_events = ["check_run","check_suite","commit_comment","create","delete","deploy_key","deployment",
"deployment_status","fork",
"gollum","issue_comment","issues","label","member","meta","milestone","package","page_build","ping","project_card",
"project_column","project","public","pull_request","pull_request_review","pull_request_review_comment",
"push","release","repository","repository_import","repository_vulnerability_alert","star","status","team_add","watch"]

github_org_events = ["check_run","check_suite","commit_comment","create","delete","deploy_key","deployment",
"deployment_status","fork","gollum","issue_comment","issues","label","member",
"membership","meta","milestone","organization","org_block","package","page_build","ping","project_card",
"project_column","project","public","pull_request","pull_request_review","pull_request_review_comment",
"push","release","repository","repository_import","repository_vulnerability_alert","star","status","team","team_add","watch"]