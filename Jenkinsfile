pipeline {

    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup PMD') {
            steps {
                sh '''
                if [ ! -d pmd-bin-7.25.0 ]; then
                    curl -L -o pmd.zip https://github.com/pmd/pmd/releases/download/pmd_releases%2F7.25.0/pmd-dist-7.25.0-bin.zip
                    unzip -q pmd.zip
                fi

                ./pmd-bin-7.25.0/bin/pmd --version
                '''
            }
        }

        stage('PMD Scan') {
            steps {
                sh '''
                ./pmd-bin-7.25.0/bin/pmd check \
                -d force-app \
                -R category/apex/bestpractices.xml
                '''
            }
        }

        stage('Setup Salesforce CLI') {
            steps {
                sh '''
                if [ ! -x sf-cli/bin/sf ]; then
                    rm -rf sf-cli sf-linux-x64.tar.gz
                    mkdir -p sf-cli
                    curl -L -o sf-linux-x64.tar.gz https://developer.salesforce.com/media/salesforce-cli/sf/channels/stable/sf-linux-x64.tar.gz
                    tar -xzf sf-linux-x64.tar.gz -C sf-cli --strip-components 1
                fi

                ./sf-cli/bin/sf --version
                '''
            }
        }

        stage('Authenticate Salesforce') {
            steps {
                withCredentials([string(credentialsId: 'salesforce-auth-url', variable: 'SF_AUTH_URL')]) {
                    sh '''
                    set +x
                    printf "%s" "$SF_AUTH_URL" > sf-auth-url.txt
                    ./sf-cli/bin/sf org login sfdx-url \
                    --sfdx-url-file sf-auth-url.txt \
                    --alias target-org \
                    --set-default
                    rm -f sf-auth-url.txt
                    set -x

                    ./sf-cli/bin/sf org display --target-org target-org
                    '''
                }
            }
        }

        stage('Validate') {
            steps {
                sh '''
                ./sf-cli/bin/sf project deploy validate \
                --source-dir force-app \
                --target-org target-org
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                ./sf-cli/bin/sf project deploy start \
                --source-dir force-app \
                --target-org target-org
                '''
            }
        }

        stage('Tests') {
            steps {
                sh '''
                ./sf-cli/bin/sf apex run test \
                --target-org target-org \
                --tests HelloWorldTest \
                --result-format human \
                --wait 10
                '''
            }
        }

        stage('Logout Salesforce') {
            steps {
                sh '''
                ./sf-cli/bin/sf org logout \
                --target-org target-org \
                --no-prompt || true
                '''
            }
        }

    }
}
