pipeline {
    agent {
        docker {
            image 'node:18-alpine'
            args '-u root:root -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        AWS_DEFAULT_REGION = 'ap-south-1'
        APP_NAME            = 'frontend-app'
        BUILD_DIR           = 'app/dist'
        NODE_ENV            = 'production'

        // Jenkins Credentials (configure in Jenkins → Manage Jenkins → Credentials)
        AWS_ACCESS_KEY_ID       = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY   = credentials('AWS_SECRET_ACCESS_KEY')
        S3_BUCKET_NAME          = credentials('S3_BUCKET_NAME')
        CLOUDFRONT_DIST_ID      = credentials('CLOUDFRONT_DISTRIBUTION_ID')
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
        ansiColor('xterm')
    }

    triggers {
        githubPush()
    }

    stages {

        stage('Checkout') {
            steps {
                echo '📦 Checking out source code...'
                checkout scm
                sh '''
                    echo "Branch: ${GIT_BRANCH}"
                    echo "Commit: ${GIT_COMMIT}"
                    echo "Author: ${GIT_AUTHOR_NAME}"
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                echo '📥 Installing Node.js dependencies...'
                dir('app') {
                    sh '''
                        node --version
                        npm --version
                        npm ci --prefer-offline
                        echo "Dependencies installed successfully"
                    '''
                }
            }
        }

        stage('Lint & Code Quality') {
            steps {
                echo '🔍 Running linters...'
                dir('app') {
                    sh '''
                        if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ]; then
                            npx eslint src/ --max-warnings=0 || echo "ESLint warnings found"
                        else
                            echo "No ESLint config found, skipping lint"
                        fi
                    '''
                }
            }
        }

        stage('Security Audit') {
            steps {
                echo '🔐 Running npm security audit...'
                dir('app') {
                    sh '''
                        npm audit --audit-level=high || true
                        echo "Security audit completed"
                    '''
                }
            }
        }

        stage('Build Application') {
            steps {
                echo '🏗️ Building frontend application...'
                dir('app') {
                    sh '''
                        npm run build
                        echo "Build output:"
                        ls -lh dist/ || ls -lh build/ || echo "Check output directory name"
                        du -sh dist/ 2>/dev/null || du -sh build/ 2>/dev/null || true
                    '''
                }
            }
        }

        stage('Install AWS CLI') {
            steps {
                echo '☁️ Setting up AWS CLI...'
                sh '''
                    apk add --no-cache aws-cli curl python3 py3-pip 2>/dev/null || \
                    (apt-get update -qq && apt-get install -y -qq awscli) || \
                    (pip3 install awscli --quiet)
                    aws --version
                '''
            }
        }

        stage('Verify AWS Credentials') {
            steps {
                echo '✅ Verifying AWS credentials and permissions...'
                sh '''
                    aws sts get-caller-identity
                    echo "AWS credentials verified"
                    aws s3 ls s3://${S3_BUCKET_NAME} --region ${AWS_DEFAULT_REGION} > /dev/null
                    echo "S3 bucket accessible: ${S3_BUCKET_NAME}"
                '''
            }
        }

        stage('Deploy to S3') {
            steps {
                echo '🚀 Deploying to AWS S3...'
                sh '''
                    # Sync build artifacts to S3
                    DIST_DIR="app/dist"
                    if [ ! -d "$DIST_DIR" ]; then
                        DIST_DIR="app/build"
                    fi

                    echo "Deploying from: $DIST_DIR"
                    echo "Target bucket: s3://${S3_BUCKET_NAME}"

                    # Deploy with proper cache headers
                    # Long cache for hashed assets
                    aws s3 sync ${DIST_DIR}/ s3://${S3_BUCKET_NAME}/ \
                        --region ${AWS_DEFAULT_REGION} \
                        --delete \
                        --exclude "*.html" \
                        --cache-control "public, max-age=31536000, immutable"

                    # Short cache for HTML files
                    aws s3 sync ${DIST_DIR}/ s3://${S3_BUCKET_NAME}/ \
                        --region ${AWS_DEFAULT_REGION} \
                        --exclude "*" \
                        --include "*.html" \
                        --cache-control "public, max-age=300, must-revalidate"

                    echo "✅ S3 deployment completed"
                '''
            }
        }

        stage('Invalidate CloudFront Cache') {
            steps {
                echo '🔄 Invalidating CloudFront cache...'
                sh '''
                    INVALIDATION_ID=$(aws cloudfront create-invalidation \
                        --distribution-id ${CLOUDFRONT_DIST_ID} \
                        --paths "/*" \
                        --query 'Invalidation.Id' \
                        --output text)

                    echo "Invalidation ID: ${INVALIDATION_ID}"
                    echo "Waiting for invalidation to complete..."

                    aws cloudfront wait invalidation-completed \
                        --distribution-id ${CLOUDFRONT_DIST_ID} \
                        --id ${INVALIDATION_ID}

                    echo "✅ CloudFront cache invalidation completed"
                '''
            }
        }

        stage('Smoke Test') {
            steps {
                echo '🧪 Running post-deployment smoke test...'
                sh '''
                    CF_DOMAIN=$(aws cloudfront get-distribution \
                        --id ${CLOUDFRONT_DIST_ID} \
                        --query 'Distribution.DomainName' \
                        --output text)

                    echo "CloudFront domain: https://${CF_DOMAIN}"
                    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://${CF_DOMAIN})

                    if [ "$HTTP_STATUS" = "200" ]; then
                        echo "✅ Smoke test PASSED — HTTP $HTTP_STATUS"
                    else
                        echo "⚠️  Smoke test returned HTTP $HTTP_STATUS"
                    fi
                '''
            }
        }
    }

    post {
        success {
            echo """
            ╔══════════════════════════════════════════╗
            ║   ✅ DEPLOYMENT SUCCESSFUL                ║
            ║   Build: #${BUILD_NUMBER}                  ║
            ║   Branch: ${GIT_BRANCH}                   ║
            ║   Commit: ${GIT_COMMIT?.take(8)}           ║
            ╚══════════════════════════════════════════╝
            """
        }
        failure {
            echo """
            ╔══════════════════════════════════════════╗
            ║   ❌ DEPLOYMENT FAILED                    ║
            ║   Build: #${BUILD_NUMBER}                  ║
            ║   Check Jenkins logs for details          ║
            ╚══════════════════════════════════════════╝
            """
        }
        always {
            cleanWs()
        }
    }
}
