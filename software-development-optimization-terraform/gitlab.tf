provider "gitlab" {
      token        = var.gitlab_token
      }

      
# This will create project webhook on the projects in your Gitlab account. 
# The values of events can be configured to true , false based on requirements . 
# For more details visit https://registry.terraform.io/providers/gitlabhq/gitlab/3.6.0/docs/resources/project_hook
resource "gitlab_project_hook" "gitlab_sumologic_project_webhook" {
      count      = ("${var.install_gitlab}" == "collection" || "${var.install_gitlab}" == "all") && "${var.gitlab_project_webhook_create}" ? length(var.gitlab_project_names) : 0
      #count      = ("${var.install_gitlab}" == "collection" || "${var.install_gitlab}" == "all") && "${var.gitlab_project_webhook_create}" ? 1 : 0
      project = var.gitlab_project_names[count.index]
      url          = sumologic_http_source.gitlab[0].url
      enable_ssl_verification = true
      merge_requests_events = true
      push_events = true
      issues_events = true
      confidential_issues_events = true
      confidential_note_events= true
      tag_push_events=true
      note_events=true
      job_events=true
      pipeline_events=true
      wiki_page_events=true
      deployment_events= true 
  
}