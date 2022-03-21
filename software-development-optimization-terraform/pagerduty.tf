# Configure the Pagerduty Provider

provider "pagerduty" {
  skip_credentials_validation = "true"
  token = var.pagerduty_api_key
}
