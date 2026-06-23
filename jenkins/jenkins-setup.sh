#!/bin/bash
###############################################################################
# jenkins-setup.sh — Install Jenkins + Docker + AWS CLI on Ubuntu EC2
# Run as root: sudo ./jenkins-setup.sh
# Author: Sri Charan Garikapati
###############################################################################

set -euo pipefail

echo "🚀 Starting Jenkins setup on Ubuntu..."

# ── System update ─────────────────────────────────────────────────────────────
apt-get update -y
apt-get install -y curl wget git unzip gnupg2 software-properties-common

# ── Java (Jenkins dependency) ─────────────────────────────────────────────────
echo "☕ Installing Java 17..."
apt-get install -y openjdk-17-jdk
java -version

# ── Jenkins ───────────────────────────────────────────────────────────────────
echo "🔧 Installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
    gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] \
    https://pkg.jenkins.io/debian-stable binary/" | \
    tee /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update -y
apt-get install -y jenkins

# ── Docker ────────────────────────────────────────────────────────────────────
echo "🐳 Installing Docker..."
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Add jenkins user to docker group
usermod -aG docker jenkins

# ── AWS CLI v2 ────────────────────────────────────────────────────────────────
echo "☁️ Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
aws --version

# ── Start services ────────────────────────────────────────────────────────────
systemctl enable jenkins
systemctl start jenkins
systemctl enable docker
systemctl start docker

# Wait for Jenkins to start
echo "⏳ Waiting for Jenkins to start..."
sleep 30

JENKINS_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "Not found yet")

echo ""
echo "═══════════════════════════════════════════════════"
echo "  ✅ Jenkins setup complete!"
echo "  URL     : http://$(curl -s ifconfig.me):8080"
echo "  Password: ${JENKINS_PASSWORD}"
echo "  Next steps:"
echo "  1. Open the URL, enter the password"
echo "  2. Install suggested plugins"
echo "  3. Add AWS credentials (see README)"
echo "  4. Create Pipeline job pointing to this repo"
echo "═══════════════════════════════════════════════════"
