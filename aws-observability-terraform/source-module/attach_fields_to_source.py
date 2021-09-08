from sumologic import SumoLogic
import json
import os

class SumoResource(object):

    def __init__(self, props, *args, **kwargs):
        access_id, access_key, deployment = props["SumoAccessID"], props["SumoAccessKey"], props["SumoDeployment"]
        self.deployment = deployment
        self.sumologic_cli = SumoLogic(access_id, access_key, self.api_endpoint)

    @property
    def api_endpoint(self):
        if self.deployment == "us1":
            return "https://api.sumologic.com/api"
        elif self.deployment in ["ca", "au", "de", "eu", "jp", "us2", "fed", "in"]:
            return "https://api.%s.sumologic.com/api" % self.deployment
        else:
            return 'https://%s-api.sumologic.net/api' % self.deployment


class SumoLogicUpdateFields(SumoResource):
    """
        This Class helps you to add fields to an existing source. This class will not create a new source if not already present.
    """
    # This function can add field if it doesnt exist
    # If field already exists, it'll update value associated with the field
    def add_fields_to_source(self, collector_id, source_id, fields):
        if collector_id and source_id:
            try:
                sv, etag = self.sumologic_cli.source(collector_id, source_id)
            except:
                return f'''Status: "Collector, source not found", collector_id: {collector_id}, source_id: {source_id}''' 

            existing_fields = sv['source']['fields']
            new_fields = existing_fields.copy()
            new_fields.update(fields)

            sv['source']['fields'] = new_fields
            resp = self.sumologic_cli.update_source(collector_id, sv, etag)
            data = resp.json()['source']
            print("Added fields to collector: "+collector_id+ " and source: "+ source_id)
            return f'''source_name: {data["name"]}, source_id: {source_id}'''
        else:
            return f'''Status: "Collector, source not found", collector_id: {collector_id}, source_id: {source_id}'''

    #This function can delete fields of source
    def delete_fields_of_source(self, collector_id, source_id, fields_to_delete):
        if collector_id and source_id:
            try:
                sv, etag = self.sumologic_cli.source(collector_id, source_id)
            except:
                return f'''Status: "Collector, source not found", collector_id: {collector_id}, source_id: {source_id}''' 

            existing_fields = sv['source']['fields']
            new_fields = existing_fields.copy()
            
            for field in fields_to_delete:
                try:
                    new_fields.pop(field)
                except KeyError as ex:
                    pass

            sv['source']['fields'] = new_fields

            resp = self.sumologic_cli.update_source(collector_id, sv, etag)
            data = resp.json()['source']
            print("Deleted fields from collector: "+collector_id+ " and source: "+ source_id)
            return f'''source_name: {data["name"]}, source_id: {source_id}'''
        else:
            return f'''Status: "Collector, source not found", collector_id: {collector_id}, source_id: {source_id}'''


if __name__ == "__main__":
    prop ={}
    env_vars = os.environ
    access_id = env_vars.get("SumoAccessID")
    access_key = env_vars.get("SumoAccessKey")
    deployment = env_vars.get("SumoDeployment")
    source_url = env_vars.get("SourceApiUrl")
    source_id = source_url.split("/")[-1]
    collector_id = source_url.split("/")[-3]
    
    prop["SumoAccessID"]=access_id
    prop["SumoAccessKey"]=access_key
    prop["SumoDeployment"]=deployment
    
    fields_to_delete = [] # Please add keys of the fields that needs to be removed on terraform destroy e.g ['FieldKeyName']
    fields = json.loads(env_vars.get("Fields"))
    source = SumoLogicUpdateFields(prop)
    source.add_fields_to_source(collector_id,source_id,fields)
    