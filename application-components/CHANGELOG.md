## 1.0.0 (Sept 20, 2022)

FEATURES:
* Added new terraform script to deploy following application components - memcached,cassandra,elasticsearch,sqlserver,mongodb,mysql,postgresql,redis,mariadb,couchbase,oracle (GH-118)
    The script creates below resources in sumo logic:

    - Creates Application Components View hierarchy in Explore.
    - Sets up Sumo Logic Field Extraction Rules ([FERs](https://help.sumologic.com/Manage/Field-Extractions)) to enrich the data.
    - Installs Sumo Logic Apps(Database apps and Application Component app) in the Admin recommended or Personal folder.
    - Creates [Fields](https://help.sumologic.com/Manage/Fields)
    - Installs Monitors for each of the selected components.
