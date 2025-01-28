# Packer and CI Workflow

This repository contains Packer configuration files and GitHub Actions workflows for building and packaging AMIs (Amazon Machine Images) using Packer. The workflows are designed to automate the build process and ensure that the Packer configurations are correctly formatted and validated.

## Workflow Overview

### CI Workflow

The CI workflow is triggered on a pull request to the `main` branch. It performs the following steps:

1. **Checkout Code**: Retrieves the latest code from the repository.
2. **Install Packer**: Installs Packer on the runner environment.
3. **Initialize Packer**: Initializes the Packer configuration in the repository.
4. **Packer Format Check**: Runs a format check on the Packer configuration files.
5. **Packer Validate**: Validates the Packer configuration to ensure it is syntactically correct.

This workflow ensures that Packer files are formatted and vali before they are merged into the `main` branch.

### Build and Package Workflow

The build and package workflow is triggered on a push to the `main` branch. It performs the following steps:

1. **Checkout Code**: Retrieves the latest code from the repository.
2. **Set AWS Environment Variables**: Sets AWS credentials and region from GitHub Secrets to interact with AWS.
3. **Install Packer**: Installs Packer on the runner environment.
4. **Install SOPS**: Installs the SOPS tool to decrypt secrets.
5. **Decrypt Secrets**: Decrypts any encrypted secrets and prepares them for use during the build.
6. **Initialize Packer**: Initializes the Packer configuration.
7. **Build AMI**: Runs Packer to build the AMI based on the provided Packer configuration file.

This workflow is responsible for building and packaging the AMI once the changes have been pushed to the `main` branch.

## Setup Instructions

### Prerequisites

1. **AWS Credentials**: Store your AWS access key and secret access key as GitHub Secrets (`AWS_ACCESS_KEY_ID_GHACTIONS_PACKER` and `AWS_SECRET_ACCESS_KEY_GHACTIONS_PACKER`).

### Running Locally

1. Initialize Packer in the repository:
   ```bash
   packer init .
   ```
2. Validate the Packer configuration:
   ```bash
   packer validate .
   ```
3. Build the AMI:
   ```bash
   packer build .
   ```

### GitHub Actions Workflows

The CI workflow will automatically run on pull requests to main to validate the Packer files.
The build and package workflow will run when changes are pushed to the main branch and will automatically build the AMI using Packer.
