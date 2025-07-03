pipeline {
    environment {
        DOCKER_ID    = "jhocan55"
        DOCKER_IMAGE = "jenkinsappexam"
        DOCKER_TAG   = "v.${BUILD_ID}.0"
    }
    agent any

    stages {
        stage('Docker Build') {
            steps {
                script {
                    sh '''
                    docker rm -f jenkins || true
                    docker build -t $DOCKER_ID/$DOCKER_IMAGE:$DOCKER_TAG .
                    '''
                }
            }
        }

        stage('Docker Run') {
            steps {
                script {
                    sh '''
                    docker rm -f jenkins || true
                    docker run -d -p 8080:8080 --name jenkins $DOCKER_ID/$DOCKER_IMAGE:$DOCKER_TAG
                    sleep 10
                    '''
                }
            }
        }

        stage('Test Acceptance') {
            steps {
                script {
                    sh '''
                    curl -f http://localhost:8080/api/v1/movies
                    curl -f http://localhost:8080/api/v1/casts
                    '''
                }
            }
        }

        stage('Docker Push') {
            environment {
                DOCKER_PASS = credentials("DOCKER_HUB_PASS")
            }
            steps {
                script {
                    sh '''
                    docker login -u $DOCKER_ID -p $DOCKER_PASS
                    docker push $DOCKER_ID/$DOCKER_IMAGE:$DOCKER_TAG
                    '''
                }
            }
        }

        stage('Déploiement en dev') {
            environment {
                KUBECONFIG = credentials("config")
            }
            steps {
                script {
                    writeFile file: '.kube/config', text: "${KUBECONFIG}"
                    sh '''
                    sed -e "s+tag:.*+tag: \\\"${DOCKER_TAG}\\\"+g" charts/values.yaml > values.yaml
                    helm upgrade --install app charts --namespace dev -f values.yaml
                    '''
                }
            }
        }

        stage('Déploiement en staging') {
            environment {
                KUBECONFIG = credentials("config")
            }
            steps {
                script {
                    writeFile file: '.kube/config', text: "${KUBECONFIG}"
                    sh '''
                    sed -e "s+tag:.*+tag: \\\"${DOCKER_TAG}\\\"+g" charts/values.yaml > values.yaml
                    helm upgrade --install app charts --namespace staging -f values.yaml
                    '''
                }
            }
        }

        stage('Déploiement en prod') {
            environment {
                KUBECONFIG = credentials("config")
            }
            steps {
                timeout(time: 15, unit: "MINUTES") {
                    input message: 'Do you want to deploy in production ?', ok: 'Yes'
                }
                script {
                    writeFile file: '.kube/config', text: "${KUBECONFIG}"
                    sh '''
                    sed -e "s+tag:.*+tag: \\\"${DOCKER_TAG}\\\"+g" charts/values.yaml > values.yaml
                    helm upgrade --install app charts --namespace prod -f values.yaml
                    '''
                }
            }
        }
    }

    post {
        failure {
            echo "This will run if the job failed"
            mail to: "jhon.castaneda.angulo@gmail.com",
                 subject: "${env.JOB_NAME} - Build # ${env.BUILD_ID} has failed",
                 body: "For more info on the pipeline failure, check out the console output at ${env.BUILD_URL}"
        }
    }
}
