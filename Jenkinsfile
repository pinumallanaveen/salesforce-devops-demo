pipeline {

    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('PMD Scan') {
            steps {
                sh '''
                pmd check \
                -d force-app \
                -R category/apex/bestpractices.xml
                '''
            }
        }

        stage('Validate') {
            steps {
                sh '''
                sf project deploy validate
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                sf project deploy start
                '''
            }
        }

        stage('Tests') {
            steps {
                sh '''
                sf apex run test
                '''
            }
        }

    }
}