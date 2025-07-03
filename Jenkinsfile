pipeline {
    agent any
    environment {
        DOCKER_ID  = "jhocan55"
        DOCKER_TAG = "v.${BUILD_ID}.0"
    }
    options {
        // skip the automatic, job‐configured checkout
        skipDefaultCheckout()
    }
    stages {
        stage("Checkout") {
            steps {
                // explicitly fetch the main branch from the same repo
                checkout([
                    $class: 'GitSCM',
                    branches: [[ name: '*/master' ]],
                    userRemoteConfigs: scm.userRemoteConfigs
                ])
            }
        }
        stage('Build Images') {
            steps {
                sh 'docker compose build'
            }
        }
        stage('Push Images') {
            when { branch 'main' }
            environment {
                DOCKER_PASS = credentials("DOCKER_HUB_PASS")
            }
            steps {
                sh '''
                  docker login -u ${DOCKER_ID} -p ${DOCKER_PASS}
                  docker compose push
                '''
            }
        }
        stage('Compose Up') {
            steps {
                sh 'docker compose up -d'
            }
        }
        stage('Test Services') {
            steps {
                sh '''
                  curl -f http://localhost:8080/api/v1/movies
                  curl -f http://localhost:8080/api/v1/casts
                '''
            }
        }
        stage('Deploy to Dev') {
            environment {
                KUBECONFIG = credentials("config")
            }
            steps {
                sh '''
                  mkdir -p $WORKSPACE/.kube
                  cp ${KUBECONFIG} $WORKSPACE/.kube/config
                  sed -e "s+tag:.*+tag: ${DOCKER_TAG}+g" charts/values.yaml > values-dev.yaml
                  helm upgrade --install fastapiapp charts --namespace dev -f values-dev.yaml
                '''
            }
        }
        stage('Deploy to Staging') {
            environment {
                KUBECONFIG = credentials("config")
            }
            steps {
                sh '''
                  mkdir -p $WORKSPACE/.kube
                  cp ${KUBECONFIG} $WORKSPACE/.kube/config
                  sed -e "s+tag:.*+tag: ${DOCKER_TAG}+g" charts/values.yaml > values-staging.yaml
                  helm upgrade --install fastapiapp charts --namespace staging -f values-staging.yaml
                '''
            }
        }
        stage('Deploy to Prod') {
            environment {
                KUBECONFIG = credentials("config")
            }
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    input message: 'Approve Prod Deployment?', ok: 'Yes'
                }
                sh '''
                  mkdir -p $WORKSPACE/.kube
                  cp ${KUBECONFIG} $WORKSPACE/.kube/config
                  sed -e "s+tag:.*+tag: ${DOCKER_TAG}+g" charts/values.yaml > values-prod.yaml
                  helm upgrade --install fastapiapp charts --namespace prod -f values-prod.yaml
                '''
            }
        }
    }
    post {
        failure {
            echo "This will run if the job failed"
            mail to: "jhon.castaneda.angulo@gmail.com",
                 subject: "${env.JOB_NAME} - Build # ${env.BUILD_ID} has failed",
                 body: "For more info on the pipeline failure, check out the console output at ${env.JOB_URL}"
        }
    }
}

