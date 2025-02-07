#!/bin/bash

sudo apt update -y
sudo apt install -y maven unzip wget tar apt-transport-https ca-certificates curl
sudo apt install -y nginx certbot python3-certbot-nginx

sudo systemctl enable nginx
sudo systemctl start nginx

# Install Docker
echo "Installing Docker..."
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker jenkins
sudo chmod 666 /var/run/docker.sock
newgrp docker

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

if sudo [ -f "$ADMIN_PASSWORD_FILE" ]; then
    sudo cat "$ADMIN_PASSWORD_FILE" | sudo tee /tmp/initialAdminPassword > /dev/null
    echo "InitialAdminPassword stored in /tmp/initialAdminPassword"
else
    echo "InitialAdminPassword file not found!"
    exit 1
fi

wget http://localhost:8080/jnlpJars/jenkins-cli.jar -O jenkins-cli.jar

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) install-plugin workflow-aggregator job-dsl groovy mailer git credentials-binding build-timeout junit artifactdeployer blueocean github golang maven-plugin kubernetes pipeline-utility-steps role-strategy oidc-provider -restart

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
import org.jenkinsci.plugins.github_branch_source.*
import jenkins.branch.*
import org.jenkinsci.plugins.workflow.multibranch.*
import com.cloudbees.plugins.credentials.common.*

// Jenkins instance
def jenkins = Jenkins.instance

// Credentials setup
def credentialsId = "$CREDENTIALS_ID"
def gitUsername = "$GIT_USERNAME"
def gitPersonalAccessToken = "$GIT_PERSONAL_ACCESS_TOKEN"

// Create credentials if not exists
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

// Pipeline setup
def pipelineName = "$PIPELINE_NAME"
def repoOwner = "$REPO_OWNER"
def repoName = "$REPO_NAME"

def existingJob = jenkins.getItem(pipelineName)

if (!existingJob) {
    println "Creating GitHub Multibranch Pipeline: ${pipelineName}"

    // Create a new multibranch pipeline
    def multibranchProject = jenkins.createProject(WorkflowMultiBranchProject.class, pipelineName)

    // GitHub SCM Source
    def githubSource = new GitHubSCMSource(repoOwner, repoName)
    githubSource.credentialsId = credentialsId  // Keep this as-is per your request

    // Enable behaviors:
    def traits = [
        new OriginPullRequestDiscoveryTrait(2), // Discover PRs from origin: Merge with target branch
        new ForkPullRequestDiscoveryTrait(2, new ForkPullRequestDiscoveryTrait.TrustPermission()) // Discover PRs from forks: Trust users with Admin/Write permission
    ]

    // Fix: Use addAll() instead of replaceBy()
    githubSource.getTraits().addAll(traits)

    // Add GitHub source to pipeline
    multibranchProject.getSourcesList().add(new BranchSource(githubSource))

    // Schedule build
    multibranchProject.scheduleBuild()

    println "GitHub Multibranch Pipeline setup complete!"
} else {
    println "Pipeline '${pipelineName}' already exists."
}

jenkins.save()
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < create_multibranch_pipeline.groovy
echo "Jenkins Multibranch Pipeline setup complete!"



