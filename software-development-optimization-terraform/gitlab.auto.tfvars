# Sumo Logic - SDO Terraform
# Configure Gitlab credentials and parameters.

# https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html
# Please replace <YOUR GITLAB TOKEN> (including brackets) with your Github token.
gitlab_token               = "<YOUR GITLAB TOKEN>"

# Please replace <PROJECT1>, <PROJECT2> (including brackets) with your Gitlab projects. If no projects are mentioned, no projects webhooks are created.
# Examples: ["project1","project2"] or ["project1"]
gitlab_project_names    = ["<<PROJECT1>>","<<PROJECT2>>"]

# Set variable gitlab_project_webhook_create to true if you want to create webhook on the projects mentioned above. Possible values ar true or false.
gitlab_project_webhook_create  = "false"

# Set the build job name which you have provided in your .gitlab-ci.yml. You can also use wildcards to extract the build job names if you have multiple build jobs . 
# Default value set is *build* , which will consider all the jobs having build in their job names as build job.
gitlab_build_jobname = "*build*"
