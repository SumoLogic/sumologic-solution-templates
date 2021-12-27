#!/bin/bash

tf_linux_amd64_url=https://releases.hashicorp.com/terraform/0.12.31/terraform_0.12.31_linux_amd64.zip
tf_linux_amd64_checksum=e5eeba803bc7d8d0cae7ef04ba7c3541c0abd8f9e934a5e3297bf738b31c5c6d

tf_linux_386_url=https://releases.hashicorp.com/terraform/0.12.31/terraform_0.12.31_linux_386.zip
tf_linux_386_checksum=abdd13b29cac315900246bf8ebff19040dbc1ae6ce99c1348e1bc59ba04241f1

tf_darwin_amd64_url=https://releases.hashicorp.com/terraform/0.12.31/terraform_0.12.31_darwin_amd64.zip
tf_darwin_amd64_checksum=c1a6ca04026cebe7849610037ebc960609484c25f47a58344efaa7fcd5be1e56

tf_jira_plugin_darwin_amd64_url=https://github.com/fourplusone/terraform-provider-jira/releases/download/v0.1.15/terraform-provider-jira_0.1.15_darwin_amd64.zip
tf_jira_plugin_linux_amd64_url=https://github.com/fourplusone/terraform-provider-jira/releases/download/v0.1.15/terraform-provider-jira_0.1.15_linux_amd64.zip
tf_jira_plugin_linux_386_url=https://github.com/fourplusone/terraform-provider-jira/releases/download/v0.1.15/terraform-provider-jira_0.1.15_linux_386.zip

tf_rest_api_plugin_darwin_amd64_url=https://github.com/Mastercard/terraform-provider-restapi/releases/download/v1.16.0/terraform-provider-restapi_1.16.0_darwin_amd64.zip
tf_rest_api_plugin_linux_amd64_url=https://github.com/Mastercard/terraform-provider-restapi/releases/download/v1.16.0/terraform-provider-restapi_1.16.0_linux_amd64.zip
tf_rest_api_plugin_linux_386_url=https://github.com/Mastercard/terraform-provider-restapi/releases/download/v1.16.0/terraform-provider-restapi_1.16.0_linux_386.zip

kernel=`uname`
if [ $kernel != "linux" ] && [ $kernel != "Darwin" ]; then
  echo "Unsupported operating system"
fi

## CHECK MACOS ARCHITECTURE
if [ $kernel == "darwin" ]; then
  darwin_architecture=`uname -a | rev | cut -d" " -f1 | rev`
  if [ $darwin_architecture != "x86_64" ]; then 
    echo "Unsupported architecture: ${darwin_architecture}"
    exit 1
  fi
fi

curl_version_stdout=`curl --version`
if [ $? -ne 0 ]; then
  echo "Could not find curl command"
  exit 1
fi

curl_version=`echo $curl_version_stdout | head -n 1 | cut -d' ' -f2`
if [ $? -ne 0 ] || [ $curl_version == "" ]; then
  echo "Could not determine version of curl"
  exit 1
fi

#TODO: check the curl version against a supported version regex

## DOWNLOAD TERRAFORM FOR PLATFORM
tf_exists=`./terraform || false`
if [ $kernel == "linux" ] && [ $tf_exists -ne 0 ]; then
  linux_architecture=`uname -i`

  if [ $linux_architecture == "x86_64" ]; then
    tf_download_url=$tf_linux_amd64_url
    tf_checksum=$tf_linux_amd64_checksum
    tf_jira_plugin_url=$tf_jira_plugin_linux_amd64_url
    tf_rest_api_plugin_url=$tf_rest_api_plugin_linux_amd64_url
    tf_plugin_directory=".terraform/plugins/linux_amd64"
  fi

  if [ $linux_architecture == "x86" ]; then
    tf_download_url=$tf_linux_386_url
    tf_checksum=$tf_linux_386_checksum
    tf_jira_plugin_url=$tf_jira_plugin_linux_386_url
    tf_rest_api_plugin_url=$tf_rest_api_plugin_linux_386_url
    tf_plugin_directory=".terraform/plugins/linux_386"
  fi
fi

if [ $kernel == "Darwin" ]; then
  darwin_architecture=`uname -a | rev | cut -d" " -f1 | rev`

  if [ $darwin_architecture == "x86_64" ]; then
    tf_download_url=$tf_darwin_amd64_url
    tf_checksum=$tf_darwin_amd64_checksum
    tf_jira_plugin_url=$tf_jira_plugin_darwin_amd64_url
    tf_rest_api_plugin_url=$tf_rest_api_plugin_darwin_amd64_url
    tf_plugin_directory=".terraform/plugins/darwin_amd64"
  fi
fi

echo "DOWNLOADING TERRAFORM..."
curl -sSL $tf_download_url -o terraform.zip

tf_binary_checksum=`shasum -a 256 terraform.zip | cut -d' ' -f1`

if [ $tf_binary_checksum != $tf_checksum ]; then
  echo "The downloaded Terraform zip file has checksum of '${tf_binary_checksum}' - does not match expected checksum of ${tf_checksum}. It may have been modified at the source: ${tf_download_url}"
  exit 2
fi

unzip -o terraform.zip
if [ $? != 0 ]; then
  echo "Could not unzip Terraform package"
  exit 1
fi
rm terraform.zip

echo "Done downloading Terraform"

## DOWNLOAD PLATFORM SPECIFIC PLUGINS
mkdir -p $tf_plugin_directory
cd $tf_plugin_directory

curl -sSL $tf_jira_plugin_url -O
if [ $? != 0 ]; then
  echo "Could not download plugin ${tf_jira_plugin_url}"
  exit 1
fi

curl -sSL $tf_rest_api_plugin_url -O
if [ $? != 0 ]; then
  echo "Could not download plugin ${tf_rest_api_plugin_url}"
  exit 1
fi

ls

find . -name 'terraform-provider-restapi*zip' | xargs unzip -o
find . -name 'terraform-provider-jira*zip' | xargs unzip -o

rm terraform-provider-restapi*zip
rm terraform-provider-jira*zip

cd -

## Initialize Terraform environment
./terraform init
if [ $? -ne 0 ]; then
  echo "Error: unable to initiatlize terraform"
fi
