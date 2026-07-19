pipeline {
    agent any

    stages {

        stage('Clone Repository') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/vinaykumarshetkar/cost-optimization.git'
            }
        }

        stage('Azure Login and Start VM') {
            steps {
                withCredentials([
                    azureServicePrincipal(
                        credentialsId: 'jenkins-azure-sp',
                        subscriptionIdVariable: 'AZ_SUBSCRIPTION_ID',
                        clientIdVariable: 'AZ_CLIENT_ID',
                        clientSecretVariable: 'AZ_CLIENT_SECRET',
                        tenantIdVariable: 'AZ_TENANT_ID'
                    )
                ]) {

                    sh '''
                    set -e

                    az --version
                    az login \
                      --service-principal \
                      --username "$AZ_CLIENT_ID" \
                      --password "$AZ_CLIENT_SECRET" \
                      --tenant "$AZ_TENANT_ID"

                    az account set --subscription "$AZ_SUBSCRIPTION_ID"

                    az account show

                    az vm status \
                      --resource-group vinay \
                      --name testVM1
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline executed successfully."
        }

        failure {
            echo "Pipeline failed. Check the console logs."
        }

        always {
            cleanWs()
        }
    }
}
