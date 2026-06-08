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
                if ! command -v sf >/dev/null 2>&1; then
                    npm install --global @salesforce/cli
                fi

                sf --version
                '''
            }
        }

        stage('Validate') {
            steps {
                sh '''
                sf project deploy validate \
                --source-dir force-app
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                sf project deploy start \
                --source-dir force-app
                '''
            }
        }

        stage('Tests') {
            steps {
                sh '''
                sf apex run test \
                --tests HelloWorldTest \
                --result-format human \
                --wait 10
                '''
            }
        }

    }
}
