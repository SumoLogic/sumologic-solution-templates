#This variable identifies Build Jobs in your CircleCI pipeline Code. It uses asterisks * as wildcards. The default value is *build*, which will consider all the jobs having "build" in their job names as The Build Job.
circleci_build_jobname = "*build*"
#This variable identifies Deploy Jobs in your CircleCI pipeline Code. It uses asterisks * as wildcards. The default value is *deploy*, which will consider all the jobs having "deploy" in their job names as the Deploy job.
circleci_deploy_jobname = "*deploy*"