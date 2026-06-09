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
                ARCH="$(uname -m)"

                if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
                    SF_CLI_ARCH="arm64"
                else
                    SF_CLI_ARCH="x64"
                fi

                rm -rf sf-cli sf-linux-*.tar.gz
                mkdir -p sf-cli
                curl -L -o sf-linux-${SF_CLI_ARCH}.tar.gz https://developer.salesforce.com/media/salesforce-cli/sf/channels/stable/sf-linux-${SF_CLI_ARCH}.tar.gz
                tar -xzf sf-linux-${SF_CLI_ARCH}.tar.gz -C sf-cli --strip-components 1

                ./sf-cli/bin/sf --version
                '''
            }
        }

        stage('Authenticate Salesforce') {
            steps {
                withCredentials([string(credentialsId: 'salesforce-auth-url', variable: 'SF_AUTH_URL')]) {
                    sh '''
                    set +x
                    trap 'rm -f sf-auth-url.txt' EXIT
                    CLEAN_SF_AUTH_URL="$(printf "%s" "$SF_AUTH_URL" | tr -d '\\r\\n')"

                    if [ -z "$CLEAN_SF_AUTH_URL" ]; then
                        echo "Salesforce auth URL credential is empty. Check Jenkins credential ID: salesforce-auth-url"
                        exit 1
                    fi

                    case "$CLEAN_SF_AUTH_URL" in
                        force://*@*.salesforce.com|force://*@*.force.com|force://*@*.cloudforce.com)
                            ;;
                        *)
                            echo "Invalid Salesforce auth URL. Jenkins secret must be the full Sfdx Auth Url starting with force:// and ending with your Salesforce domain."
                            exit 1
                            ;;
                    esac

                    printf "%s" "$CLEAN_SF_AUTH_URL" > sf-auth-url.txt
                    ./sf-cli/bin/sf org login sfdx-url \
                    --sfdx-url-file sf-auth-url.txt \
                    --alias target-org \
                    --set-default
                    rm -f sf-auth-url.txt
                    echo "Salesforce authentication completed."
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

        stage('Install Docker') {
            steps {
                sh '''
                set -e

                if command -v docker >/dev/null 2>&1; then
                    echo "Docker already installed: $(docker --version)"
                    exit 0
                fi

                if command -v apt-get >/dev/null 2>&1; then
                    echo "Detected apt-get, installing docker.io"
                    sudo apt-get update
                    sudo apt-get install -y docker.io
                    sudo systemctl enable --now docker || true
                    sudo usermod -aG docker "${USER:-jenkins}" || true
                elif command -v yum >/dev/null 2>&1; then
                    echo "Detected yum, installing docker-ce"
                    sudo yum install -y yum-utils
                    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || true
                    sudo yum install -y docker-ce docker-ce-cli containerd.io || true
                    sudo systemctl enable --now docker || true
                    sudo usermod -aG docker "${USER:-jenkins}" || true
                elif command -v apk >/dev/null 2>&1; then
                    echo "Detected apk, installing docker"
                    sudo apk add --no-cache docker
                    sudo rc-update add docker boot || true
                    sudo service docker start || true
                    sudo addgroup "${USER:-jenkins}" docker || true
                else
                    echo "No supported package manager found. Please install Docker on this node manually."
                    exit 0
                fi

                echo "Verifying docker..."
                for i in 1 2 3 4 5; do
                    if sudo docker info >/dev/null 2>&1; then
                        echo "Docker is available"
                        break
                    fi
                    sleep 1
                done

                docker --version || true
                '''
            }
        }

        stage('Check Docker') {
            steps {
                sh '''
                docker --version
                docker info
                '''
            }
        }

        stage('Build nginx Image') {
            steps {
                sh '''
                docker build \
                -t salesforce-devops-demo-nginx:latest \
                nginx
                '''
            }
        }

        stage('Deploy nginx Container') {
            steps {
                sh '''
                docker stop salesforce-devops-demo-nginx || true
                docker rm salesforce-devops-demo-nginx || true

                docker run -d \
                --name salesforce-devops-demo-nginx \
                -p 8081:80 \
                salesforce-devops-demo-nginx:latest
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
