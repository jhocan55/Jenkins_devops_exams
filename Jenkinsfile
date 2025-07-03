pipeline {
    environment {
        DOCKER_ID    = "jhocan55"
        DOCKER_TAG   = "v.${BUILD_ID}.0"
        MOVIE_IMAGE  = "${DOCKER_ID}/movie_service:${DOCKER_TAG}"
        CAST_IMAGE   = "${DOCKER_ID}/cast_service:${DOCKER_TAG}"
    }
    agent any

    stages {
        stage('Docker Compose Build') {
            steps {
                script {
                    sh '''
                    docker compose build
                    '''
                }
            }
        }

        stage('Tag Built Images') {
            steps {
                script {
                    def movieImageId = sh(script: "docker images -q datascientest-ci-cd-exam-movie_service", returnStdout: true).trim()
                    def castImageId  = sh(script: "docker images -q datascientest-ci-cd-exam-cast_service", returnStdout: true).trim()

                    if (!movieImageId || !castImageId) {
                        error "Could not find built images for movie_service or cast_service"
                    }

                    sh """
                    docker tag ${movieImageId} ${MOVIE_IMAGE}
                    docker tag ${castImageId} ${CAST_IMAGE}
                    """
                }
            }
        }

        stage('Docker Run') {
            steps {
                script {
                    sh '''
                    docker compose up -d
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
                    docker push $MOVIE_IMAGE
                    docker push $CAST_IMAGE
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

