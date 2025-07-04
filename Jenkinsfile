pipeline {
  agent any

  environment {
    DOCKER_ID            = "jhocan55"
    DOCKER_TAG           = "v.${BUILD_ID}.0"
    MOVIE_IMAGE          = "${DOCKER_ID}/movie_service:${DOCKER_TAG}"
    CAST_IMAGE           = "${DOCKER_ID}/cast_service:${DOCKER_TAG}"
  }

  stages {
    stage('Build & Start Services') {
      steps {
        script {
          sh '''
            set -eux

            # write .env so compose picks up DOCKER_ID/DOCKER_TAG
            cat > .env <<EOF
DOCKER_ID=${DOCKER_ID}
DOCKER_TAG=${DOCKER_TAG}
EOF

            echo ">>> Tear down old stack"
            docker compose down --remove-orphans || true

            echo ">>> Build & bring up all services in one step"
            docker compose up -d --build
            sleep 20
          '''
        }
      }
    }

    stage('Test Acceptance') {
      steps {
        sh '''
          curl -f http://localhost:8001/api/v1/movies
          curl -f http://localhost:8002/api/v1/casts
        '''
      }
    }

    stage('Docker Push') {
      environment {
        DOCKER_PASS = credentials("DOCKER_HUB_PASS")
      }
      steps {
        sh '''
          echo "$DOCKER_PASS" | docker login -u "$DOCKER_ID" --password-stdin

          echo ">>> Pushing images built by Compose"
          docker push ${MOVIE_IMAGE}
          docker push ${CAST_IMAGE}
        '''
      }
    }

    stage('Deploy to Dev') {
      steps {
        withCredentials([file(credentialsId: 'config', variable: 'KUBE_CFG')]) {
          sh """
            helm upgrade --install fastapiapp charts \
              --namespace dev \
              --kubeconfig "$KUBE_CFG" \
              -f charts/values-dev.yaml \
              --set movie.image.tag=${DOCKER_TAG} \
              --set cast.image.tag=${DOCKER_TAG}
            """
        }
      }
    }

    stage('Deploy to QA') {
      steps {
        withCredentials([file(credentialsId: 'config', variable: 'KUBE_CFG')]) {
          sh """
            helm upgrade --install fastapiapp charts \
              --namespace qa \
              --kubeconfig "$KUBE_CFG" \
              -f charts/values-qa.yaml \
              --set movie.image.tag=${DOCKER_TAG} \
              --set cast.image.tag=${DOCKER_TAG}
            """
        }
      }
    }

    stage('Deploy to Staging') {
      steps {
        withCredentials([file(credentialsId: 'config', variable: 'KUBE_CFG')]) {
          sh """
            helm upgrade --install fastapiapp charts \
              --namespace staging \
              --kubeconfig "$KUBE_CFG" \
              -f charts/values-staging.yaml \
              --set movie.image.tag=${DOCKER_TAG} \
              --set cast.image.tag=${DOCKER_TAG}
            """
        }
      }
    }

    stage('Deploy to Prod') {
      steps {
        timeout(time: 15, unit: 'MINUTES') {
          input message: 'Approve prod deploy?', ok: 'Yes'
        }
        withCredentials([file(credentialsId: 'config', variable: 'KUBE_CFG')]) {
          sh """
            helm upgrade --install fastapiapp charts \
              --namespace prod \
              --kubeconfig "$KUBE_CFG" \
              -f charts/values-prod.yaml \
              --set movie.image.tag=${DOCKER_TAG} \
              --set cast.image.tag=${DOCKER_TAG}
            """
        }
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