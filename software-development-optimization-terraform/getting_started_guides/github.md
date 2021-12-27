# Visualize GitHub Data in Sumo Logic - Quick Start Guide

This guide will walk you through creating a Sumo Logic account as well as
getting GitHub data visualized in Sumo Logic. At the end, you will have:

- A Sumo Logic trial account if you do not already have an existing account
- GitHub dashboards and data collection configured in your Sumo Logic account
- A GitHub webhook configured that will send data to your Sumo Logic account

For trial accounts, all of the data collected as a result from this guide will
be free of charge.

**Prerequisites** 

This guide will use a helper script to automate much of the setup process. The
following operating systems and architectures are supported:

- MacOS 64-bit Intel
- Linux 32-bit and 64-bit

Arm architectures for either Linux or Mac are not yet supported.

The scripts require the following system commands be available:
- curl
- unzip
- shasum 
- sed
- awk
- find
- grep

**Outcomes**
The scripts and Terraform code provided in this guide will have the following outcomes:

- You will be able to track data on pull requests, issues, branch development,
  and more across all GitHub repositories in your GitHub organization.
- A collection of GitHub dashboards will be installed in the folder "Software
  Development Optimization" within your Sumo Logic account.
- A single webhook will be added to your specified GitHub organization that
  will send events to Sumo Logic. You will provide a GitHub personal access
  token to be used to create the webhook.  The webhook can be removed at any
  time to stop sending data to Sumo Logic.
- A specific version of Terraform for your OS and architecture will be
  downloaded and be installed in isolation to the local working directory. It
  **will not** affect any existing system installations of Terraform.


# Steps

## Step 1 - Create a trial account
If you already have a Sumo Logic account, you can skip this step and go straight to step #2

1) Go to sumologic.com
2) Click on "Start free trial"

![](/resources/start-free-trial.png)

3) Provide your business email address
4) Select the deployment region closest to you. **Important: Remember your selection! You will need it later**
5) Agree to the Service License Agreement and click "Sign up"

6) Check your inbox for your verification email. Click "Activate account" to be taken to the last account setup page.

![](/resources/activate-sumo-trial-account.png)
7) Fill out the form and click "Activate"

![](/resources/activate-trial.gif)
8) Click the 'x' at the top right of the 'Welcome to Sumo Logic' web page. You will not need to follow the in-application guide for this gude.

Congratulations! You now have a trial account

## Step 2 - Create a Sumo Logic access key
In this step, you will create an access key to programatically manage your Sumo Logic account.

Follow the instructions here: [Manage all users’ access keys on Access Keys page](https://help.sumologic.com/Manage/Security/Access-Keys#manage-all-users%E2%80%99-access-keys-on-access-keys-page)

![](/resources/create-access-key.gif)

**Copy your access ID and key to another location. You will need them later**

## Step 3 - Create a GitHub personal access token

In order to create a webhook that will send data to your Sumo Logic account,
the automation in this guide will need an access token for your GitHub account.
Go to this page in your GitHub account to create one:
[](https://github.com/settings/tokens)

The access token will need the following permissions:

- read:org
- admin:repo_hook
- admin:org_hook

**Copy your access token to another location. You will need it later**

## Step 4 - Prepare the automation

In this step, you will use a script that will automatically configure Terraform
to create all the necessary resources to ingest GitHub data into Sumo Logic.

Run this command `sh -c "$(curl -sSL https://raw.githubusercontent.com/ccaum/sumologic-solution-templates/github_getting_started_guide/software-development-optimization-terraform/scripts/getting-started)" -- github`

### Step 4a - Enter your GitHub info

![](/resources/github-access-token.png)

1) Enter the GitHub personal access token you created in Step 3
2) Enter the name of the GitHub organization you'd like to collect GitHub data on

### Step 4b - Enter your Sumo Logic access token

![](/resources/sumo-logic-access-token.png)

1) Enter the Sumo Logic Personal Access Token you created in Step 2

2) Enter the region you created your Sumo Logic account in. Use this guide to determine which region code to provide: [](https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security#how-can-i-determine-which-endpoint-i-should-use)


The script will now download a specific version of Terraform and dependent
plugins and apply Terraform code. The Terraform installed **will not**
interfere with any existing installations of Terraform.

If the script c, you will now have a new folder called "Software
Development Optimization" in your Sumo Logic Personal folder. There will be a
collection of GitHub dashboards that will populate as you and your team use
GitHub.

## Step 5 - Verify data is being received

1) Create a new pull request in a repository in the GitHub organization you specified when you ran the script in Step 4.

![](/resources/github-pull-requests-dashboard.gif)

2) Wait about 1 minute and then view the "GitHub - Pull Request Overview dashboard" in your Sumo Logic Account.
