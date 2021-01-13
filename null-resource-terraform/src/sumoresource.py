import json
import os
import re
import tempfile
import time
from abc import abstractmethod
from datetime import datetime
from random import uniform

import requests
import six
from resourcefactory import AutoRegisterResource
from sumologic import SumoLogic
from fileutils import FileUtils


@six.add_metaclass(AutoRegisterResource)
class SumoResource(object):

    def __init__(self, props, resource_type):
        access_id, access_key, deployment = props.get("SumoAccessID"), props.get("SumoAccessKey"), props.get(
            "SumoDeployment")
        self.deployment = deployment
        self.sumologic_cli = SumoLogic(access_id, access_key, self.api_endpoint)
        self.file = FileUtils(props.get("Section"), props.get("KeyPrefix"))
        self.key = resource_type

    @abstractmethod
    def create(self, *args, **kwargs):
        pass

    @abstractmethod
    def update(self, *args, **kwargs):
        pass

    @abstractmethod
    def delete(self, *args, **kwargs):
        pass

    @abstractmethod
    def extract_params(self, event):
        pass

    @property
    def api_endpoint(self):
        if self.deployment == "us1":
            return "https://api.sumologic.com/api"
        elif self.deployment in ["ca", "au", "de", "eu", "jp", "us2", "fed", "in"]:
            return "https://api.%s.sumologic.com/api" % self.deployment
        else:
            return 'https://%s-api.sumologic.net/api' % self.deployment

    def is_enterprise_or_trial_account(self):
        to_time = int(time.time()) * 1000
        from_time = to_time - 5 * 60 * 1000
        try:
            search_query = '''guardduty*
                | "IAMUser" as targetresource
                | "2" as sev
                | "UserPermissions" as threatName
                | "Recon" as threatPurpose
                | toint(sev) as sev
                | benchmark percentage as global_percent from guardduty on threatpurpose=threatPurpose, threatname=threatName, severity=sev, resource=targetresource'''
            response = self.sumologic_cli.search_job(search_query, fromTime=from_time, toTime=to_time)
            print("schedule job status: %s" % response)
            response = self.sumologic_cli.search_job_status(response)
            print("job status: %s" % response)
            if len(response.get("pendingErrors", [])) > 0:
                return False
            else:
                return True
        except Exception as e:
            if hasattr(e, "response") and e.response.status_code == 403:
                return False
            else:
                raise e


class App(SumoResource):

    ENTERPRISE_ONLY_APPS = {"Amazon GuardDuty Benchmark", "Global Intelligence for AWS CloudTrail"}

    def _convert_to_hour(self, timeoffset):
        hour = timeoffset / 60 * 60 * 1000
        return "%sh" % (hour)

    def _replace_source_category(self, appjson_filepath, sourceDict):
        with open(appjson_filepath, 'r') as old_file:
            text = old_file.read()
            if sourceDict:
                for k, v in sourceDict.items():
                    text = text.replace("$$%s" % k, v)
            appjson = json.loads(text)

        return appjson

    def _add_time_suffix(self, appjson):
        date_format = "%Y-%m-%d %H:%M:%S"
        appjson['name'] = appjson['name'] + "-" + datetime.utcnow().strftime(date_format)
        return appjson

    def _get_app_folder(self, appdata, parent_id):
        folder_id = None
        try:
            response = self.sumologic_cli.create_folder(appdata["name"], appdata["description"][:255], parent_id)
            folder_id = response.json()["id"]
        except Exception as e:
            if hasattr(e, 'response') and "errors" in e.response.json() and e.response.json()["errors"]:
                errors = e.response.json()["errors"]
                for error in errors:
                    if error.get('code') == 'content:duplicate_content':
                        folder_details = self.sumologic_cli.get_folder_by_id(parent_id)
                        if "children" in folder_details:
                            for children in folder_details["children"]:
                                if "name" in children and children["name"] == appdata["name"]:
                                    return children["id"]
                raise
        return folder_id

    def _get_app_content(self, appname, source_params, s3url=None):
        # Based on S3 URL provided download the data.
        if not s3url:
            key_name = "ApiExported-" + re.sub(r"\s+", "-", appname) + ".json"
            s3url = "https://app-json-store.s3.amazonaws.com/%s" % key_name
        print("Fetching appjson %s" % s3url)
        with requests.get(s3url, stream=True) as r:
            r.raise_for_status()
            with tempfile.NamedTemporaryFile() as fp:
                for chunk in r.iter_content(chunk_size=8192):
                    if chunk:
                        fp.write(chunk)
                fp.flush()
                fp.seek(0)
                appjson = self._replace_source_category(fp.name, source_params)
                appjson = self._add_time_suffix(appjson)

        return appjson

    def _wait_for_folder_creation(self, folder_id, job_id):
        print("waiting for folder creation folder_id %s job_id %s" % (folder_id, job_id))
        waiting = True
        while waiting:
            response = self.sumologic_cli.check_import_status(folder_id, job_id)
            waiting = response.json()['status'] == "InProgress"
            time.sleep(5)

        print("job status: %s" % response.text)

    def _wait_for_folder_copy(self, folder_id, job_id):
        print("waiting for folder copy folder_id %s job_id %s" % (folder_id, job_id))
        waiting = True
        while waiting:
            response = self.sumologic_cli.check_copy_status(folder_id, job_id)
            waiting = response.json()['status'] == "InProgress"
            time.sleep(5)

        print("job status: %s" % response.text)
        matched = re.search('id:\s*(.*?)\"', response.text)
        copied_folder_id = None
        if matched:
            copied_folder_id = matched[1]
        return copied_folder_id

    def _wait_for_app_install(self, job_id):
        print("waiting for app installation job_id %s" % job_id)
        waiting = True
        while waiting:
            response = self.sumologic_cli.check_app_install_status(job_id)
            waiting = response.json()['status'] == "InProgress"
            time.sleep(5)
        print("job status: %s" % response.text)
        return response

    def _create_or_fetch_apps_parent_folder(self, folder_prefix):
        response = self.sumologic_cli.get_personal_folder()
        folder_name = folder_prefix + str(datetime.now().strftime(" %d-%b-%Y"))
        description = "This folder contains all the apps created as a part of Sumo Logic Solutions."
        try:
            folder = self.sumologic_cli.create_folder(folder_name, description, response.json()['id'])
            return folder.json()["id"]
        except Exception as e:
            if hasattr(e, 'response') and "errors" in e.response.json() and e.response.json()["errors"]:
                errors = e.response.json()["errors"]
                for error in errors:
                    if error.get('code') == 'content:duplicate_content':
                        response = self.sumologic_cli.get_personal_folder()
                        if "children" in response.json():
                            for children in response.json()["children"]:
                                if "name" in children and children["name"] == folder_name:
                                    return children["id"]
            raise

    def create_by_import_api(self, appname, source_params, folder_name, s3url, *args, **kwargs):
        # Add  retry if folder sync fails
        if appname in self.ENTERPRISE_ONLY_APPS and not self.is_enterprise_or_trial_account():
            raise Exception("%s is available to Enterprise or Trial Account Type only." % appname)

        content = self._get_app_content(appname, source_params, s3url)

        if folder_name:
            folder_id = self._create_or_fetch_apps_parent_folder(folder_name)
        else:
            response = self.sumologic_cli.get_personal_folder()
            folder_id = response.json()['id']
        app_folder_id = self._get_app_folder(content, folder_id)
        time.sleep(5)
        response = self.sumologic_cli.import_content(folder_id, content, is_overwrite="true")
        job_id = response.json()["id"]
        print("installed app %s: appFolderId: %s personalFolderId: %s jobId: %s" % (
            appname, app_folder_id, folder_id, job_id))
        self._wait_for_folder_creation(folder_id, job_id)
        return {"APP_FOLDER_NAME": content["name"]}, app_folder_id

    def create_by_install_api(self, appid, appname, source_params, folder_name, *args, **kwargs):
        if appname in self.ENTERPRISE_ONLY_APPS and not self.is_enterprise_or_trial_account():
            raise Exception("%s is available to Enterprise or Trial Account Type only." % appname)

        folder_id = None

        if folder_name:
            folder_id = self._create_or_fetch_apps_parent_folder(folder_name)
        else:
            response = self.sumologic_cli.get_personal_folder()
            folder_id = response.json()['id']

        content = {'name': appname + datetime.now().strftime(" %d-%b-%Y %H:%M:%S"), 'description': appname,
                   'dataSourceValues': source_params, 'destinationFolderId': folder_id}

        response = self.sumologic_cli.install_app(appid, content)
        job_id = response.json()["id"]
        response = self._wait_for_app_install(job_id)

        json_resp = json.loads(response.content)
        if (json_resp['status'] == 'Success'):
            app_folder_id = json_resp['statusMessage'].split(":")[1]
            print("installed app %s: appFolderId: %s parent_folder_id: %s jobId: %s" % (
                appname, app_folder_id, folder_id, job_id))
            return {"APP_FOLDER_NAME": content["name"]}, app_folder_id
        else:
            print("%s installation failed." % appname)
            raise Exception(response.text)

    def create(self, appname, source_params, appid=None, folder_name=None, s3url=None, *args, **kwargs):
        if appid:
            return self.create_by_install_api(appid, appname, source_params, folder_name, *args, **kwargs)
        else:
            return self.create_by_import_api(appname, source_params, folder_name, s3url, *args, **kwargs)

    def update(self, app_folder_id, appname, source_params, appid=None, folder_name=None, retain_old_app=False,
               s3url=None, *args, **kwargs):
        data, new_app_folder_id = self.create(appname, source_params, appid, folder_name, s3url)
        print("updated app appFolderId: %s " % new_app_folder_id)
        if retain_old_app:
            # get the parent folder from new app folder. Create a OLD APPS folder in it.
            # Copy the app_folder_id to OLD APPS.
            new_folder_details = self.sumologic_cli.get_folder_by_id(new_app_folder_id)
            parent_folder_id = new_folder_details["parentId"]
            backup_folder_id = self._get_app_folder({"name": "BackUpOldApps", "description": "The folder contains back up of all the apps that are updated using CloudFormation template."},
                                                    parent_folder_id)
            # Starting Folder Copy
            response = self.sumologic_cli.copy_folder(app_folder_id, backup_folder_id)
            job_id = response.json()["id"]
            print("Copy Completed parentFolderId: %s jobId: %s" % (backup_folder_id, job_id))
            copied_folder_id = self._wait_for_folder_copy(app_folder_id, job_id)
            # Updating copied folder name with suffix BackUp.
            copied_folder_details = self.sumologic_cli.get_folder_by_id(copied_folder_id)
            copied_folder_details = {"name": copied_folder_details["name"].replace("(Copy)", "- BackUp_" + datetime.now().strftime("%H:%M:%S")),
                                     "description": copied_folder_details["description"][:255]}
            self.sumologic_cli.update_folder_by_id(copied_folder_id, copied_folder_details)
        self.delete(app_folder_id, True)
        return data, new_app_folder_id

    def delete(self, app_folder_id, remove_on_delete_stack, *args, **kwargs):
        if remove_on_delete_stack and app_folder_id:
            self.sumologic_cli.delete_folder(app_folder_id)
            print("SUMO LOGIC APP - deleting app folder %s." % app_folder_id)
        else:
            print("SUMO LOGIC APP - skipping app folder deletion")

    def extract_params(self, environment_variables):
        app_folder_id = self.file.get_key(self.key)

        return {
            "appid": environment_variables.get("AppId"),
            "appname": environment_variables.get("AppName"),
            "source_params": environment_variables.get("AppSources"),
            "folder_name": environment_variables.get("FolderName"),
            "retain_old_app": True if environment_variables.get("RetainOldAppOnUpdate") == "True" else False,
            "app_folder_id": app_folder_id,
            "update_flag": True if app_folder_id else False,
            "s3url": environment_variables.get("AppJsonS3Url")
        }


class SumoLogicAWSExplorer(SumoResource):

    def get_explorer_id(self, hierarchy_name):
        hierarchies = self.sumologic_cli.get_entity_hierarchies()
        if hierarchies and "data" in hierarchies:
            for hierarchy in hierarchies["data"]:
                if hierarchy_name == hierarchy["name"]:
                    return hierarchy["id"]
        raise Exception("Hierarchy with name %s not found" % hierarchy_name)

    def create_hierarchy(self, hierarchy_name, level, hierarchy_filter):
        content = {
            "name": hierarchy_name,
            "filter": hierarchy_filter,
            "level": level
        }
        try:
            response = self.sumologic_cli.create_hierarchy(content)
            hierarchy_id = response.json()["id"]
            print("Hierarchy -  creation successful with ID %s" % hierarchy_id)
            return {"Hierarchy_Name": response.json()["name"]}, hierarchy_id
        except Exception as e:
            if hasattr(e, 'response') and "errors" in e.response.json() and e.response.json()["errors"]:
                errors = e.response.json()["errors"]
                for error in errors:
                    if error.get('code') == 'hierarchy:duplicate':
                        print("Hierarchy -  Duplicate Exists for Name %s" % hierarchy_name)
                        # Get the hierarchy ID from all explorer.
                        hierarchy_id = self.get_explorer_id(hierarchy_name)
                        response = self.sumologic_cli.update_hierarchy(hierarchy_id, content)
                        hierarchy_id = response.json()["id"]
                        print("Hierarchy -  update successful with ID %s" % hierarchy_id)
                        return {"Hierarchy_Name": hierarchy_name}, hierarchy_id
            raise

    def create(self, hierarchy_name, level, hierarchy_filter, *args, **kwargs):
        return self.create_hierarchy(hierarchy_name, level, hierarchy_filter)

    # Use the new update API.
    def update(self, hierarchy_id, hierarchy_name, level, hierarchy_filter, *args, **kwargs):
        data, hierarchy_id = self.create(hierarchy_name, level, hierarchy_filter)
        print("Hierarchy -  update successful with ID %s" % hierarchy_id)
        return data, hierarchy_id

    # handling exception during delete, as update can fail if the previous explorer, metric rule or field has
    # already been deleted. This is required in case of multiple installation of
    # CF template with same names for metric rule, explorer view or fields
    def delete(self, hierarchy_id, hierarchy_name, remove_on_delete_stack, *args, **kwargs):
        if remove_on_delete_stack:
            # Backward Compatibility for 2.0.2 Versions.
            # If id is duplicate then get the id from explorer name and delete it.
            if hierarchy_id == "Duplicate":
                hierarchy_id = self.get_explorer_id(hierarchy_name)
            response = self.sumologic_cli.delete_hierarchy(hierarchy_id)
            print("Hierarchy - Completed the Hierarchy deletion for Name %s, response - %s"
                  % (hierarchy_name, response.text))
        else:
            print("Hierarchy - Skipping the Hierarchy deletion.")

    def extract_params(self, event):
        props = event.get("ResourceProperties")
        hierarchy_id = None
        if event.get('PhysicalResourceId'):
            _, hierarchy_id = event['PhysicalResourceId'].split("/")

        return {
            "hierarchy_name": props.get("HierarchyName"),
            "level": props.get("HierarchyLevel"),
            "hierarchy_filter": props.get("HierarchyFilter"),
            "hierarchy_id": hierarchy_id
        }


class SumoLogicMetricRules(SumoResource):

    def create_metric_rule(self, metric_rule_name, match_expression, variables, delete=True):
        variables_to_extract = []
        if variables:
            for k, v in variables.items():
                variables_to_extract.append({"name": k, "tagSequence": v})

        content = {
            "name": metric_rule_name,
            "matchExpression": match_expression,
            "variablesToExtract": variables_to_extract
        }
        try:
            response = self.sumologic_cli.create_metric_rule(content)
            job_name = response.json()["name"]
            print("SUMO LOGIC METRIC RULES - creation successful with Name %s." % job_name)
            return {"METRIC_RULES": response.json()["name"]}, job_name
        except Exception as e:
            if hasattr(e, 'response') and "errors" in e.response.json() and e.response.json()["errors"]:
                errors = e.response.json()["errors"]
                for error in errors:
                    if error.get('code') == 'metrics:rule_name_already_exists' \
                            or error.get('code') == 'metrics:rule_already_exists':
                        print("SUMO LOGIC METRIC RULES - Duplicate Exists for Name %s." % metric_rule_name)
                        if delete:
                            self.delete(metric_rule_name, metric_rule_name, True)
                            # providing sleep for 10 seconds after delete.
                            time.sleep(uniform(2, 10))
                            return self.create_metric_rule(metric_rule_name, match_expression, variables, False)
                        return {"METRIC_RULES": metric_rule_name}, metric_rule_name
            raise

    def create(self, metric_rule_name, match_expression, variables, *args, **kwargs):
        return self.create_metric_rule(metric_rule_name, match_expression, variables)

    def update(self, metric_rule_id, metric_rule_name, match_expression, variables, *args, **kwargs):
        # Need to add it because CF calls delete method if identifies change in metric rule name.
        self.delete(metric_rule_id, True)
        data, job_name = self.create_metric_rule(metric_rule_name, match_expression, variables)
        print("SUMO LOGIC METRIC RULES - Update successful with Name %s." % job_name)
        return data, job_name

    def delete(self, metric_rule_id, remove_on_delete_stack, *args, **kwargs):
        if remove_on_delete_stack and metric_rule_id:
            try:
                self.sumologic_cli.delete_metric_rule(metric_rule_id)
                print("SUMO LOGIC METRIC RULES - Completed the Metric Rule deletion for Name %s." % metric_rule_id)
            except Exception as e:
                raise e
        else:
            print("SUMO LOGIC METRIC RULES - Skipping the Metric Rule deletion.")

    def extract_params(self, environment_variables):
        # Get previous Metric Rule Name
        old_metric_rule_name = self.file.get_key(self.key)

        variables = {}
        if "ExtractVariables" in environment_variables:
            variables = json.loads(environment_variables.get("ExtractVariables"))

        return {
            "metric_rule_name": environment_variables.get("MetricRuleName"),
            "match_expression": environment_variables.get("MatchExpression"),
            "variables": variables,
            "metric_rule_id": old_metric_rule_name,
            "update_flag": True if old_metric_rule_name else False
        }


class SumoLogicUpdateFields(SumoResource):
    """
        This Class helps you to add fields to an existing source. This class will not create a new source if not already present.
        Fields can also be added to new Sources using AWSSource, HTTPSources classes.
        Getting collector name, as Calling custom collector resource can update the collector name if stack is updated with different collector name.
    """

    def add_fields_to_collector(self, collector_id, source_id, fields):
        if collector_id and source_id:
            sv, etag = self.sumologic_cli.source(collector_id, source_id)

            existing_fields = sv['source']['fields']

            new_fields = existing_fields.copy()
            new_fields.update(fields)

            sv['source']['fields'] = new_fields

            resp = self.sumologic_cli.update_source(collector_id, sv, etag)

            data = resp.json()['source']
            print("SUMO LOGIC ADD FIELDS - Added Fields %s in Source %s." % (fields, data["name"]))

            return "AddField", {"collector_id": collector_id, "source_id": source_id, "fields": fields, "source_name": data["name"]}
        return "AddField", {}

    def create(self, collector_id, source_id, fields, *args, **kwargs):
        return self.add_fields_to_collector(collector_id, source_id, fields)

    # Update the new fields to source.
    def update(self, collector_id, source_id, fields, *args, **kwargs):
        data, value = self.add_fields_to_collector(collector_id, source_id, fields)
        print("SUMO LOGIC ADD FIELDS - Updated Fields %s in Source." % fields)
        return data, value

    def delete(self, old_properties, remove_on_delete_stack, *args, **kwargs):
        if remove_on_delete_stack and old_properties:
            sv, etag = self.sumologic_cli.source(old_properties.get("collector_id"), old_properties.get("source_id"))
            existing_fields = sv['source']['fields']

            if old_properties.get("fields"):
                for k in old_properties.get("fields"):
                    existing_fields.pop(k, None)

            sv['source']['fields'] = existing_fields
            resp = self.sumologic_cli.update_source(old_properties.get("collector_id"), sv, etag)

            data = resp.json()['source']
            print("SUMO LOGIC ADD FIELDS - Reverted Fields in Source %s." % data["name"])
        else:
            print("SUMO LOGIC ADD FIELDS - Skipping the deletion of Fields from source.")

    def extract_params(self, environment_variables):

        # Get previous Field Related data
        old_data = self.file.get_key(self.key)

        fields = {}
        if "Fields" in environment_variables:
            fields = json.loads(environment_variables.get("Fields"))

        source_api_url = os.getenv("SourceApiUrl")
        try:
            collector_id = re.search('collectors/(.*)/sources', source_api_url).group(1)
            source_id = source_api_url.rsplit('/', 1)[-1]
        except:
            raise Exception(
                "Sumo Logic Add Fields - Provided URL %s is not correct. Please check and provide." % source_api_url)

        return {
            "fields": fields,
            "collector_id": collector_id,
            "source_id": source_id,
            "old_properties": old_data,
            "update_flag": True if old_data else False
        }


class SumoLogicFieldExtractionRule(SumoResource):
    def _get_fer_by_name(self, fer_name):
        token = ""
        page_limit = 100
        response = self.sumologic_cli.get_all_field_extraction_rules(limit=page_limit, token=token)
        while response:
            print("calling FER API with token " + token)
            for fer in response['data']:
                if fer["name"] == fer_name:
                    return fer
            token = response['next']
            if token:
                response = self.sumologic_cli.get_all_field_extraction_rules(limit=page_limit, token=token)
            else:
                response = None

        raise Exception("FER with name %s not found" % fer_name)

    def create(self, fer_name, fer_scope, fer_expression, fer_enabled, *args, **kwargs):
        content = {
            "name": fer_name,
            "scope": fer_scope,
            "parseExpression": fer_expression,
            "enabled": fer_enabled
        }
        try:
            response = self.sumologic_cli.create_field_extraction_rule(content)
            job_id = response.json()["id"]
            print("FER RULES -  creation successful with ID %s" % job_id)
            return {"FER_RULES": response.json()["name"]}, job_id
        except Exception as e:
            if hasattr(e, 'response') and "errors" in e.response.json() and e.response.json()["errors"]:
                errors = e.response.json()["errors"]
                for error in errors:
                    if error.get('code') == 'fer:invalid_extraction_rule':
                        print("FER RULES -  Duplicate Exists for Name %s" % fer_name)
                        # check if there is difference in scope, if yes then merge the scopes.
                        fer_details = self._get_fer_by_name(fer_name)
                        change_in_fer = False
                        if "scope" in fer_details and fer_scope not in fer_details["scope"]:
                            fer_details["scope"] = fer_details["scope"] + " or " + fer_scope
                            change_in_fer = True
                        if "parseExpression" in fer_details and fer_expression not in fer_details["parseExpression"]:
                            fer_details["parseExpression"] = fer_expression
                            change_in_fer = True
                        if change_in_fer:
                            self.sumologic_cli.update_field_extraction_rules(fer_details["id"], fer_details)
                        return {"FER_RULES": fer_name}, fer_details["id"]
            raise

    def update(self, fer_id, fer_name, fer_scope, fer_expression, fer_enabled, *args, **kwargs):
        """
            Field Extraction Rule can be updated and deleted from the main stack where it was created.
            Update will update all the details in FER which are changed.
            Scope will be appended with OR conditions.
        """
        content = {
            "name": fer_name,
            "scope": fer_scope,
            "parseExpression": fer_expression,
            "enabled": fer_enabled
        }
        try:
            fer_details = self.sumologic_cli.get_fer_by_id(fer_id)
            # Use existing or append the new scope to existing scope.
            if "scope" in fer_details:
                if fer_scope not in fer_details["scope"]:
                    content["scope"] = fer_details["scope"] + " or " + fer_scope
                else:
                    content["scope"] = fer_details["scope"]

            response = self.sumologic_cli.update_field_extraction_rules(fer_id, content)
            job_id = response.json()["id"]
            print("FER RULES -  update successful with ID %s" % job_id)
            return {"FER_RULES": response.json()["name"]}, job_id
        except Exception as e:
            raise

    def delete(self, fer_id, remove_on_delete_stack, *args, **kwargs):
        if remove_on_delete_stack:
            response = self.sumologic_cli.delete_field_extraction_rule(fer_id)
            print("FER RULES - Completed the Metric Rule deletion for ID %s, response - %s" % (
                fer_id, response.text))
        else:
            print("FER RULES - Skipping the Metric Rule deletion")

    def extract_params(self, environment_variables):
        # Get previous Field Related data
        fer_id = self.file.get_key(self.key)

        return {
            "fer_name": environment_variables.get("FieldExtractionRuleName"),
            "fer_scope": environment_variables.get("FieldExtractionRuleScope"),
            "fer_expression": environment_variables.get("FieldExtractionRuleParseExpression"),
            "fer_enabled": environment_variables.get("FieldExtractionRuleParseEnabled") == "True",
            "fer_id": fer_id,
            "update_flag": True if fer_id else False
        }


class SumoLogicFieldsSchema(SumoResource):

    def get_field_id(self, field_name):
        all_fields = self.sumologic_cli.get_all_fields()
        if all_fields:
            for field in all_fields:
                if field_name == field["fieldName"]:
                    return field["fieldId"]
        raise Exception("Field Name with name %s not found" % field_name)

    def add_field(self, field_name):
        content = {
            "fieldName": field_name,
        }
        try:
            response = self.sumologic_cli.create_new_field(content)
            field_id = response["fieldId"]
            print("SUMO LOGIC FIELD - Field %s created with Field ID as %s." % (field_name, field_id))
            return {"FIELD_NAME": response["fieldName"]}, field_id
        except Exception as e:
            if hasattr(e, 'response') and "errors" in e.response.json() and e.response.json()["errors"]:
                errors = e.response.json()["errors"]
                for error in errors:
                    if error.get('code') == 'field:already_exists':
                        print("SUMO LOGIC FIELD - Duplicate Exists for Name %s." % field_name)
                        # Get the Field ID from the existing fields.
                        field_id = self.get_field_id(field_name)
                        return {"FIELD_NAME": field_name}, field_id
            raise

    def create(self, field_name, *args, **kwargs):
        return self.add_field(field_name)

    def update(self, field_id, field_name, *args, **kwargs):
        self.delete(field_id, True)
        data, field_id = self.create(field_name)
        print("SUMO LOGIC FIELD - Update successful with Name %s." % field_name)
        return data, field_id

    def delete(self, field_id, remove_on_delete_stack, *args, **kwargs):
        if remove_on_delete_stack and field_id:
            try:
                self.sumologic_cli.delete_existing_field(field_id)
                print("SUMO LOGIC FIELD - Completed the Field deletion for ID %s." % field_id)
            except Exception as e:
                if hasattr(e, 'response') and "errors" in e.response.json() and e.response.json()["errors"]:
                    errors = e.response.json()["errors"]
                    for error in errors:
                        if error.get('code') == 'field:cant_be_deleted':
                            print("SUMO LOGIC FIELD - Error while deleting the Field %s, Reason - %s." % (
                                field_id, error.get('message')))
                            return
                raise
        else:
            print("SUMO LOGIC FIELD - Skipping the Field deletion")

    def extract_params(self, environment_variables):
        # Get previous Field ID
        field_id = self.file.get_key(self.key)

        return {
            "field_name": environment_variables.get("FieldName"),
            "field_id": field_id,
            "update_flag": True if field_id else False
        }


class EnterpriseOrTrialAccountCheck(SumoResource):

    def check_account(self):
        is_enterprise = self.is_enterprise_or_trial_account()
        is_paid = "Yes"
        if not is_enterprise:
            all_apps = self.sumologic_cli.get_apps()
            if "apps" in all_apps and len(all_apps['apps']) <= 5:
                is_paid = "No"
        return {"is_enterprise": "Yes" if is_enterprise else "No", "is_paid": is_paid}, is_enterprise

    def create(self, *args, **kwargs):
        return self.check_account()

    def update(self, *args, **kwargs):
        return self.check_account()

    def delete(self, *args, **kwargs):
        print("In Delete method for Enterprise or Trial account")

    def extract_params(self, event):
        props = event.get("ResourceProperties")
        return props
