FROM python:3.13-alpine

# Install git using apk
RUN apk update && apk add git ruby ruby-dev build-base
RUN gem --version
RUN gem install cfn-nag -v 0.8.10

# Create a working directory
WORKDIR /cf_test_automation

# Copy only image files (like .jpg, .png) from the host to the container

# Copy the specified directories into the container
COPY setup-infra/ /cf_test_automation/test/setup-infra/
COPY testbundles/ /cf_test_automation/test/testbundles/
COPY testcases/ /cf_test_automation/test/testcases/
COPY testsuites/ /cf_test_automation/test/testsuites/

# Optional: Install dependencies
COPY requirements.txt /cf_test_automation/test/
RUN pip install --no-cache-dir -r /cf_test_automation/test/requirements.txt

# Install dependencies (if any, e.g., pip requirements)
RUN pip install --no-cache-dir git+https://<username>:<password>@github.com/SumoLogic/sumologic-aws-cloudformation-test.git@cf_2_12_0
