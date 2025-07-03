pipeline {
    environment { // Declaration of environment variables
        DOCKER_ID    = "jhocan55"
        DOCKER_IMAGE = "jenkinsappexam"
        DOCKER_TAG   = "v.${BUILD_ID}.0"
    }
    agent any // Jenkins will be able to select all available agents
    stages {
        stage(' Docker Build'){ // docker build image stage
            steps {
                script {
                sh '''
                 docker rm -f jenkins || true
                 docker compose build
                 sleep 6
                '''
                }
            }
        }
        stage('Docker run'){ // run containers via compose
            steps {
                script {
                    sh '''
                     docker rm -f jenkins || true
                    '''
                    writeFile file: 'jenkins.override.yml', text: '''
services:
  movie_service:
    volumes: []
  cast_service:
    volumes: []
'''
                    sh '''
                      docker compose -f docker-compose.yml -f jenkins.override.yml up -d
                      sleep 10
                    '''
                }
            }
        }
        stage('Test Acceptance'){ // validate the endpoints
            steps {
                script {
                sh '''
                 curl -f http://localhost:8080/api/v1/movies
                 curl -f http://localhost:8080/api/v1/casts
                '''
                }
            }
        }
        stage('Docker Push'){ // push images to Docker Hub
            environment {
                DOCKER_PASS = credentials("DOCKER_HUB_PASS")
            }
            steps {
                script {
                sh '''
                 docker login -u $DOCKER_ID -p $DOCKER_PASS
                 docker compose push
                '''
                }
            }
        }
        stage('Deploiement en dev'){
            environment {
                KUBECONFIG = credentials("config")
            }
            steps {
                script {
                sh '''
                 rm -rf .kube && mkdir .kube
                 cp ${KUBECONFIG} .kube/config
                 sed -e "s+tag:.*+tag: ${DOCKER_TAG}+g" charts/values.yaml > values.yaml
                 helm upgrade --install app charts --namespace dev -f values.yaml
                '''
                }
            }
        }
        stage('Deploiement en staging'){
            environment {
                KUBECONFIG = credentials("config")
            }
            steps {
                script {
                sh '''
                 rm -rf .kube && mkdir .kube
                 cp ${KUBECONFIG} .kube/config
                 sed -e "s+tag:.*+tag: ${DOCKER_TAG}+g" charts/values.yaml > values.yaml
                 helm upgrade --install app charts --namespace staging -f values.yaml
                '''
                }
            }
        }
        stage('Deploiement en prod'){
            environment {
                KUBECONFIG = credentials("config")
            }
            steps {
                timeout(time: 15, unit: "MINUTES") {
                    input message: 'Do you want to deploy in production ?', ok: 'Yes'
                }
                script {
                sh '''
                 rm -rf .kube && mkdir .kube
                 cp ${KUBECONFIG} .kube/config
                 sed -e "s+tag:.*+tag: ${DOCKER_TAG}+g" charts/values.yaml > values.yaml
                 helm upgrade --install app charts --namespace prod -f values.yaml
                '''
                }
            }
        }
    }
    post { // send email when the job has failed
        failure {
            echo "This will run if the job failed"
            mail to: "jhon.castaneda.angulo@gmail.com",
                 subject: "${env.JOB_NAME} - Build # ${env.BUILD_ID} has failed",
                 body: "For more info on the pipeline failure, check out the console output at ${env.BUILD_URL}"
        }
    }
}

