pipeline {
  agent any

  environment {
    DOCKER_ID            = "jhocan55"
    DOCKER_TAG           = "v.${BUILD_ID}.0"
    MOVIE_IMAGE          = "${DOCKER_ID}/movie_service:${DOCKER_TAG}"
    CAST_IMAGE           = "${DOCKER_ID}/cast_service:${DOCKER_TAG}"
    COMPOSE_PROJECT_NAME = "datascientest-ci-cd-exam"
  }

  stages {
    stage('Build & Start Services') {
      steps {
        script {
          sh '''
            set -eux

            echo ">>> Tear down old stack (if any)"
            docker compose -p ${COMPOSE_PROJECT_NAME} down --remove-orphans || true

            echo ">>> Build all services"
            docker compose -p ${COMPOSE_PROJECT_NAME} build

            echo ">>> Bring up"
            docker compose -p ${COMPOSE_PROJECT_NAME} up -d
            sleep 20
          '''
        }
      }
    }

    stage('Test Acceptance') {
      steps {
        script {
          sh '''
            echo ">>> Testing movie-service"
            curl -f http://localhost:8001/api/v1/movies

            echo ">>> Testing cast-service"
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
            set -eux

            echo "$DOCKER_PASS" | docker login -u "$DOCKER_ID" --password-stdin

            echo ">>> Retagging images"
            docker tag ${COMPOSE_PROJECT_NAME}_movie_service:latest ${MOVIE_IMAGE}
            docker tag ${COMPOSE_PROJECT_NAME}_cast_service:latest  ${CAST_IMAGE}

            echo ">>> Pushing to Docker Hub"
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
          helm upgrade --install fastapiapp charts \
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
          helm upgrade --install fastapiapp charts \
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
          helm upgrade --install fastapiapp charts \
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
           body:    "See ${env.BUILD_URL}"
    }
  }
}