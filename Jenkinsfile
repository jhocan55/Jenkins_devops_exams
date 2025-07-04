pipeline {
  agent any
  environment {
    DOCKER_ID    = "jhocan55"
    DOCKER_TAG   = "v.${BUILD_ID}.0"
    MOVIE_IMAGE  = "${DOCKER_ID}/movie_service:${DOCKER_TAG}"
    CAST_IMAGE   = "${DOCKER_ID}/cast_service:${DOCKER_TAG}"
  }

  stages {
    stage('Build & Start Services') {
      steps {
        script {
          sh '''
            # 1) Tear down old containers
            docker compose down --remove-orphans

            # 2) Build movie-service with your tag
            docker build \
              --build-arg DOCKER_ID=${DOCKER_ID} \
              --build-arg DOCKER_TAG=${DOCKER_TAG} \
              -t ${MOVIE_IMAGE} ./movie-service

            # 3) Build cast-service with your tag
            docker build \
              --build-arg DOCKER_ID=${DOCKER_ID} \
              --build-arg DOCKER_TAG=${DOCKER_TAG} \
              -t ${CAST_IMAGE} ./cast-service

            # 4) Start stack using the pre-built images
            docker compose up -d --no-build
            sleep 10                        
          '''
        }
      }
    }

    stage('Test') {
      steps {
        script {
          sh '''
            # Acceptance tests
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
            docker push ${MOVIE_IMAGE}
            docker push ${CAST_IMAGE}
          '''
        }
      }
    }

    stage('Deploy to Dev') {
      environment {
        KUBECONFIG = credentials("config")
      }
      steps {
        script {
          writeFile file: '.kube/config', text: "${KUBECONFIG}"
          sh '''
            helm upgrade --install app charts \
              --namespace dev \
              --kubeconfig .kube/config \
              --set image.tag=${DOCKER_TAG}
          '''
        }
      }
    }

    stage('Deploy to Staging') {
      environment {
        KUBECONFIG = credentials("config")
      }
      steps {
        script {
          writeFile file: '.kube/config', text: "${KUBECONFIG}"
          sh '''
            helm upgrade --install app charts \
              --namespace staging \
              --kubeconfig .kube/config \
              --set image.tag=${DOCKER_TAG}
          '''
        }
      }
    }

    stage('Deploy to Prod') {
      environment {
        KUBECONFIG = credentials("config")
      }
      steps {
        timeout(time: 15, unit: 'MINUTES') {
          input message: 'Approve production deploy?', ok: 'Yes'
        }
        script {
          writeFile file: '.kube/config', text: "${KUBECONFIG}"
          sh '''
            helm upgrade --install app charts \
              --namespace prod \
              --kubeconfig .kube/config \
              --set image.tag=${DOCKER_TAG}
          '''
        }
      }
    }
  }

  post {
    failure {
      mail to:    "jhon.castaneda.angulo@gmail.com",
           subject: "${env.JOB_NAME} #${env.BUILD_ID} Failed",
           body:    "See the console output at ${env.BUILD_URL}"
    }
  }
}