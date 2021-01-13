import os

from sumoresource import SumoResource

from resourcefactory import ResourceFactory


def main():
    resource_type = os.getenv("ResourceType")
    resource_class = ResourceFactory.get_resource(resource_type)
    # Getting all Env Variables
    props = os.environ
    # Getting the resource
    resource = resource_class(props, resource_type)
    params = resource.extract_params(props)
    # Setting Flag for remove
    params["remove_on_delete_stack"] = True if props.get("Delete") == "True" else False

    some_processing_done = False
    if params["remove_on_delete_stack"]:
        resource.delete(**params)
        resource.file.remove_key(resource.key)
        some_processing_done = True
    else:
        if params["update_flag"]:
            data, value = resource.update(**params)
            some_processing_done = True
        else:
            data, value = resource.create(**params)
            some_processing_done = True
        resource.file.write_data(resource.key, value)

    if not some_processing_done:
        resource.file.remove_key(resource.key)

if __name__ == "__main__":
    main()
