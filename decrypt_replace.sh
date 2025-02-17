#!/bin/bash




decrypted_secrets=$(sops -d secrets.yaml)


ADMIN_USERNAME=$(echo "$decrypted_secrets" | grep admin_username | awk '{print $2}')
ADMIN_PASSWORD=$(echo "$decrypted_secrets" | grep admin_password | awk '{print $2}')
ADMIN_FIRSTNAME=$(echo "$decrypted_secrets" | grep admin_firstname | awk '{print $2}')
ADMIN_LASTNAME=$(echo "$decrypted_secrets" | grep admin_lastname | awk '{print $2}')
ADMIN_EMAIL=$(echo "$decrypted_secrets" | grep admin_email | awk '{print $2}')
JENKINS_LOCATION_URL=$(echo "$decrypted_secrets" | grep jenkins_location_url | awk '{print $2}')
DOMAIN=$(echo "$decrypted_secrets" | grep domain | awk '{print $2}')
NGINX_LINK=$(echo "$decrypted_secrets" | grep nginx_link | awk '{print $2}')
NGINX_CONF=$(echo "$decrypted_secrets" | grep nginx_conf | awk '{print $2}')
REPO_OWNER=$(echo "$decrypted_secrets" | grep repo_owner | awk '{print $2}')
GITHUB_WEBHOOK_ID=$(echo "$decrypted_secrets" | grep github_webhook_id | awk '{print $2}')
GITHUB_WEBHOOK_SECRET=$(echo "$decrypted_secrets" | grep github_webhook_password | awk '{print $2}')
GIT_CREDENTIALS_ID=$(echo "$decrypted_secrets" | grep git_credentials_id | awk '{print $2}')
GIT_USERNAME=$(echo "$decrypted_secrets" | grep gitUsername | awk '{print $2}')
GIT_PERSONAL_ACCESS_TOKEN=$(echo "$decrypted_secrets" | grep git_personal_access_token | awk '{print $2}')
TF_GCP_INFRA_PIPELINE_NAME=$(echo "$decrypted_secrets" | grep tf-gcp-infra-pipeline | awk '{print $2}')
TF_GCP_INFRA_REPO_NAME=$(echo "$decrypted_secrets" | grep tf-gcp-infra-repo_name | awk '{print $2}')
DOCKER_CREDENTIALS_ID=$(echo "$decrypted_secrets" | grep docker_credentials_id | awk '{print $2}')
DOCKER_USERNAME=$(echo "$decrypted_secrets" | grep dockerUsername | awk '{print $2}')
DOCKER_PERSONAL_ACCESS_TOKEN=$(echo "$decrypted_secrets" | grep dockerPersonalAccessToken | awk '{print $2}')
STATIC_SITE_PIPELINE_NAME=$(echo "$decrypted_secrets" | grep static-site-pipeline | awk '{print $2}')
STATIC_SITE_ACTIONS_PIPELINE_NAME=$(echo "$decrypted_secrets" | grep static-site-actions-pipeline | awk '{print $2}')
STATIC_SITE_REPO_NAME=$(echo "$decrypted_secrets" | grep static-site-repo_name | awk '{print $2}')
STATIC_SITE_K8S_PIPELINE_NAME=$(echo "$decrypted_secrets" | grep static-site-k8s-pipeline | awk '{print $2}')
WEBAPP_PIPELINE_NAME=$(echo "$decrypted_secrets" | grep webapp-pipeline | awk '{print $2}')
WEBAPP_HELLO_WORLD_PIPELINE_NAME=$(echo "$decrypted_secrets" | grep webapp-hello-world-pipeline | awk '{print $2}')

STATIC_SITE_K8S_ACTIONS_PIPELINE_NAME=$(echo "$decrypted_secrets" | grep static-site-k8s-actions-pipeline | awk '{print $2}')
STATIC_SITE_K8S_REPO_NAME=$(echo "$decrypted_secrets" | grep static-site-k8s-repo_name | awk '{print $2}')
WEBAPP_ACTIONS_PIPELINE_NAME=$(echo "$decrypted_secrets" | grep webapp-actions-pipeline | awk '{print $2}')
WEBAPP_REPO_NAME=$(echo "$decrypted_secrets" | grep webapp-repo_name | awk '{print $2}')
WEBAPP_HELLO_WORLD_ACTIONS_PIPELINE_NAME=$(echo "$decrypted_secrets" | grep webapp-hello-world-actions-pipeline | awk '{print $2}')
WEBAPP_HELLO_WORLD_REPO_NAME=$(echo "$decrypted_secrets" | grep webapp-hello-world-repo_name | awk '{print $2}')

sed -i "s/ADMIN_USERNAME=\"\*\*\*\"/ADMIN_USERNAME=\"$ADMIN_USERNAME\"/" jenkins.sh
sed -i "s/ADMIN_PASSWORD=\"\*\*\*\"/ADMIN_PASSWORD=\"$ADMIN_PASSWORD\"/" jenkins.sh
sed -i "s/ADMIN_FIRSTNAME=\"\*\*\*\"/ADMIN_FIRSTNAME=\"$ADMIN_FIRSTNAME\"/" jenkins.sh
sed -i "s/ADMIN_LASTNAME=\"\*\*\*\"/ADMIN_LASTNAME=\"$ADMIN_LASTNAME\"/g" jenkins.sh
sed -i "s/ADMIN_EMAIL=\"\*\*\*\"/ADMIN_EMAIL=\"$ADMIN_EMAIL\"/" jenkins.sh
sed -i "s/REPO_OWNER=\"\*\*\*\"/REPO_OWNER=\"$REPO_OWNER\"/" jenkins.sh
awk -v jenkins_location_url="$JENKINS_LOCATION_URL" '{gsub(/JENKINS_LOCATION_URL="[^"]*"/, "JENKINS_LOCATION_URL=\"" jenkins_location_url "\""); print}' jenkins.sh > jenkins.sh.tmp && mv jenkins.sh.tmp jenkins.sh
sed -i "s/JENKINS_LOCATION_URL=\"\*\*\*\"/JENKINS_LOCATION_URL=\"$JENKINS_LOCATION_URL\"/" jenkins.sh
sed -i "s/DOMAIN=\"\*\*\*\"/DOMAIN=\"$DOMAIN\"/" jenkins.sh
awk -v nginx_conf="$NGINX_CONF" '{gsub(/NGINX_CONF="[^"]*"/, "NGINX_CONF=\"" nginx_conf "\""); print}' jenkins.sh > jenkins.sh.tmp && mv jenkins.sh.tmp jenkins.sh
awk -v nginx_link="$NGINX_LINK" '{gsub(/NGINX_LINK="[^"]*"/, "NGINX_LINK=\"" nginx_link "\""); print}' jenkins.sh > jenkins.sh.tmp && mv jenkins.sh.tmp jenkins.sh

sed -i "s/GITHUB_WEBHOOK_ID=\"\*\*\*\"/GITHUB_WEBHOOK_ID=\"$GITHUB_WEBHOOK_ID\"/" jenkins.sh
sed -i "s/GITHUB_WEBHOOK_SECRET=\"\*\*\*\"/GITHUB_WEBHOOK_SECRET=\"$GITHUB_WEBHOOK_SECRET\"/" jenkins.sh

sed -i "s/GIT_CREDENTIALS_ID=\"\*\*\*\"/GIT_CREDENTIALS_ID=\"$GIT_CREDENTIALS_ID\"/" jenkins.sh
sed -i "s/GIT_USERNAME=\"\*\*\*\"/GIT_USERNAME=\"$GIT_USERNAME\"/" jenkins.sh
sed -i "s/GIT_PERSONAL_ACCESS_TOKEN=\"\*\*\*\"/GIT_PERSONAL_ACCESS_TOKEN=\"$GIT_PERSONAL_ACCESS_TOKEN\"/" jenkins.sh
sed -i "s/TF_GCP_INFRA_PIPELINE_NAME=\"\*\*\*\"/TF_GCP_INFRA_PIPELINE_NAME=\"$TF_GCP_INFRA_PIPELINE_NAME\"/" jenkins.sh
sed -i "s/TF_GCP_INFRA_REPO_NAME=\"\*\*\*\"/TF_GCP_INFRA_REPO_NAME=\"$TF_GCP_INFRA_REPO_NAME\"/" jenkins.sh

sed -i "s/DOCKER_CREDENTIALS_ID=\"\*\*\*\"/DOCKER_CREDENTIALS_ID=\"$DOCKER_CREDENTIALS_ID\"/" jenkins.sh
sed -i "s/DOCKER_USERNAME=\"\*\*\*\"/DOCKER_USERNAME=\"$DOCKER_USERNAME\"/" jenkins.sh
sed -i "s/DOCKER_PERSONAL_ACCESS_TOKEN=\"\*\*\*\"/DOCKER_PERSONAL_ACCESS_TOKEN=\"$DOCKER_PERSONAL_ACCESS_TOKEN\"/" jenkins.sh
sed -i "s/STATIC_SITE_PIPELINE_NAME=\"\*\*\*\"/STATIC_SITE_PIPELINE_NAME=\"$STATIC_SITE_PIPELINE_NAME\"/" jenkins.sh
sed -i "s/STATIC_SITE_ACTIONS_PIPELINE_NAME=\"\*\*\*\"/STATIC_SITE_ACTIONS_PIPELINE_NAME=\"$STATIC_SITE_ACTIONS_PIPELINE_NAME\"/" jenkins.sh
sed -i "s/STATIC_SITE_REPO_NAME=\"\*\*\*\"/STATIC_SITE_REPO_NAME=\"$STATIC_SITE_REPO_NAME\"/" jenkins.sh
sed -i "s/STATIC_SITE_K8S_PIPELINE_NAME=\"\*\*\*\"/STATIC_SITE_K8S_PIPELINE_NAME=\"$STATIC_SITE_K8S_PIPELINE_NAME\"/" jenkins.sh
sed -i "s/STATIC_SITE_K8S_ACTIONS_PIPELINE_NAME=\"\*\*\*\"/STATIC_SITE_K8S_ACTIONS_PIPELINE_NAME=\"$STATIC_SITE_K8S_ACTIONS_PIPELINE_NAME\"/" jenkins.sh
sed -i "s/STATIC_SITE_K8S_REPO_NAME=\"\*\*\*\"/STATIC_SITE_K8S_REPO_NAME=\"$STATIC_SITE_K8S_REPO_NAME\"/" jenkins.sh
sed -i "s/WEBAPP_PIPELINE_NAME=\"\*\*\*\"/WEBAPP_PIPELINE_NAME=\"$WEBAPP_PIPELINE_NAME\"/" jenkins.sh
sed -i "s/WEBAPP_ACTIONS_PIPELINE_NAME=\"\*\*\*\"/WEBAPP_ACTIONS_PIPELINE_NAME=\"$WEBAPP_ACTIONS_PIPELINE_NAME\"/" jenkins.sh
sed -i "s/WEBAPP_REPO_NAME=\"\*\*\*\"/WEBAPP_REPO_NAME=\"$WEBAPP_REPO_NAME\"/" jenkins.sh
sed -i "s/WEBAPP_HELLO_WORLD_PIPELINE_NAME=\"\*\*\*\"/WEBAPP_HELLO_WORLD_PIPELINE_NAME=\"$WEBAPP_HELLO_WORLD_PIPELINE_NAME\"/" jenkins.sh
sed -i "s/WEBAPP_HELLO_WORLD_ACTIONS_PIPELINE_NAME=\"\*\*\*\"/WEBAPP_HELLO_WORLD_ACTIONS_PIPELINE_NAME=\"$WEBAPP_HELLO_WORLD_ACTIONS_PIPELINE_NAME\"/" jenkins.sh
sed -i "s/WEBAPP_HELLO_WORLD_REPO_NAME=\"\*\*\*\"/WEBAPP_HELLO_WORLD_REPO_NAME=\"$WEBAPP_HELLO_WORLD_REPO_NAME\"/" jenkins.sh
