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
            set -eux

            echo "===== CLEANUP ====="
            docker compose down --remove-orphans || true

            echo "===== BUILD via docker-compose ====="
            docker compose build

            echo "===== UP via docker-compose ====="
            docker compose up -d
            sleep 20
          '''
        }
      }
    }

    stage('Test') {
      steps {
        script {
          sh '''
            # Acceptance tests
            curl -f http://localhost:8001/api/v1/movies
            curl -f http://localhost:8002/api/v1/casts
          '''
        }
      }
    }

    stage('Tag & Push Images') {
      environment {
        DOCKER_PASS = credentials("DOCKER_HUB_PASS")
      }
      steps {
        script {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_ID" --password-stdin

            echo "===== TAGGING ====="
            docker tag datascientest-ci-cd-exam_movie_service:latest ${MOVIE_IMAGE}
            docker tag datascientest-ci-cd-exam_cast_service:latest  ${CAST_IMAGE}

            echo "===== PUSHING ====="
            docker push ${MOVIE_IMAGE}
            docker push ${CAST_IMAGE}
          '''
        }
      }
    }

    stage('Deploy to Dev') {
      environment { KUBECONFIG = credentials("config") }
      steps {
        writeFile file: '.kube/config', text: "${KUBECONFIG}"
        sh '''
          helm upgrade --install app charts \
            --namespace dev \
            --kubeconfig .kube/config \
            --set movie.image.tag=${DOCKER_TAG} \
            --set cast.image.tag=${DOCKER_TAG}
        '''
      }
    }

    stage('Deploy to Staging') {
      environment { KUBECONFIG = credentials("config") }
      steps {
        writeFile file: '.kube/config', text: "${KUBECONFIG}"
        sh '''
          helm upgrade --install app charts \
            --namespace staging \
            --kubeconfig .kube/config \
            --set movie.image.tag=${DOCKER_TAG} \
            --set cast.image.tag=${DOCKER_TAG}
        '''
      }
    }

    stage('Deploy to Prod') {
      environment { KUBECONFIG = credentials("config") }
      steps {
        timeout(time: 15, unit: 'MINUTES') {
          input message: 'Approve production deploy?', ok: 'Yes'
        }
        writeFile file: '.kube/config', text: "${KUBECONFIG}"
        sh '''
          helm upgrade --install app charts \
            --namespace prod \
            --kubeconfig .kube/config \
            --set movie.image.tag=${DOCKER_TAG} \
            --set cast.image.tag=${DOCKER_TAG}
        '''
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