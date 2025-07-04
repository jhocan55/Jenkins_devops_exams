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

            echo "===== BEFORE DOWN: docker ps -a ====="
            docker ps -a

            echo "===== INSPECT ALL CONTAINERS ====="
            for ID in $(docker ps -aq); do
              echo "---- $ID ----"
              docker inspect --format \
                'Name={{.Name}} State={{.State.Status}} User={{.Config.User}}' $ID
            done

            echo "===== TRYING docker compose down (timeout=60) ====="
            docker compose down --timeout 60 --remove-orphans || {
              echo "⚠️ compose down failed, attempting manual docker stop…"
              for ID in $(docker ps -aq); do
                echo "stopping $ID"
                docker stop --time=30 $ID || echo "❌ could not stop $ID"
              done
              echo "retrying compose down"
              docker compose down --timeout 60 --remove-orphans
            }

            echo "===== AFTER DOWN: docker ps -a ====="
            docker ps -a

            echo "===== BUILD movie-service ====="
            docker build \
              --build-arg DOCKER_ID=${DOCKER_ID} \
              --build-arg DOCKER_TAG=${DOCKER_TAG} \
              -t ${MOVIE_IMAGE} ./movie-service

            echo "===== BUILD cast-service ====="
            docker build \
              --build-arg DOCKER_ID=${DOCKER_ID} \
              --build-arg DOCKER_TAG=${DOCKER_TAG} \
              -t ${CAST_IMAGE} ./cast-service

            echo "===== docker compose up ====="
            docker compose up -d --no-build
            sleep 10

            echo "===== FINISHED BUILD & START ====="
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