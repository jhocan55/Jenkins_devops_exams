pipeline {
  agent any
  environment {
    DOCKER_ID    = "jhocan55"
    DOCKER_TAG   = "v.${BUILD_ID}.0"
    MOVIE_IMAGE  = "${DOCKER_ID}/movie_service:${DOCKER_TAG}"
    CAST_IMAGE   = "${DOCKER_ID}/cast_service:${DOCKER_TAG}"
  }

  stages {
    stage('Build Docker Images') {
      steps {
        script {
          sh '''
            echo "===== BUILD movie-service ====="
            docker build -t ${MOVIE_IMAGE} ./movie-service

            echo "===== BUILD cast-service ====="
            docker build -t ${CAST_IMAGE} ./cast-service
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
            echo "===== PUSHING IMAGES TO DOCKER HUB ====="
            docker login -u $DOCKER_ID -p $DOCKER_PASS
            docker push ${MOVIE_IMAGE}
            docker push ${CAST_IMAGE}
          '''
        }
      }
    }

    stage('Start Services') {
      steps {
        script {
          sh """
            echo "===== STARTING SERVICES WITH DOCKER COMPOSE (No volumes, no build) ====="
            docker compose down --remove-orphans
            docker pull ${CAST_IMAGE}
            docker pull ${MOVIE_IMAGE}
            docker compose up -d --no-build

            sleep 10
          """
        }
      }
    }

    stage('Test') {
      steps {
        script {
          sh '''
            echo "===== RUNNING ACCEPTANCE TESTS ====="
            curl -f http://localhost:8001/api/v1/movies
            curl -f http://localhost:8002/api/v1/casts
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
      mail to: "jhon.castaneda.angulo@gmail.com",
           subject: "${env.JOB_NAME} #${env.BUILD_ID} Failed",
           body: "See the console output at ${env.BUILD_URL}"
    }
  }
}
