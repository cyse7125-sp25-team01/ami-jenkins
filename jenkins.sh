#!/bin/bash

sudo apt update -y
sudo apt install -y zip unzip wget tar apt-transport-https ca-certificates curl 
sudo apt-get update && sudo apt-get -y install golang-go 
sudo apt install -y nginx certbot python3-certbot-nginx npm
sudo npm install -g @commitlint/config-conventional @commitlint/cli 

sudo systemctl enable nginx
sudo systemctl start nginx

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g semantic-release
sudo npm install -g @semantic-release/commit-analyzer @semantic-release/github @semantic-release/release-notes-generator

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" -y
sudo apt install docker-ce -y
sudo systemctl start docker
sudo systemctl enable docker

sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update -y
sudo apt-get install terraform -y

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo apt-key add -
sudo add-apt-repository -y https://packages.adoptium.net/artifactory/deb
sudo apt update -y
sudo apt install -y temurin-21-jdk

sudo update-alternatives --set java /usr/lib/jvm/temurin-21-jdk-amd64/bin/java
sudo update-alternatives --set javac /usr/lib/jvm/temurin-21-jdk-amd64/bin/javac

sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
/etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update -y
sudo apt install -y jenkins


sudo systemctl start jenkins
sudo systemctl enable jenkins

sleep 30

ADMIN_PASSWORD_FILE="/var/lib/jenkins/secrets/initialAdminPassword"

ADMIN_USERNAME="***"
ADMIN_PASSWORD="***"
ADMIN_FIRSTNAME="***"
ADMIN_LASTNAME="***"
ADMIN_FULLNAME="$ADMIN_FIRSTNAME $ADMIN_LASTNAME"
ADMIN_EMAIL="***"
JENKINS_LOCATION_URL="***"
DOMAIN="***"
NGINX_CONF="***"
NGINX_LINK="***"
REPO_OWNER="***"
GITHUB_WEBHOOK_ID="***"
GITHUB_WEBHOOK_SECRET="***"
GIT_CREDENTIALS_ID="***"
GIT_USERNAME="***"
GIT_PERSONAL_ACCESS_TOKEN="***"
TF_GCP_INFRA_PIPELINE_NAME="***"
TF_GCP_INFRA_REPO_NAME="***"
DOCKER_CREDENTIALS_ID="***"
DOCKER_USERNAME="***"
DOCKER_PERSONAL_ACCESS_TOKEN="***"
STATIC_SITE_PIPELINE_NAME="***"
STATIC_SITE_ACTIONS_PIPELINE_NAME="***"
STATIC_SITE_REPO_NAME="***"
STATIC_SITE_K8S_PIPELINE_NAME="***"
STATIC_SITE_K8S_ACTIONS_PIPELINE_NAME="***"
STATIC_SITE_K8S_REPO_NAME="***"
WEBAPP_PIPELINE_NAME="***"
WEBAPP_ACTIONS_PIPELINE_NAME="***"
WEBAPP_REPO_NAME="***"
WEBAPP_HELLO_WORLD_PIPELINE_NAME="***"
WEBAPP_HELLO_WORLD_ACTIONS_PIPELINE_NAME="***"
WEBAPP_HELLO_WORLD_REPO_NAME="***"
WEBAPP_HELLO_WORLD_K8S_ACTIONS_PIPELINE_NAME="***"
WEBAPP_HELLO_WORLD_K8S_REPO_NAME="***"
API_SERVER_REPO_NAME="***"
API_SERVER_PIPELINE_NAME="***"
API_SERVER_ACTIONS_PIPELINE_NAME="***"
API_DB_REPO_NAME="***"
API_DB_PIPELINE_NAME="***"
API_DB_ACTIONS_PIPELINE_NAME="***"
HELM_CHARTS_REPO_NAME="***"
HELM_CHARTS_PIPELINE_NAME="***"
HELM_CHARTS_ACTIONS_PIPELINE_NAME="***"
TRACE_DB_REPO_NAME="***"
TRACE_DB_PIPELINE_NAME="***"
TRACE_DB_ACTIONS_PIPELINE_NAME="***"
TRACE_SERVER_REPO_NAME="***"
TRACE_SERVER_PIPELINE_NAME="***"
TRACE_SERVER_ACTIONS_PIPELINE_NAME="***"


if sudo [ -f "$ADMIN_PASSWORD_FILE" ]; then
    sudo cat "$ADMIN_PASSWORD_FILE" | sudo tee /tmp/initialAdminPassword > /dev/null
    echo "InitialAdminPassword stored in /tmp/initialAdminPassword"
else
    echo "InitialAdminPassword file not found!"
    exit 1
fi

wget http://localhost:8080/jnlpJars/jenkins-cli.jar -O jenkins-cli.jar

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) install-plugin workflow-aggregator pipeline-stage-view ws-cleanup pipeline-rest-api job-dsl groovy mailer git credentials-binding build-timeout junit artifactdeployer blueocean github golang maven-plugin kubernetes pipeline-utility-steps role-strategy oidc-provider docker-plugin conventional-commits docker-workflow  -restart

echo "Waiting for Jenkins to restart..."
sleep 60

cat <<EOF > setup_complete.groovy
import jenkins.model.*
import hudson.security.*
import hudson.tasks.Mailer

def instance = Jenkins.getInstance()

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
def username = "$ADMIN_USERNAME"
def password = "$ADMIN_PASSWORD"
def fullName = "$ADMIN_FULLNAME"
def email = "$ADMIN_EMAIL"


def user = hudsonRealm.createAccount(username, password)
user.setFullName(fullName)
user.addProperty(new Mailer.UserProperty(email))

instance.setSecurityRealm(hudsonRealm)
instance.save()

JenkinsLocationConfiguration.get().setAdminAddress("$ADMIN_EMAIL")
JenkinsLocationConfiguration.get().setUrl("$JENKINS_LOCATION_URL")
JenkinsLocationConfiguration.get().save()

println "Admin user created successfully."
EOF

echo "Creating admin user..."
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < setup_complete.groovy
sudo sed -i 's|Environment="JAVA_OPTS=-Djava.awt.headless=true|Environment="JAVA_OPTS=-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false|' /usr/lib/systemd/system/jenkins.service
sudo usermod -aG docker jenkins
sudo systemctl daemon-reload
sudo systemctl restart jenkins
echo "Waiting for Jenkins to finalize setup..."

sudo bash -c "cat > $NGINX_CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF


sudo ln -s $NGINX_CONF $NGINX_LINK 2>/dev/null || true

echo "Testing Nginx configuration..."
sudo nginx -t
if [ $? -eq 0 ]; then
    echo "Reloading Nginx..."
    sudo systemctl reload nginx
else
    echo "Nginx configuration test failed. Exiting."
    exit 1
fi

echo "Creating Groovy Script to setup Jenkins Multibranch Pipeline..."
cat <<EOF > create_multibranch_pipeline.groovy
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.common.*
import org.jenkinsci.plugins.github_branch_source.*
import org.jenkinsci.plugins.workflow.multibranch.*
import jenkins.branch.*
import hudson.util.Secret
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl

def jenkins = Jenkins.instance

def credentialsId = "$GIT_CREDENTIALS_ID"
def gitUsername = "$GIT_USERNAME"
def gitPersonalAccessToken = "$GIT_PERSONAL_ACCESS_TOKEN"
def pipelineName = "$TF_GCP_INFRA_PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$TF_GCP_INFRA_REPO_NAME"
def github_webhook_secretId = "$GITHUB_WEBHOOK_ID"
def github_webhook_secret = "$GITHUB_WEBHOOK_SECRET"

def store = SystemCredentialsProvider.getInstance().getStore()
def existingCredentials = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == credentialsId }

if (!existingCredentials) {
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "GitHub Personal Access Token",
        gitUsername,
        gitPersonalAccessToken
    )
    store.addCredentials(Domain.global(), credentials)
}
def existingWebhookSecret = CredentialsProvider.lookupCredentials(
    StringCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == github_webhook_secretId }

if (!existingWebhookSecret) {
    def webhookSecret = new StringCredentialsImpl(
        CredentialsScope.GLOBAL,
        github_webhook_secretId,
        "GitHub Webhook Secret",
        Secret.fromString(github_webhook_secret)
    )
    store.addCredentials(Domain.global(), webhookSecret)
}

def existingJob = jenkins.getItem(pipelineName)

if (!existingJob) {
    println("Creating GitHub Multibranch Pipeline: "+ pipelineName)

    def multibranchProject = jenkins.createProject(WorkflowMultiBranchProject.class, pipelineName)
    
    def githubSource = new GitHubSCMSource(repoOwner, repoName)
    githubSource.credentialsId = credentialsId  // Keep this as-is per your request
    
    def traits = [
        new OriginPullRequestDiscoveryTrait(2), // Discover PRs from origin: Merge with target branch
        new ForkPullRequestDiscoveryTrait(2, new ForkPullRequestDiscoveryTrait.TrustPermission()) // Discover PRs from forks: Trust users with Admin/Write permission
    ]
    
    githubSource.getTraits().addAll(traits)
    
    multibranchProject.getSourcesList().add(new BranchSource(githubSource))

    multibranchProject.scheduleBuild()

    println "GitHub Multibranch Pipeline setup complete!"
} else {
    println("Pipeline "+ pipelineName +" already exists.")
}

jenkins.save()
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < create_multibranch_pipeline.groovy
echo "Jenkins Multibranch Pipeline setup complete!"


cat <<EOF > static-site-pipeline.groovy
import jenkins.model.*
import hudson.model.*
import org.jenkinsci.plugins.workflow.job.*
import org.jenkinsci.plugins.workflow.cps.*
import hudson.plugins.git.*
import hudson.util.Secret
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import jenkins.plugins.git.*
import hudson.triggers.*
import hudson.plugins.git.extensions.impl.CloneOption
import hudson.triggers.SCMTrigger
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import com.cloudbees.jenkins.GitHubPushTrigger

def jenkins = Jenkins.instance

def jobName = "$STATIC_SITE_PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$STATIC_SITE_REPO_NAME"
def credentialsId = "$DOCKER_CREDENTIALS_ID"
def gitcredentialsId = "$GIT_CREDENTIALS_ID"
def dockerUsername = "$DOCKER_USERNAME"
def dockerPersonalAccessToken = "$DOCKER_PERSONAL_ACCESS_TOKEN"
def github_webhook_secretId = "$GITHUB_WEBHOOK_ID"
def github_webhook_secret = "$GITHUB_WEBHOOK_SECRET"
def repoUrl = "https://github.com/"+repoOwner+"/"+repoName+".git"


def store = SystemCredentialsProvider.getInstance().getStore()
def existingCredentials = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == credentialsId }

if (!existingCredentials) {
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "Docker Hub Personal Access Token",
        dockerUsername,
        dockerPersonalAccessToken
    )
    store.addCredentials(Domain.global(), credentials)
}

def existingWebhookSecret = CredentialsProvider.lookupCredentials(
    StringCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == github_webhook_secretId }

if (!existingWebhookSecret) {
    def webhookSecret = new StringCredentialsImpl(
        CredentialsScope.GLOBAL,
        github_webhook_secretId,
        "GitHub Webhook Secret",
        Secret.fromString(github_webhook_secret)
    )
    store.addCredentials(Domain.global(), webhookSecret)
}

def job = jenkins.getItem(jobName)
if (job) {
    println("Job "+ jobName+ "already exists. Deleting and recreating it.")
    job.delete()
}

job = jenkins.createProject(WorkflowJob, jobName)
job.setDescription("Builds and pushes a multi-platform container image (Linux & Windows) to a private Docker Hub repository.")

def scm = new GitSCM(repoUrl)
scm.branches = [new BranchSpec("*/main")]
scm.userRemoteConfigs = [new UserRemoteConfig(repoUrl, null, null, gitcredentialsId)]

def definition = new CpsScmFlowDefinition(scm, "JenkinsfileDocker")
job.definition = definition

def webhookSecretFromJenkins = CredentialsProvider.lookupCredentials(
    StringCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == github_webhook_secretId }?.getSecret().getPlainText()

if (!webhookSecretFromJenkins) {
    println("Warning: GitHub webhook secret not found in Jenkins credentials store!")
} else {
    def githubTrigger = new GitHubPushTrigger()
    job.addTrigger(githubTrigger)
}

def trigger = new SCMTrigger("")
job.addTrigger(trigger)
job.save()
trigger.start(job, false)
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < static-site-pipeline.groovy
echo "Jenkins Pipeline setup complete!"


echo "Creating Groovy Script to setup Jenkins Multibranch Pipeline webapp hello world k8s..."
cat <<EOF > create_multibranch_pipeline_webapp-hello-world-k8s.groovy
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.common.*
import org.jenkinsci.plugins.github_branch_source.*
import org.jenkinsci.plugins.workflow.multibranch.*
import jenkins.branch.*
import hudson.util.Secret
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl

def jenkins = Jenkins.instance

def credentialsId = "$GIT_CREDENTIALS_ID"
def gitUsername = "$GIT_USERNAME"
def gitPersonalAccessToken = "$GIT_PERSONAL_ACCESS_TOKEN"
def pipelineName = "$WEBAPP_HELLO_WORLD_K8S_ACTIONS_PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$WEBAPP_HELLO_WORLD_K8S_REPO_NAME"

def store = SystemCredentialsProvider.getInstance().getStore()
def existingCredentials = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == credentialsId }

if (!existingCredentials) {
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "GitHub Personal Access Token",
        gitUsername,
        gitPersonalAccessToken
    )
    store.addCredentials(Domain.global(), credentials)
}

def existingJob = jenkins.getItem(pipelineName)

if (!existingJob) {
    println("Creating GitHub Multibranch Pipeline: "+ pipelineName)

    def multibranchProject = jenkins.createProject(WorkflowMultiBranchProject.class, pipelineName)
    
    def githubSource = new GitHubSCMSource(repoOwner, repoName)
    githubSource.credentialsId = credentialsId  // Keep this as-is per your request
    def traits = [
        new OriginPullRequestDiscoveryTrait(2), // Discover PRs from origin: Merge with target branch
        new ForkPullRequestDiscoveryTrait(2, new ForkPullRequestDiscoveryTrait.TrustPermission()) // Discover PRs from forks: Trust users with Admin/Write permission
    ]
    
    githubSource.getTraits().addAll(traits)
    
    multibranchProject.getSourcesList().add(new BranchSource(githubSource))
    def projectFactory = new WorkflowBranchProjectFactory()
    projectFactory.setScriptPath("Jenkinsfile")
    multibranchProject.setProjectFactory(projectFactory)
    multibranchProject.scheduleBuild()

    println "GitHub Multibranch Pipeline setup complete!"
} else {
    println("Pipeline "+ pipelineName +" already exists.")
}

jenkins.save()
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < create_multibranch_pipeline_webapp-hello-world-k8s.groovy
echo "Jenkins Multibranch Pipeline setup complete - webapp-hello-world-k8s!"

echo "Creating Groovy Script to setup Jenkins Multibranch Pipeline Static site..."
cat <<EOF > create_multibranch_pipeline_static_site.groovy
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.common.*
import org.jenkinsci.plugins.github_branch_source.*
import org.jenkinsci.plugins.workflow.multibranch.*
import jenkins.branch.*
import hudson.util.Secret
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl

def jenkins = Jenkins.instance

def credentialsId = "$GIT_CREDENTIALS_ID"
def gitUsername = "$GIT_USERNAME"
def gitPersonalAccessToken = "$GIT_PERSONAL_ACCESS_TOKEN"
def pipelineName = "$STATIC_SITE_ACTIONS_PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$STATIC_SITE_REPO_NAME"

def store = SystemCredentialsProvider.getInstance().getStore()
def existingCredentials = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == credentialsId }

if (!existingCredentials) {
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "GitHub Personal Access Token",
        gitUsername,
        gitPersonalAccessToken
    )
    store.addCredentials(Domain.global(), credentials)
}

def existingJob = jenkins.getItem(pipelineName)

if (!existingJob) {
    println("Creating GitHub Multibranch Pipeline: "+ pipelineName)

    def multibranchProject = jenkins.createProject(WorkflowMultiBranchProject.class, pipelineName)
    
    def githubSource = new GitHubSCMSource(repoOwner, repoName)
    githubSource.credentialsId = credentialsId  // Keep this as-is per your request
    def traits = [
        new OriginPullRequestDiscoveryTrait(2), // Discover PRs from origin: Merge with target branch
        new ForkPullRequestDiscoveryTrait(2, new ForkPullRequestDiscoveryTrait.TrustPermission()) // Discover PRs from forks: Trust users with Admin/Write permission
    ]
    
    githubSource.getTraits().addAll(traits)
    
    multibranchProject.getSourcesList().add(new BranchSource(githubSource))
    def projectFactory = new WorkflowBranchProjectFactory()
    projectFactory.setScriptPath("Jenkinsfile")
    multibranchProject.setProjectFactory(projectFactory)
    multibranchProject.scheduleBuild()

    println "GitHub Multibranch Pipeline setup complete!"
} else {
    println("Pipeline "+ pipelineName +" already exists.")
}

jenkins.save()
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < create_multibranch_pipeline_static_site.groovy
echo "Jenkins Multibranch Pipeline setup complete - Static-Site!"

echo "Creating Groovy Script to setup Jenkins Multibranch Pipeline Static site K8s..."
cat <<EOF > create_multibranch_pipeline_static_site_k8s.groovy
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.common.*
import org.jenkinsci.plugins.github_branch_source.*
import org.jenkinsci.plugins.workflow.multibranch.*
import jenkins.branch.*
import hudson.util.Secret
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl

def jenkins = Jenkins.instance

def credentialsId = "$GIT_CREDENTIALS_ID"
def gitUsername = "$GIT_USERNAME"
def gitPersonalAccessToken = "$GIT_PERSONAL_ACCESS_TOKEN"
def pipelineName = "$STATIC_SITE_K8S_ACTIONS_PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$STATIC_SITE_K8S_REPO_NAME"

def store = SystemCredentialsProvider.getInstance().getStore()
def existingCredentials = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == credentialsId }

if (!existingCredentials) {
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "GitHub Personal Access Token",
        gitUsername,
        gitPersonalAccessToken
    )
    store.addCredentials(Domain.global(), credentials)
}

def existingJob = jenkins.getItem(pipelineName)

if (!existingJob) {
    println("Creating GitHub Multibranch Pipeline: "+ pipelineName)

    def multibranchProject = jenkins.createProject(WorkflowMultiBranchProject.class, pipelineName)
    
    def githubSource = new GitHubSCMSource(repoOwner, repoName)
    githubSource.credentialsId = credentialsId  // Keep this as-is per your request
    
    def traits = [
        new OriginPullRequestDiscoveryTrait(2), // Discover PRs from origin: Merge with target branch
        new ForkPullRequestDiscoveryTrait(2, new ForkPullRequestDiscoveryTrait.TrustPermission()) // Discover PRs from forks: Trust users with Admin/Write permission
    ]
    
    githubSource.getTraits().addAll(traits)
    
    multibranchProject.getSourcesList().add(new BranchSource(githubSource))

    multibranchProject.scheduleBuild()

    println "GitHub Multibranch Pipeline setup complete!"
} else {
    println("Pipeline "+ pipelineName +" already exists.")
}

jenkins.save()
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < create_multibranch_pipeline_static_site_k8s.groovy
echo "Jenkins Multibranch Pipeline setup complete static site k8s!"

echo "Creating Groovy Script to setup Jenkins Multibranch Pipeline webapp..."
cat <<EOF > create_multibranch_pipeline_webapp.groovy
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.common.*
import org.jenkinsci.plugins.github_branch_source.*
import org.jenkinsci.plugins.workflow.multibranch.*
import jenkins.branch.*
import hudson.util.Secret
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl

def jenkins = Jenkins.instance

def credentialsId = "$GIT_CREDENTIALS_ID"
def gitUsername = "$GIT_USERNAME"
def gitPersonalAccessToken = "$GIT_PERSONAL_ACCESS_TOKEN"
def pipelineName = "$WEBAPP_ACTIONS_PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$WEBAPP_REPO_NAME"

def store = SystemCredentialsProvider.getInstance().getStore()
def existingCredentials = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == credentialsId }

if (!existingCredentials) {
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "GitHub Personal Access Token",
        gitUsername,
        gitPersonalAccessToken
    )
    store.addCredentials(Domain.global(), credentials)
}

def existingJob = jenkins.getItem(pipelineName)

if (!existingJob) {
    println("Creating GitHub Multibranch Pipeline: "+ pipelineName)

    def multibranchProject = jenkins.createProject(WorkflowMultiBranchProject.class, pipelineName)
    
    def githubSource = new GitHubSCMSource(repoOwner, repoName)
    githubSource.credentialsId = credentialsId  // Keep this as-is per your request
    
    def traits = [
        new OriginPullRequestDiscoveryTrait(2), // Discover PRs from origin: Merge with target branch
        new ForkPullRequestDiscoveryTrait(2, new ForkPullRequestDiscoveryTrait.TrustPermission()) // Discover PRs from forks: Trust users with Admin/Write permission
    ]
    
    githubSource.getTraits().addAll(traits)
    
    multibranchProject.getSourcesList().add(new BranchSource(githubSource))
    def projectFactory = new WorkflowBranchProjectFactory()
    projectFactory.setScriptPath("Jenkinsfile")
    multibranchProject.setProjectFactory(projectFactory)
    multibranchProject.scheduleBuild()

    println "GitHub Multibranch Pipeline setup complete!"
} else {
    println("Pipeline "+ pipelineName +" already exists.")
}

jenkins.save()
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < create_multibranch_pipeline_webapp.groovy
echo "Jenkins Multibranch Pipeline setup complete Webapp!"

echo "Creating Groovy Script to setup Jenkins Multibranch Pipeline Webapp hello world..."
cat <<EOF > create_multibranch_pipeline_webapp_hello_world.groovy
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.common.*
import org.jenkinsci.plugins.github_branch_source.*
import org.jenkinsci.plugins.workflow.multibranch.*
import jenkins.branch.*
import hudson.util.Secret
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl

def jenkins = Jenkins.instance

def credentialsId = "$GIT_CREDENTIALS_ID"
def gitUsername = "$GIT_USERNAME"
def gitPersonalAccessToken = "$GIT_PERSONAL_ACCESS_TOKEN"
def pipelineName = "$WEBAPP_HELLO_WORLD_ACTIONS_PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$WEBAPP_HELLO_WORLD_REPO_NAME"

def store = SystemCredentialsProvider.getInstance().getStore()
def existingCredentials = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == credentialsId }

if (!existingCredentials) {
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "GitHub Personal Access Token",
        gitUsername,
        gitPersonalAccessToken
    )
    store.addCredentials(Domain.global(), credentials)
}

def existingJob = jenkins.getItem(pipelineName)

if (!existingJob) {
    println("Creating GitHub Multibranch Pipeline: "+ pipelineName)

    def multibranchProject = jenkins.createProject(WorkflowMultiBranchProject.class, pipelineName)
    
    def githubSource = new GitHubSCMSource(repoOwner, repoName)
    githubSource.credentialsId = credentialsId  // Keep this as-is per your request
    
    def traits = [
        new OriginPullRequestDiscoveryTrait(2), // Discover PRs from origin: Merge with target branch
        new ForkPullRequestDiscoveryTrait(2, new ForkPullRequestDiscoveryTrait.TrustPermission()) // Discover PRs from forks: Trust users with Admin/Write permission
    ]
    
    githubSource.getTraits().addAll(traits)
    
    multibranchProject.getSourcesList().add(new BranchSource(githubSource))
    def projectFactory = new WorkflowBranchProjectFactory()
    projectFactory.setScriptPath("Jenkinsfile")
    multibranchProject.setProjectFactory(projectFactory)
    multibranchProject.scheduleBuild()

    println "GitHub Multibranch Pipeline setup complete!"
} else {
    println("Pipeline "+ pipelineName +" already exists.")
}

jenkins.save()
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < create_multibranch_pipeline_webapp_hello_world.groovy
echo "Jenkins Multibranch Pipeline setup complete Webapp Hello World!"

cat <<EOF > webapp-pipeline.groovy
import jenkins.model.*
import hudson.model.*
import org.jenkinsci.plugins.workflow.job.*
import org.jenkinsci.plugins.workflow.cps.*
import hudson.plugins.git.*
import hudson.util.Secret
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import jenkins.plugins.git.*
import hudson.triggers.*
import hudson.plugins.git.extensions.impl.CloneOption
import hudson.triggers.SCMTrigger
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import com.cloudbees.jenkins.GitHubPushTrigger

def jenkins = Jenkins.instance

def jobName = "$WEBAPP_PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$WEBAPP_REPO_NAME"
def credentialsId = "$DOCKER_CREDENTIALS_ID"
def gitcredentialsId = "$GIT_CREDENTIALS_ID"
def dockerUsername = "$DOCKER_USERNAME"
def dockerPersonalAccessToken = "$DOCKER_PERSONAL_ACCESS_TOKEN"
def github_webhook_secretId = "$GITHUB_WEBHOOK_ID"
def github_webhook_secret = "$GITHUB_WEBHOOK_SECRET"
def repoUrl = "https://github.com/"+repoOwner+"/"+repoName+".git"


def store = SystemCredentialsProvider.getInstance().getStore()
def existingCredentials = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == credentialsId }

if (!existingCredentials) {
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "Docker Hub Personal Access Token",
        dockerUsername,
        dockerPersonalAccessToken
    )
    store.addCredentials(Domain.global(), credentials)
}

def existingWebhookSecret = CredentialsProvider.lookupCredentials(
    StringCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == github_webhook_secretId }

if (!existingWebhookSecret) {
    def webhookSecret = new StringCredentialsImpl(
        CredentialsScope.GLOBAL,
        github_webhook_secretId,
        "GitHub Webhook Secret",
        Secret.fromString(github_webhook_secret)
    )
    store.addCredentials(Domain.global(), webhookSecret)
}

def job = jenkins.getItem(jobName)
if (job) {
    println("Job "+ jobName+ "already exists. Deleting and recreating it.")
    job.delete()
}

job = jenkins.createProject(WorkflowJob, jobName)
job.setDescription("Builds and pushes a multi-platform container image (Linux & Windows) to a private Docker Hub repository.")

def scm = new GitSCM(repoUrl)
scm.branches = [new BranchSpec("*/main")]
scm.userRemoteConfigs = [new UserRemoteConfig(repoUrl, null, null, gitcredentialsId)]

def definition = new CpsScmFlowDefinition(scm, "JenkinsfileDocker")
job.definition = definition

def webhookSecretFromJenkins = CredentialsProvider.lookupCredentials(
    StringCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == github_webhook_secretId }?.getSecret().getPlainText()

if (!webhookSecretFromJenkins) {
    println("Warning: GitHub webhook secret not found in Jenkins credentials store!")
} else {
    def githubTrigger = new GitHubPushTrigger()
    job.addTrigger(githubTrigger)
}

def trigger = new SCMTrigger("")
job.addTrigger(trigger)
job.save()
trigger.start(job, false)
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < webapp-pipeline.groovy
echo "Jenkins Pipeline setup complete Webapp!"


cat <<EOF > webapp-hello-world-pipeline.groovy
import jenkins.model.*
import hudson.model.*
import org.jenkinsci.plugins.workflow.job.*
import org.jenkinsci.plugins.workflow.cps.*
import hudson.plugins.git.*
import hudson.util.Secret
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import jenkins.plugins.git.*
import hudson.triggers.*
import hudson.plugins.git.extensions.impl.CloneOption
import hudson.triggers.SCMTrigger
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import com.cloudbees.jenkins.GitHubPushTrigger

def jenkins = Jenkins.instance

def jobName = "$WEBAPP_HELLO_WORLD_PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$WEBAPP_HELLO_WORLD_REPO_NAME"
def credentialsId = "$DOCKER_CREDENTIALS_ID"
def gitcredentialsId = "$GIT_CREDENTIALS_ID"
def dockerUsername = "$DOCKER_USERNAME"
def dockerPersonalAccessToken = "$DOCKER_PERSONAL_ACCESS_TOKEN"
def github_webhook_secretId = "$GITHUB_WEBHOOK_ID"
def github_webhook_secret = "$GITHUB_WEBHOOK_SECRET"
def repoUrl = "https://github.com/"+repoOwner+"/"+repoName+".git"


def store = SystemCredentialsProvider.getInstance().getStore()
def existingCredentials = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == credentialsId }

if (!existingCredentials) {
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "Docker Hub Personal Access Token",
        dockerUsername,
        dockerPersonalAccessToken
    )
    store.addCredentials(Domain.global(), credentials)
}

def existingWebhookSecret = CredentialsProvider.lookupCredentials(
    StringCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == github_webhook_secretId }

if (!existingWebhookSecret) {
    def webhookSecret = new StringCredentialsImpl(
        CredentialsScope.GLOBAL,
        github_webhook_secretId,
        "GitHub Webhook Secret",
        Secret.fromString(github_webhook_secret)
    )
    store.addCredentials(Domain.global(), webhookSecret)
}

def job = jenkins.getItem(jobName)
if (job) {
    println("Job "+ jobName+ "already exists. Deleting and recreating it.")
    job.delete()
}

job = jenkins.createProject(WorkflowJob, jobName)
job.setDescription("Builds and pushes a multi-platform container image (Linux & Windows) to a private Docker Hub repository.")

def scm = new GitSCM(repoUrl)
scm.branches = [new BranchSpec("*/main")]
scm.userRemoteConfigs = [new UserRemoteConfig(repoUrl, null, null, gitcredentialsId)]

def definition = new CpsScmFlowDefinition(scm, "JenkinsfileDocker")
job.definition = definition

def webhookSecretFromJenkins = CredentialsProvider.lookupCredentials(
    StringCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == github_webhook_secretId }?.getSecret().getPlainText()

if (!webhookSecretFromJenkins) {
    println("Warning: GitHub webhook secret not found in Jenkins credentials store!")
} else {
    def githubTrigger = new GitHubPushTrigger()
    job.addTrigger(githubTrigger)
}

def trigger = new SCMTrigger("")
job.addTrigger(trigger)
job.save()
trigger.start(job, false)
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < webapp-hello-world-pipeline.groovy
echo "Jenkins Pipeline setup complete Webapp!"


echo "Creating Groovy Script to setup Jenkins Multibranch Pipeline api server..."
cat <<EOF > create_multibranch_pipeline_api_server.groovy
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.common.*
import org.jenkinsci.plugins.github_branch_source.*
import org.jenkinsci.plugins.workflow.multibranch.*
import jenkins.branch.*
import hudson.util.Secret
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl

def jenkins = Jenkins.instance

def credentialsId = "$GIT_CREDENTIALS_ID"
def gitUsername = "$GIT_USERNAME"
def gitPersonalAccessToken = "$GIT_PERSONAL_ACCESS_TOKEN"
def pipelineName = "$API_SERVER_ACTIONS_PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$API_SERVER_REPO_NAME"

def store = SystemCredentialsProvider.getInstance().getStore()
def existingCredentials = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == credentialsId }

if (!existingCredentials) {
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "GitHub Personal Access Token",
        gitUsername,
        gitPersonalAccessToken
    )
    store.addCredentials(Domain.global(), credentials)
}

def existingJob = jenkins.getItem(pipelineName)

if (!existingJob) {
    println("Creating GitHub Multibranch Pipeline: "+ pipelineName)

    def multibranchProject = jenkins.createProject(WorkflowMultiBranchProject.class, pipelineName)
    
    def githubSource = new GitHubSCMSource(repoOwner, repoName)
    githubSource.credentialsId = credentialsId  // Keep this as-is per your request
    
    def traits = [
        new OriginPullRequestDiscoveryTrait(2), // Discover PRs from origin: Merge with target branch
        new ForkPullRequestDiscoveryTrait(2, new ForkPullRequestDiscoveryTrait.TrustPermission()) // Discover PRs from forks: Trust users with Admin/Write permission
    ]
    
    githubSource.getTraits().addAll(traits)
    
    multibranchProject.getSourcesList().add(new BranchSource(githubSource))
    def projectFactory = new WorkflowBranchProjectFactory()
    projectFactory.setScriptPath("Jenkinsfile")
    multibranchProject.setProjectFactory(projectFactory)
    multibranchProject.scheduleBuild()

    println "GitHub Multibranch Pipeline setup complete!"
} else {
    println("Pipeline "+ pipelineName +" already exists.")
}

jenkins.save()
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < create_multibranch_pipeline_api_server.groovy
echo "Jenkins Multibranch Pipeline setup complete api server actions"


cat <<EOF > api-server-pipeline.groovy
import jenkins.model.*
import hudson.model.*
import org.jenkinsci.plugins.workflow.job.*
import org.jenkinsci.plugins.workflow.cps.*
import hudson.plugins.git.*
import hudson.util.Secret
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import jenkins.plugins.git.*
import hudson.triggers.*
import hudson.plugins.git.extensions.impl.CloneOption
import hudson.triggers.SCMTrigger
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import com.cloudbees.jenkins.GitHubPushTrigger

def jenkins = Jenkins.instance

def jobName = "$API_SERVER_PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$API_SERVER_REPO_NAME"
def credentialsId = "$DOCKER_CREDENTIALS_ID"
def gitcredentialsId = "$GIT_CREDENTIALS_ID"
def dockerUsername = "$DOCKER_USERNAME"
def dockerPersonalAccessToken = "$DOCKER_PERSONAL_ACCESS_TOKEN"
def github_webhook_secretId = "$GITHUB_WEBHOOK_ID"
def github_webhook_secret = "$GITHUB_WEBHOOK_SECRET"
def repoUrl = "https://github.com/"+repoOwner+"/"+repoName+".git"


def store = SystemCredentialsProvider.getInstance().getStore()
def existingCredentials = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == credentialsId }

if (!existingCredentials) {
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "Docker Hub Personal Access Token",
        dockerUsername,
        dockerPersonalAccessToken
    )
    store.addCredentials(Domain.global(), credentials)
}

def existingWebhookSecret = CredentialsProvider.lookupCredentials(
    StringCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == github_webhook_secretId }

if (!existingWebhookSecret) {
    def webhookSecret = new StringCredentialsImpl(
        CredentialsScope.GLOBAL,
        github_webhook_secretId,
        "GitHub Webhook Secret",
        Secret.fromString(github_webhook_secret)
    )
    store.addCredentials(Domain.global(), webhookSecret)
}

def job = jenkins.getItem(jobName)
if (job) {
    println("Job "+ jobName+ "already exists. Deleting and recreating it.")
    job.delete()
}

job = jenkins.createProject(WorkflowJob, jobName)
job.setDescription("Builds and pushes a multi-platform container image (Linux & Windows) to a private Docker Hub repository.")

def scm = new GitSCM(repoUrl)
scm.branches = [new BranchSpec("*/main")]
scm.userRemoteConfigs = [new UserRemoteConfig(repoUrl, null, null, gitcredentialsId)]

def definition = new CpsScmFlowDefinition(scm, "JenkinsfileDocker")
job.definition = definition

def webhookSecretFromJenkins = CredentialsProvider.lookupCredentials(
    StringCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == github_webhook_secretId }?.getSecret().getPlainText()

if (!webhookSecretFromJenkins) {
    println("Warning: GitHub webhook secret not found in Jenkins credentials store!")
} else {
    def githubTrigger = new GitHubPushTrigger()
    job.addTrigger(githubTrigger)
}

def trigger = new SCMTrigger("")
job.addTrigger(trigger)
job.save()
trigger.start(job, false)
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < api-server-pipeline.groovy
echo "Jenkins Pipeline setup complete api server!"

echo "Creating Groovy Script to setup Jenkins Multibranch Pipeline api db..."
cat <<EOF > create_multibranch_pipeline_api_db.groovy
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.common.*
import org.jenkinsci.plugins.github_branch_source.*
import org.jenkinsci.plugins.workflow.multibranch.*
import jenkins.branch.*
import hudson.util.Secret
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl

def jenkins = Jenkins.instance

def credentialsId = "$GIT_CREDENTIALS_ID"
def gitUsername = "$GIT_USERNAME"
def gitPersonalAccessToken = "$GIT_PERSONAL_ACCESS_TOKEN"
def pipelineName = "$API_DB_ACTIONS_PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$API_DB_REPO_NAME"

def store = SystemCredentialsProvider.getInstance().getStore()
def existingCredentials = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == credentialsId }

if (!existingCredentials) {
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "GitHub Personal Access Token",
        gitUsername,
        gitPersonalAccessToken
    )
    store.addCredentials(Domain.global(), credentials)
}

def existingJob = jenkins.getItem(pipelineName)

if (!existingJob) {
    println("Creating GitHub Multibranch Pipeline: "+ pipelineName)

    def multibranchProject = jenkins.createProject(WorkflowMultiBranchProject.class, pipelineName)
    
    def githubSource = new GitHubSCMSource(repoOwner, repoName)
    githubSource.credentialsId = credentialsId  // Keep this as-is per your request
    
    def traits = [
        new OriginPullRequestDiscoveryTrait(2), // Discover PRs from origin: Merge with target branch
        new ForkPullRequestDiscoveryTrait(2, new ForkPullRequestDiscoveryTrait.TrustPermission()) // Discover PRs from forks: Trust users with Admin/Write permission
    ]
    
    githubSource.getTraits().addAll(traits)
    
    multibranchProject.getSourcesList().add(new BranchSource(githubSource))
    def projectFactory = new WorkflowBranchProjectFactory()
    projectFactory.setScriptPath("Jenkinsfile")
    multibranchProject.setProjectFactory(projectFactory)
    multibranchProject.scheduleBuild()

    println "GitHub Multibranch Pipeline setup complete!"
} else {
    println("Pipeline "+ pipelineName +" already exists.")
}

jenkins.save()
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < create_multibranch_pipeline_api_db.groovy
echo "Jenkins Multibranch Pipeline setup complete api db actions"


cat <<EOF > api-db-pipeline.groovy
import jenkins.model.*
import hudson.model.*
import org.jenkinsci.plugins.workflow.job.*
import org.jenkinsci.plugins.workflow.cps.*
import hudson.plugins.git.*
import hudson.util.Secret
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import jenkins.plugins.git.*
import hudson.triggers.*
import hudson.plugins.git.extensions.impl.CloneOption
import hudson.triggers.SCMTrigger
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import com.cloudbees.jenkins.GitHubPushTrigger

def jenkins = Jenkins.instance

def jobName = "$API_DB_PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$API_DB_REPO_NAME"
def credentialsId = "$DOCKER_CREDENTIALS_ID"
def gitcredentialsId = "$GIT_CREDENTIALS_ID"
def dockerUsername = "$DOCKER_USERNAME"
def dockerPersonalAccessToken = "$DOCKER_PERSONAL_ACCESS_TOKEN"
def github_webhook_secretId = "$GITHUB_WEBHOOK_ID"
def github_webhook_secret = "$GITHUB_WEBHOOK_SECRET"
def repoUrl = "https://github.com/"+repoOwner+"/"+repoName+".git"


def store = SystemCredentialsProvider.getInstance().getStore()
def existingCredentials = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == credentialsId }

if (!existingCredentials) {
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "Docker Hub Personal Access Token",
        dockerUsername,
        dockerPersonalAccessToken
    )
    store.addCredentials(Domain.global(), credentials)
}

def existingWebhookSecret = CredentialsProvider.lookupCredentials(
    StringCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == github_webhook_secretId }

if (!existingWebhookSecret) {
    def webhookSecret = new StringCredentialsImpl(
        CredentialsScope.GLOBAL,
        github_webhook_secretId,
        "GitHub Webhook Secret",
        Secret.fromString(github_webhook_secret)
    )
    store.addCredentials(Domain.global(), webhookSecret)
}

def job = jenkins.getItem(jobName)
if (job) {
    println("Job "+ jobName+ "already exists. Deleting and recreating it.")
    job.delete()
}

job = jenkins.createProject(WorkflowJob, jobName)
job.setDescription("Builds and pushes a multi-platform container image (Linux & Windows) to a private Docker Hub repository.")

def scm = new GitSCM(repoUrl)
scm.branches = [new BranchSpec("*/main")]
scm.userRemoteConfigs = [new UserRemoteConfig(repoUrl, null, null, gitcredentialsId)]

def definition = new CpsScmFlowDefinition(scm, "JenkinsfileDocker")
job.definition = definition

def webhookSecretFromJenkins = CredentialsProvider.lookupCredentials(
    StringCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == github_webhook_secretId }?.getSecret().getPlainText()

if (!webhookSecretFromJenkins) {
    println("Warning: GitHub webhook secret not found in Jenkins credentials store!")
} else {
    def githubTrigger = new GitHubPushTrigger()
    job.addTrigger(githubTrigger)
}

def trigger = new SCMTrigger("")
job.addTrigger(trigger)
job.save()
trigger.start(job, false)
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < api-db-pipeline.groovy
echo "Jenkins Pipeline setup complete api db!"

echo "Creating Groovy Script to setup Jenkins Multibranch Pipeline helm charts..."
cat <<EOF > create_multibranch_pipeline_helm_charts.groovy
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.common.*
import org.jenkinsci.plugins.github_branch_source.*
import org.jenkinsci.plugins.workflow.multibranch.*
import jenkins.branch.*
import hudson.util.Secret
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl

def jenkins = Jenkins.instance

def credentialsId = "$GIT_CREDENTIALS_ID"
def gitUsername = "$GIT_USERNAME"
def gitPersonalAccessToken = "$GIT_PERSONAL_ACCESS_TOKEN"
def pipelineName = "$HELM_CHARTS_ACTIONS_PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$HELM_CHARTS_REPO_NAME"

def store = SystemCredentialsProvider.getInstance().getStore()
def existingCredentials = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == credentialsId }

if (!existingCredentials) {
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "GitHub Personal Access Token",
        gitUsername,
        gitPersonalAccessToken
    )
    store.addCredentials(Domain.global(), credentials)
}

def existingJob = jenkins.getItem(pipelineName)

if (!existingJob) {
    println("Creating GitHub Multibranch Pipeline: "+ pipelineName)

    def multibranchProject = jenkins.createProject(WorkflowMultiBranchProject.class, pipelineName)
    
    def githubSource = new GitHubSCMSource(repoOwner, repoName)
    githubSource.credentialsId = credentialsId  // Keep this as-is per your request
    
    def traits = [
        new OriginPullRequestDiscoveryTrait(2), // Discover PRs from origin: Merge with target branch
        new ForkPullRequestDiscoveryTrait(2, new ForkPullRequestDiscoveryTrait.TrustPermission()) // Discover PRs from forks: Trust users with Admin/Write permission
    ]
    
    githubSource.getTraits().addAll(traits)
    
    multibranchProject.getSourcesList().add(new BranchSource(githubSource))
    def projectFactory = new WorkflowBranchProjectFactory()
    projectFactory.setScriptPath("Jenkinsfile")
    multibranchProject.setProjectFactory(projectFactory)
    multibranchProject.scheduleBuild()

    println "GitHub Multibranch Pipeline setup complete!"
} else {
    println("Pipeline "+ pipelineName +" already exists.")
}

jenkins.save()
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < create_multibranch_pipeline_helm_charts.groovy
echo "Jenkins Multibranch Pipeline setup complete helm charts actions"


cat <<EOF > helm-charts-pipeline.groovy
import jenkins.model.*
import hudson.model.*
import org.jenkinsci.plugins.workflow.job.*
import org.jenkinsci.plugins.workflow.cps.*
import hudson.plugins.git.*
import hudson.util.Secret
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import jenkins.plugins.git.*
import hudson.triggers.*
import hudson.plugins.git.extensions.impl.CloneOption
import hudson.triggers.SCMTrigger
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import com.cloudbees.jenkins.GitHubPushTrigger

def jenkins = Jenkins.instance

def jobName = "$HELM_CHARTS_PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$HELM_CHARTS_REPO_NAME"
def credentialsId = "$DOCKER_CREDENTIALS_ID"
def gitcredentialsId = "$GIT_CREDENTIALS_ID"
def dockerUsername = "$DOCKER_USERNAME"
def dockerPersonalAccessToken = "$DOCKER_PERSONAL_ACCESS_TOKEN"
def github_webhook_secretId = "$GITHUB_WEBHOOK_ID"
def github_webhook_secret = "$GITHUB_WEBHOOK_SECRET"
def repoUrl = "https://github.com/"+repoOwner+"/"+repoName+".git"


def store = SystemCredentialsProvider.getInstance().getStore()
def existingCredentials = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == credentialsId }

if (!existingCredentials) {
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "Docker Hub Personal Access Token",
        dockerUsername,
        dockerPersonalAccessToken
    )
    store.addCredentials(Domain.global(), credentials)
}

def existingWebhookSecret = CredentialsProvider.lookupCredentials(
    StringCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == github_webhook_secretId }

if (!existingWebhookSecret) {
    def webhookSecret = new StringCredentialsImpl(
        CredentialsScope.GLOBAL,
        github_webhook_secretId,
        "GitHub Webhook Secret",
        Secret.fromString(github_webhook_secret)
    )
    store.addCredentials(Domain.global(), webhookSecret)
}

def job = jenkins.getItem(jobName)
if (job) {
    println("Job "+ jobName+ "already exists. Deleting and recreating it.")
    job.delete()
}

job = jenkins.createProject(WorkflowJob, jobName)
job.setDescription("Builds and pushes a multi-platform container image (Linux & Windows) to a private Docker Hub repository.")

def scm = new GitSCM(repoUrl)
scm.branches = [new BranchSpec("*/main")]
scm.userRemoteConfigs = [new UserRemoteConfig(repoUrl, null, null, gitcredentialsId)]

def definition = new CpsScmFlowDefinition(scm, "JenkinsfileHelm")
job.definition = definition

def webhookSecretFromJenkins = CredentialsProvider.lookupCredentials(
    StringCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == github_webhook_secretId }?.getSecret().getPlainText()

if (!webhookSecretFromJenkins) {
    println("Warning: GitHub webhook secret not found in Jenkins credentials store!")
} else {
    def githubTrigger = new GitHubPushTrigger()
    job.addTrigger(githubTrigger)
}

def trigger = new SCMTrigger("")
job.addTrigger(trigger)
job.save()
trigger.start(job, false)
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < helm-charts-pipeline.groovy
echo "Jenkins Pipeline setup complete helm charts!"


echo "Creating Groovy Script to setup Jenkins Multibranch Pipeline trace db..."
cat <<EOF > create_multibranch_pipeline_trace_db.groovy
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.common.*
import org.jenkinsci.plugins.github_branch_source.*
import org.jenkinsci.plugins.workflow.multibranch.*
import jenkins.branch.*
import hudson.util.Secret
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl

def jenkins = Jenkins.instance

def credentialsId = "$GIT_CREDENTIALS_ID"
def gitUsername = "$GIT_USERNAME"
def gitPersonalAccessToken = "$GIT_PERSONAL_ACCESS_TOKEN"
def pipelineName = "$TRACE_DB_ACTIONS_PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$TRACE_DB_REPO_NAME"

def store = SystemCredentialsProvider.getInstance().getStore()
def existingCredentials = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == credentialsId }

if (!existingCredentials) {
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "GitHub Personal Access Token",
        gitUsername,
        gitPersonalAccessToken
    )
    store.addCredentials(Domain.global(), credentials)
}

def existingJob = jenkins.getItem(pipelineName)

if (!existingJob) {
    println("Creating GitHub Multibranch Pipeline: "+ pipelineName)

    def multibranchProject = jenkins.createProject(WorkflowMultiBranchProject.class, pipelineName)
    
    def githubSource = new GitHubSCMSource(repoOwner, repoName)
    githubSource.credentialsId = credentialsId  // Keep this as-is per your request
    
    def traits = [
        new OriginPullRequestDiscoveryTrait(2), // Discover PRs from origin: Merge with target branch
        new ForkPullRequestDiscoveryTrait(2, new ForkPullRequestDiscoveryTrait.TrustPermission()) // Discover PRs from forks: Trust users with Admin/Write permission
    ]
    
    githubSource.getTraits().addAll(traits)
    
    multibranchProject.getSourcesList().add(new BranchSource(githubSource))
    def projectFactory = new WorkflowBranchProjectFactory()
    projectFactory.setScriptPath("Jenkinsfile")
    multibranchProject.setProjectFactory(projectFactory)
    multibranchProject.scheduleBuild()

    println "GitHub Multibranch Pipeline setup complete!"
} else {
    println("Pipeline "+ pipelineName +" already exists.")
}

jenkins.save()
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < create_multibranch_pipeline_trace_db.groovy
echo "Jenkins Multibranch Pipeline setup complete trace db actions"


cat <<EOF > trace-db-pipeline.groovy
import jenkins.model.*
import hudson.model.*
import org.jenkinsci.plugins.workflow.job.*
import org.jenkinsci.plugins.workflow.cps.*
import hudson.plugins.git.*
import hudson.util.Secret
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import jenkins.plugins.git.*
import hudson.triggers.*
import hudson.plugins.git.extensions.impl.CloneOption
import hudson.triggers.SCMTrigger
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import com.cloudbees.jenkins.GitHubPushTrigger

def jenkins = Jenkins.instance

def jobName = "$TRACE_DB_PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$TRACE_DB_REPO_NAME"
def credentialsId = "$DOCKER_CREDENTIALS_ID"
def gitcredentialsId = "$GIT_CREDENTIALS_ID"
def dockerUsername = "$DOCKER_USERNAME"
def dockerPersonalAccessToken = "$DOCKER_PERSONAL_ACCESS_TOKEN"
def github_webhook_secretId = "$GITHUB_WEBHOOK_ID"
def github_webhook_secret = "$GITHUB_WEBHOOK_SECRET"
def repoUrl = "https://github.com/"+repoOwner+"/"+repoName+".git"


def store = SystemCredentialsProvider.getInstance().getStore()
def existingCredentials = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == credentialsId }

if (!existingCredentials) {
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "Docker Hub Personal Access Token",
        dockerUsername,
        dockerPersonalAccessToken
    )
    store.addCredentials(Domain.global(), credentials)
}

def existingWebhookSecret = CredentialsProvider.lookupCredentials(
    StringCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == github_webhook_secretId }

if (!existingWebhookSecret) {
    def webhookSecret = new StringCredentialsImpl(
        CredentialsScope.GLOBAL,
        github_webhook_secretId,
        "GitHub Webhook Secret",
        Secret.fromString(github_webhook_secret)
    )
    store.addCredentials(Domain.global(), webhookSecret)
}

def job = jenkins.getItem(jobName)
if (job) {
    println("Job "+ jobName+ "already exists. Deleting and recreating it.")
    job.delete()
}

job = jenkins.createProject(WorkflowJob, jobName)
job.setDescription("Builds and pushes a multi-platform container image (Linux & Windows) to a private Docker Hub repository.")

def scm = new GitSCM(repoUrl)
scm.branches = [new BranchSpec("*/main")]
scm.userRemoteConfigs = [new UserRemoteConfig(repoUrl, null, null, gitcredentialsId)]

def definition = new CpsScmFlowDefinition(scm, "JenkinsfileDocker")
job.definition = definition

def webhookSecretFromJenkins = CredentialsProvider.lookupCredentials(
    StringCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == github_webhook_secretId }?.getSecret().getPlainText()

if (!webhookSecretFromJenkins) {
    println("Warning: GitHub webhook secret not found in Jenkins credentials store!")
} else {
    def githubTrigger = new GitHubPushTrigger()
    job.addTrigger(githubTrigger)
}

def trigger = new SCMTrigger("")
job.addTrigger(trigger)
job.save()
trigger.start(job, false)
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < trace-db-pipeline.groovy
echo "Jenkins Pipeline setup complete trace db!"

echo "Creating Groovy Script to setup Jenkins Multibranch Pipeline trace server..."
cat <<EOF > create_multibranch_pipeline_trace_server.groovy
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.common.*
import org.jenkinsci.plugins.github_branch_source.*
import org.jenkinsci.plugins.workflow.multibranch.*
import jenkins.branch.*
import hudson.util.Secret
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl

def jenkins = Jenkins.instance

def credentialsId = "$GIT_CREDENTIALS_ID"
def gitUsername = "$GIT_USERNAME"
def gitPersonalAccessToken = "$GIT_PERSONAL_ACCESS_TOKEN"
def pipelineName = "$TRACE_SERVER_ACTIONS_PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$TRACE_SERVER_REPO_NAME"

def store = SystemCredentialsProvider.getInstance().getStore()
def existingCredentials = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == credentialsId }

if (!existingCredentials) {
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "GitHub Personal Access Token",
        gitUsername,
        gitPersonalAccessToken
    )
    store.addCredentials(Domain.global(), credentials)
}

def existingJob = jenkins.getItem(pipelineName)

if (!existingJob) {
    println("Creating GitHub Multibranch Pipeline: "+ pipelineName)

    def multibranchProject = jenkins.createProject(WorkflowMultiBranchProject.class, pipelineName)
    
    def githubSource = new GitHubSCMSource(repoOwner, repoName)
    githubSource.credentialsId = credentialsId  // Keep this as-is per your request
    
    def traits = [
        new OriginPullRequestDiscoveryTrait(2), // Discover PRs from origin: Merge with target branch
        new ForkPullRequestDiscoveryTrait(2, new ForkPullRequestDiscoveryTrait.TrustPermission()) // Discover PRs from forks: Trust users with Admin/Write permission
    ]
    
    githubSource.getTraits().addAll(traits)
    
    multibranchProject.getSourcesList().add(new BranchSource(githubSource))
    def projectFactory = new WorkflowBranchProjectFactory()
    projectFactory.setScriptPath("Jenkinsfile")
    multibranchProject.setProjectFactory(projectFactory)
    multibranchProject.scheduleBuild()

    println "GitHub Multibranch Pipeline setup complete!"
} else {
    println("Pipeline "+ pipelineName +" already exists.")
}

jenkins.save()
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < create_multibranch_pipeline_trace_server.groovy
echo "Jenkins Multibranch Pipeline setup complete trace server actions"


cat <<EOF > trace-server-pipeline.groovy
import jenkins.model.*
import hudson.model.*
import org.jenkinsci.plugins.workflow.job.*
import org.jenkinsci.plugins.workflow.cps.*
import hudson.plugins.git.*
import hudson.util.Secret
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import jenkins.plugins.git.*
import hudson.triggers.*
import hudson.plugins.git.extensions.impl.CloneOption
import hudson.triggers.SCMTrigger
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import com.cloudbees.jenkins.GitHubPushTrigger

def jenkins = Jenkins.instance

def jobName = "$TRACE_SERVER_PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$TRACE_SERVER_REPO_NAME"
def credentialsId = "$DOCKER_CREDENTIALS_ID"
def gitcredentialsId = "$GIT_CREDENTIALS_ID"
def dockerUsername = "$DOCKER_USERNAME"
def dockerPersonalAccessToken = "$DOCKER_PERSONAL_ACCESS_TOKEN"
def github_webhook_secretId = "$GITHUB_WEBHOOK_ID"
def github_webhook_secret = "$GITHUB_WEBHOOK_SECRET"
def repoUrl = "https://github.com/"+repoOwner+"/"+repoName+".git"


def store = SystemCredentialsProvider.getInstance().getStore()
def existingCredentials = CredentialsProvider.lookupCredentials(
    UsernamePasswordCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == credentialsId }

if (!existingCredentials) {
    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "Docker Hub Personal Access Token",
        dockerUsername,
        dockerPersonalAccessToken
    )
    store.addCredentials(Domain.global(), credentials)
}

def existingWebhookSecret = CredentialsProvider.lookupCredentials(
    StringCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == github_webhook_secretId }

if (!existingWebhookSecret) {
    def webhookSecret = new StringCredentialsImpl(
        CredentialsScope.GLOBAL,
        github_webhook_secretId,
        "GitHub Webhook Secret",
        Secret.fromString(github_webhook_secret)
    )
    store.addCredentials(Domain.global(), webhookSecret)
}

def job = jenkins.getItem(jobName)
if (job) {
    println("Job "+ jobName+ "already exists. Deleting and recreating it.")
    job.delete()
}

job = jenkins.createProject(WorkflowJob, jobName)
job.setDescription("Builds and pushes a multi-platform container image (Linux & Windows) to a private Docker Hub repository.")

def scm = new GitSCM(repoUrl)
scm.branches = [new BranchSpec("*/main")]
scm.userRemoteConfigs = [new UserRemoteConfig(repoUrl, null, null, gitcredentialsId)]

def definition = new CpsScmFlowDefinition(scm, "JenkinsfileDocker")
job.definition = definition

def webhookSecretFromJenkins = CredentialsProvider.lookupCredentials(
    StringCredentialsImpl.class,
    Jenkins.instance,
    null,
    Collections.emptyList()
).find { it.id == github_webhook_secretId }?.getSecret().getPlainText()

if (!webhookSecretFromJenkins) {
    println("Warning: GitHub webhook secret not found in Jenkins credentials store!")
} else {
    def githubTrigger = new GitHubPushTrigger()
    job.addTrigger(githubTrigger)
}

def trigger = new SCMTrigger("")
job.addTrigger(trigger)
job.save()
trigger.start(job, false)
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < trace-server-pipeline.groovy
echo "Jenkins Pipeline setup complete trace server!"


cat <<EOF > github-secret.groovy
import jenkins.model.*
import hudson.model.*
import org.jenkinsci.plugins.workflow.job.*
import org.jenkinsci.plugins.workflow.cps.*
import hudson.plugins.git.*
import hudson.util.Secret
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import jenkins.plugins.git.*
import hudson.triggers.*
import hudson.plugins.git.extensions.impl.CloneOption
import hudson.triggers.SCMTrigger
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import com.cloudbees.jenkins.GitHubPushTrigger




def credentialId = "github_token"
def secretText = "$GIT_PERSONAL_ACCESS_TOKEN" 
def description = "GitHub Personal Access Token"

def credentialsStore = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

def existingCredential = credentialsStore.getCredentials(Domain.global()).find { it.id == credentialId }
if (existingCredential) {
    println "Credential with ID '${credentialId}' already exists."
} else {
    def newCredential = new StringCredentialsImpl(
        CredentialsScope.GLOBAL, credentialId, description, new Secret(secretText)
    )
    
    credentialsStore.addCredentials(Domain.global(), newCredential)
    println "Credential '${credentialId}' created successfully."
}
EOF