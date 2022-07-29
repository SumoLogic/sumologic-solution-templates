package test

import (
	"encoding/base64"
	"fmt"
	"net/url"
	"testing"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

var props = loadPropertiesFile("../../examples/sourcemodule/testSource/main.auto.tfvars")

func loadPropertiesFile(file string) map[string]string {
	props, err := ReadPropertiesFile(file)
	if err != nil {
		fmt.Println("Error while reading properties file " + err.Error())
	}
	return props
}

//SumoLogic Environment URL
var sumologicURL = getSumologicURL()

func getSumologicURL() string {
	u, _ := url.Parse(getProperty("sumo_api_endpoint"))
	return u.Scheme + "://" + u.Host
}

func getProperty(property string) string {
	return props[property]
}

var customValidation = func(statusCode int, body string) bool { return statusCode == 200 }

// We are creating admin header because Folder is not visible in case of Admin Recom Folder with share = false, only visible with admin mode
var headers = map[string]string{"Authorization": "Basic " + base64.StdEncoding.EncodeToString([]byte(getProperty("sumologic_access_id")+":"+getProperty("sumologic_access_key"))), "isAdminMode": "true"}

func validateSumoCollector(t *testing.T, terraformOptions *terraform.Options, collectorID string) {
	// Verify that we get back a 200 OK
	http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/collectors/%s", sumologicURL, collectorID), nil, headers, customValidation, nil)
}

func validateSumoSource(t *testing.T, terraformOptions *terraform.Options, collectorID string, source string) {
	// Verify that we get back a 200 OK
	http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/collectors/%v/sources/%v", sumologicURL, collectorID, source), nil, headers, customValidation, nil)
}

// ValidateResourceCounts is used to validate added, changed and destroyed resource count.
func AssertResourceCounts(t *testing.T, actualCount *terraform.ResourceCount, countAdd, countChange, countDestroy int) {
	assert.Equal(t, countAdd, actualCount.Add, "Mismatch in Added resources.")
	assert.Equal(t, countChange, actualCount.Change, "Mismatch in Changed resources.")
	assert.Equal(t, countDestroy, actualCount.Destroy, "Mismatch in Destroyed resources.")
}
