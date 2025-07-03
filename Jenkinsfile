pipeline {
    agent any
    environment {
        DOCKER_ID       = "jhocan55"
        DOCKER_TAG      = "v.${BUILD_ID}.0"
        MOVIE_IMAGE     = "${DOCKER_ID}/movie_service"
        CAST_IMAGE      = "${DOCKER_ID}/cast_service"
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
                sh 'docker-compose build'
            }
        }
        stage('Push Images') {
            when { branch 'main' }
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh '''
                      docker login -u $USER -p $PASS
                      docker-compose push
                    '''
                }
            }
        }
        stage('Compose Up') {
            steps {
                sh 'docker-compose up -d'
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
            environment { KUBECONFIG = credentials('kubeconfig-dev') }
            steps {
                sh '''
                  cp charts/values.yaml values-dev.yaml
                  sed -i "s+tag:.*+tag: ${DOCKER_TAG}+g" values-dev.yaml
                  helm upgrade --install fastapiapp charts --namespace dev -f values-dev.yaml
                '''
            }
        }
        stage('Deploy to Staging') {
            environment { KUBECONFIG = credentials('kubeconfig-staging') }
            steps {
                sh '''
                  cp charts/values.yaml values-staging.yaml
                  sed -i "s+tag:.*+tag: ${DOCKER_TAG}+g" values-staging.yaml
                  helm upgrade --install fastapiapp charts --namespace staging -f values-staging.yaml
                '''
            }
        }
        stage('Deploy to Prod') {
            environment { KUBECONFIG = credentials('kubeconfig-prod') }
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    input message: 'Approve Prod Deployment?', ok: 'Yes'
                }
                sh '''
                  cp charts/values.yaml values-prod.yaml
                  sed -i "s+tag:.*+tag: ${DOCKER_TAG}+g" values-prod.yaml
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

