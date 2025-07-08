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
        sh '''
          docker version
          docker info
          docker compose version
          curl --version
          jq --version
        '''
      }
    }

    stage('Prune Docker data') {
      steps {
        sh 'docker system prune -a --volumes -f'
      }
    }
    stage('Start Containers') {
      steps {
        sh '''
          docker compose up -d --no-color --wait
          docker compose ps
        '''
      }
    }

    stage('Test Acceptance') {
      steps {
        sh '''
          curl -f http://localhost:8081/api/v1/movies
          curl -f http://localhost:8081/api/v1/casts
        '''
      }
    }

    stage('Docker Push') {
      environment {
        DOCKER_PASS = credentials("DOCKER_HUB_PASS")
      }
      steps {
        sh """
          echo "\$DOCKER_PASS" | docker login -u "$DOCKER_ID" --password-stdin

          echo ">>> Pushing images built by Compose"
          docker tag datascientest-ci-cd-exam-movie_service $MOVIE_IMAGE
          docker tag datascientest-ci-cd-exam-cast_service $CAST_IMAGE

          docker push $MOVIE_IMAGE
          docker push $CAST_IMAGE
        """
      }
    }

    stage('Deploy to Dev') {
        environment {
            KUBECONFIG = credentials("config")
        }
        steps {
            script {
                sh '''
                rm -Rf .kube
                mkdir .kube
                cat $KUBECONFIG > .kube/config
                cp charts/values.yaml values.yml
                sed -i "s/tag:.*/tag: ${DOCKER_TAG}/g" values.yml
                helm upgrade --install fastapiapp charts --values=values.yml --namespace dev

                echo "=== DEBUG: Service Info ==="
                kubectl get svc -n dev -o wide

                echo "=== DEBUG: Endpoints ==="
                kubectl get endpoints -n dev

                echo "=== DEBUG: Pods ==="
                kubectl get pods -n dev -o wide

                echo "=== DEBUG: Try port-forward and curl ==="
                kubectl port-forward svc/fastapiapp-movie 18087:80 -n dev &
                sleep 5
                curl -v http://localhost:18087/api/v1/movies/ || echo "curl failed"
                pkill -f "kubectl port-forward svc/fastapiapp-movie"
                '''
            }
        }
    }
    stage('Deploy to QA') {
        environment {
            KUBECONFIG = credentials("config")
        }
        steps {
            script {
                sh '''
                rm -Rf .kube
                mkdir .kube
                cat $KUBECONFIG > .kube/config
                cp charts/values.yaml values.yml
                sed -i "s/tag:.*/tag: ${DOCKER_TAG}/g" values.yml
                helm upgrade --install fastapiapp charts --values=values.yml --namespace qa
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
                sh '''
                rm -Rf .kube
                mkdir .kube
                cat $KUBECONFIG > .kube/config
                cp charts/values.yaml values.yml
                sed -i "s/tag:.*/tag: ${DOCKER_TAG}/g" values.yml
                helm upgrade --install fastapiapp charts --values=values.yml --namespace staging
                '''
            }
        }
    }

    stage('Deploy to Prod') {
        environment {
            KUBECONFIG = credentials("config")
        }
        steps {
            timeout(time: 15, unit: "MINUTES") {
                input message: 'Do you want to deploy in production ?', ok: 'Yes'
            }
            script {
                sh '''
                rm -Rf .kube
                mkdir .kube
                cat $KUBECONFIG > .kube/config
                cp charts/values.yaml values.yml
                sed -i "s/tag:.*/tag: ${DOCKER_TAG}/g" values.yml
                helm upgrade --install fastapiapp charts --values=values.yml --namespace prod
                '''
            }
        }
    }
  }
  post {
    failure {
      mail to: "jhon.castaneda.angulo@gmail.com",
           subject: "${env.JOB_NAME} #${env.BUILD_ID} Failed",
           body: "See ${env.BUILD_URL}"
    }
  }
}
