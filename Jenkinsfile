pipeline {
  agent any
  environment {
    DOCKER_ID    = "jhocan55"
    DOCKER_TAG   = "v.${BUILD_ID}.0"
    MOVIE_IMAGE  = "${DOCKER_ID}/movie_service:${DOCKER_TAG}"
    CAST_IMAGE   = "${DOCKER_ID}/cast_service:${DOCKER_TAG}"    
    // When you deploy with Helm, your chart’s values.yaml should
    // have image.tag: "" so we can inject via --set image.tag=${DOCKER_TAG}
  }

  stages {
    stage('Build & Tag Images') {
      steps {
        sh '''
            # Tear down any old containers
            docker compose down --remove-orphans

            # Build all services per docker-compose.yml
            docker compose build

            # Directly grab the image IDs by service name
            MOVIE_ID=$(docker compose images -q movie_service)
            CAST_ID=$(docker compose images -q cast_service)

            if [ -z "$MOVIE_ID" ] || [ -z "$CAST_ID" ]; then
              echo "Could not find compose-built images"; exit 1
            fi

            # Tag them into your Docker Hub repo
            docker tag $MOVIE_ID ${MOVIE_IMAGE}
            docker tag $CAST_ID  ${CAST_IMAGE}
        '''
      }
    }

    stage('Start Stack & Test') {
      steps {
        script {
          sh '''
            # Spin up (now using your freshly tagged images)
            docker compose up -d --no-build
            sleep 10

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