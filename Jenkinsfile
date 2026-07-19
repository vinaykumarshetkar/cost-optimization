pipeline {
    agent any
    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'candidate/vinay',
                    url: 'https://github.com/vinaykumarshetkar/cost-optimization.git'
            }
        }     
stage('Azure Login and Start VM') {
    steps {
        withCredentials([
            azureServicePrincipal(
                credentialsId: 'vinay-azure-sp',
                subscriptionIdVariable: 'AZ_SUBSCRIPTION_ID',
                clientIdVariable: 'AZ_CLIENT_ID',
                clientSecretVariable: 'AZ_CLIENT_SECRET',
                tenantIdVariable: 'AZ_TENANT_ID'
            )
        ]) {
            sh '''
                az login --service-principal \
                  --username "$AZ_CLIENT_ID" \
                  --password "$AZ_CLIENT_SECRET" \
                  --tenant "$AZ_TENANT_ID"

                az account set --subscription "$AZ_SUBSCRIPTION_ID"

                az account show
                az VM start -resource-group vinay -n testVM1
            '''
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
