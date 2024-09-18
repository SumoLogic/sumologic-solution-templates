# Use a more up-to-date base image (Debian Buster)
FROM debian:buster-slim

# Install curl, git, vim, and other essential tools
RUN apt-get update && apt-get install -y \
    curl \
    git \
    vim \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python 2.7
RUN apt-get update && apt-get install -y \
    python2.7 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Download and install Terraform 0.12.31
RUN curl -LO https://releases.hashicorp.com/terraform/0.12.31/terraform_0.12.31_linux_amd64.zip \
    && unzip terraform_0.12.31_linux_amd64.zip -d /usr/local/bin \
    && rm terraform_0.12.31_linux_amd64.zip

# Download and extract the terraform-provider-jira plugin version 0.1.11
RUN curl -LO https://github.com/fourplusone/terraform-provider-jira/releases/download/v0.1.11/terraform-provider-jira_linux_amd64.zip \
    && unzip terraform-provider-jira_linux_amd64.zip -d /usr/local/bin \
    && rm terraform-provider-jira_linux_amd64.zip 

# Download and install the terraform-provider-restapi plugin
RUN curl -LO https://github.com/Mastercard/terraform-provider-restapi/releases/download/v1.12.0/terraform-provider-restapi_v1.12.0-linux-amd64 \
    && chmod +x terraform-provider-restapi_v1.12.0-linux-amd64 \
    && mv terraform-provider-restapi_v1.12.0-linux-amd64 /usr/local/bin/terraform-provider-restapi

# Set the working directory
WORKDIR /sdo
COPY . /sdo

# Set an entry point for convenience (you can customize this)
ENTRYPOINT ["bash"]
