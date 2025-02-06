#!/bin/bash

sudo apt update -y
sudo apt install -y maven unzip wget tar apt-transport-https ca-certificates curl
sudo apt install -y nginx certbot python3-certbot-nginx

sudo systemctl enable nginx
sudo systemctl start nginx

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

echo "Installing Terraform Inside Jenkins..."

# Create terraform directory with proper permissions
sudo mkdir -p /var/lib/jenkins/tools/terraform
sudo chown -R jenkins:jenkins /var/lib/jenkins/tools/terraform
sudo chmod -R 755 /var/lib/jenkins/tools/terraform

# Download and install Terraform as jenkins user
sudo -u jenkins bash -c '
cd /var/lib/jenkins/tools/terraform || exit 1
wget -q https://releases.hashicorp.com/terraform/1.4.6/terraform_1.4.6_linux_amd64.zip
unzip terraform_1.4.6_linux_amd64.zip
chmod +x terraform
rm terraform_1.4.6_linux_amd64.zip
'

# Add Terraform to system PATH
echo 'export PATH=/var/lib/jenkins/tools/terraform:$PATH' | sudo tee /etc/profile.d/terraform.sh
sudo chmod +x /etc/profile.d/terraform.sh

# Add to Jenkins environment
sudo -u jenkins bash -c 'echo "export PATH=/var/lib/jenkins/tools/terraform:$PATH" >> /var/lib/jenkins/.bashrc'
sudo -u jenkins bash -c 'echo "export PATH=/var/lib/jenkins/tools/terraform:$PATH" >> /var/lib/jenkins/.profile'

# Verify installation
sudo -u jenkins bash -c 'cd /var/lib/jenkins/tools/terraform && ./terraform --version'

echo "Creating Groovy Script to setup Jenkins Multibranch Pipeline..."
cat <<EOF > create_multibranch_pipeline.groovy
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import org.jenkinsci.plugins.github_branch_source.*
import org.jenkinsci.plugins.workflow.multibranch.*
import jenkins.branch.*
import hudson.util.Secret

// Jenkins instance
def jenkins = Jenkins.instance

// GitHub App Credentials Details
def credentialsId = "CloudJenkinsBuild"
def appId = "1135780"
def privateKey = Secret.fromString('''-----BEGIN PRIVATE KEY-----
                                      MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC4L/3fXkV7hWmO
                                      NKs/spAHQygKWlVrhVNMwpOroeE4vbZK2mW7nzqVfDj2mWb3Q1BkeKBEq1M0rh9t
                                      eqwfM44bOdFOj6+TtLL1H06L7Ddp2S+nH9w1OIsdBsv5mv6YTCbcfh9TZP226y/f
                                      r88Jre7m3PcJiSKtRnl1wrg/ynp2wle9rC6zw9Qb57b/6+FKWAPTuqs/b+GKdyLQ
                                      BimoesDa+IVprc3mtIYWXzVVSc8boobaWf1n3t1mv16gqJwLwtHhDP9xHfYwdmmZ
                                      Tjb3xKX5gKgBjbOCPA528rL/g43Z0YOVQ4X7H1TR+QSEKxypo8D/eM12Q1t20Tjh
                                      wUl4BTzxAgMBAAECggEBAKv+NKU2lM+Jf04JpLgweAowDd3NCOMEdwrAz8B/w56G
                                      mQlA86rGP6CDhXXRPbM7qoCHm7FEAsi4qCRFXyErtVF7JhakWiIlpM780w4aIIy5
                                      AKShPbJ9AHq0dBi7QW7Z/Zf8NihbsAf1ipjoxP6W6vWt9Ql0g2sm2hi7Ie5/luf5
                                      cPZi4Ozi2M78opij+R7JTN50Vxlp/jQXImQYERYMQM+THKAMukL24LRiUJXpFfTE
                                      YeNmQhsH1cEKOVCGulzD8I2T+G2hreBsdMf4Xv2JZ9dtOU2ZJwTw0C2RfhmakBzV
                                      vAqwPatby++hD7Ga/cPxB/JNKj8h+LgTy7TdAmW001kCgYEA3PvslwMKeC69Tpkb
                                      Dxda1A/y/nXHKGKj56X9w8/86zOg0xtBFoCXlb0pUKkDR4fi0+QMRWKtSneYbb6v
                                      ISWQx3qarxtCqv6lGaGX5Yoge6NFHQTEwBNjEWx8QR09rW63JcQ4pJm3XM/s8rkt
                                      4UL4apydSask/8ZnQJ2LrLlPTjsCgYEA1V9v1Mx1kX8Xvo+IM+XCED//XwYtHOxV
                                      0Ya82ovoyR0Dw9zBMIKyJQRwZQcPOHueeUtSONJ+g/JOaV7u5sBJXD3AL+rtOYhu
                                      saRpoPEdpX5T5wnK6hZkPZfyQkiSuN+aqw1ncYiFT/LMsp2B1x5sTmp3VakVaCeZ
                                      EIR+M4cNksMCgYEAxiVuQwoK/TCLtko6pRF/895JODlLVr770N5Z6JY6ZntonWI2
                                      voKXaUCwJw8lTaJelThKeHy+faM3HlB4n/QbGYKp6JE8+i5Sw+TNWpi7/6CqfBam
                                      hMPddOYdlBUwFK7NsiN71ruuWp5mDE5XAUEXliDQOBoplt7D/oBFmZ6fqbkCgYBb
                                      M0utfSbTZatUfC0PYaktIO2aRB2MO0gDIsAd+acqLwio8vZwMazLPbZ8uCO9VLlL
                                      xvIB75a79xmk2DrszkuM7afz00pKSRJnQ4sSi3zMe86I9hqRK7j0yrl1s2djNc/6
                                      RORuFphEr9bmkYQp2osYiVEwf/Dyb9pwwPDgPV2D2QKBgCCefx12fOI/+COsnsqR
                                      b6IicvgyczSyNsZmYaYM5VfsFkMBopafu9RNn0JviDBx4YR8lvTvtHd2FDXx6dMZ
                                      UFdcdyhdN+8FSzWl3oi0Z5p9rdeR1qm4ZyW9nANx7zR6+5VcsZjvvG3U9Qzeijxa
                                      lYRsmLsk6MDQIqHLNdhiB3Dw
                                      -----END PRIVATE KEY-----
''')

// Check if credentials exist
def store = jenkins.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
def existingCredentials = store.getCredentials(Domain.global()).find { it.id == credentialsId }

if (!existingCredentials) {
    println "Creating new GitHub App credentials..."
    def creds = new GitHubAppCredentials(CredentialsScope.GLOBAL, credentialsId, "GitHub App", appId, privateKey)
    store.addCredentials(Domain.global(), creds)
} else {
    println "GitHub App credentials already exist."
}

// Pipeline Configuration
def pipelineName = "tf-gcp-infra-pipeline"
def repoOwner = "cyse7125-sp25-team01"
def repoName = "tf-gcp-infra"

// Check if pipeline exists
def existingJob = jenkins.getItem(pipelineName)
if (!existingJob) {
    println "Creating Multibranch Pipeline: ${pipelineName}"

    def mbp = new WorkflowMultiBranchProject(jenkins, pipelineName)

    def source = new GitHubSCMSource(repoOwner, repoName)
    source.setCredentialsId(credentialsId)
    source.setTraits([new BranchDiscoveryTrait(3), new OriginPullRequestDiscoveryTrait(2)])

    mbp.getSourcesList().add(new BranchSource(source))
    mbp.setProjectFactory(new WorkflowBranchProjectFactory())

    jenkins.add(mbp, pipelineName)
    mbp.scheduleBuild()
}

jenkins.save()
EOF

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /tmp/initialAdminPassword) groovy = < create_multibranch_pipeline.groovy
echo "Jenkins Multibranch Pipeline setup complete!"



