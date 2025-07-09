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
          docker login -u $DOCKER_ID -p $DOCKER_PASS

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
                cp charts/values-dev.yaml values.yml
                sed -i "s/tag:.*/tag: ${DOCKER_TAG}/g" values.yml
                helm upgrade --install fastapiapp charts --values=values.yml --namespace dev
                
                echo "=== DEBUG: Node IPs ==="
                kubectl get nodes -o wide

                echo "=== DEBUG: Service Info ==="
                kubectl get svc -n dev -o wide 
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
                cp charts/values-qa.yaml values.yml
                sed -i "s/tag:.*/tag: ${DOCKER_TAG}/g" values.yml
                helm upgrade --install fastapiapp charts --values=values.yml --namespace qa
                
                echo "=== DEBUG: Node IPs ==="
                kubectl get nodes -o wide

                echo "=== DEBUG: Service Info ==="
                kubectl get svc -n qa -o wide 
                '''
            }
        }
    }

    // stage('Deploy to Staging') {
    //     environment {
    //         KUBECONFIG = credentials("config")
    //     }
    //     steps {
    //         script {
    //             sh '''
    //             rm -Rf .kube
    //             mkdir .kube
    //             cat $KUBECONFIG > .kube/config
    //             cp charts/values-staging.yaml values.yml
    //             sed -i "s/tag:.*/tag: ${DOCKER_TAG}/g" values.yml
    //             helm upgrade --install fastapiapp charts --values=values.yml --namespace staging
                
    //             echo "=== DEBUG: Node IPs ==="
    //             kubectl get nodes -o wide

    //             echo "=== DEBUG: Service Info ==="
    //             kubectl get svc -n staging -o wide 
    //             '''
    //         }
    //     }
    // }

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
                  cp charts/values-staging.yaml values.yml
                  sed -i "s/tag:.*/tag: ${DOCKER_TAG}/g" values.yml
                  helm upgrade --install fastapiapp charts --values=values.yml --namespace staging

                  echo "=== DEBUG: Node IPs ==="
                  kubectl get nodes -o wide

                  echo "=== DEBUG: Service Info ==="
                  kubectl get svc -n staging -o wide 

                  echo "=== DEBUG: Pod Info ==="
                  kubectl get pods -n staging -o wide

                  echo "=== DEBUG: Pod Env for movie ==="
                  kubectl get pods -n staging -l app=fastapiapp-movie -o json | jq '.items[].spec.containers[].env'

                  echo "=== DEBUG: Pod Env for cast ==="
                  kubectl get pods -n staging -l app=fastapiapp-cast -o json | jq '.items[].spec.containers[].env'

                  echo "=== DEBUG: Pod Logs (movie) ==="
                  kubectl logs -n staging -l app=fastapiapp-movie --tail=40 || true

                  echo "=== DEBUG: Pod Logs (cast) ==="
                  kubectl logs -n staging -l app=fastapiapp-cast --tail=40 || true

                  echo "=== DEBUG: Pod Describe (movie) ==="
                  kubectl describe pods -n staging -l app=fastapiapp-movie || true

                  echo "=== DEBUG: Pod Describe (cast) ==="
                  kubectl describe pods -n staging -l app=fastapiapp-cast || true
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
              cp charts/values-prod.yaml values.yml
              sed -i "s/tag:.*/tag: ${DOCKER_TAG}/g" values.yml
              helm upgrade --install fastapiapp charts --values=values.yml --namespace prod

              echo "=== DEBUG: Node IPs ==="
              kubectl get nodes -o wide

              echo "=== DEBUG: Service Info ==="
              kubectl get svc -n prod -o wide              
              '''
          }
        }
    }
  }
  post {
    failure {
      catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
        mail to: "jhon.castaneda.angulo@gmail.com",
             subject: "${env.JOB_NAME} #${env.BUILD_ID} Failed",
             body: "See ${env.BUILD_URL}"      
      }
    } 
       
    // always {
    //   sh 'docker compose down --remove-orphans --volumes'
    //   sh 'docker system prune -a --volumes -f'
    //   sh 'docker volume prune -f'
    //   sh 'docker network prune -f'
    //   sh 'docker container prune -f'
    //   sh 'docker ps -a'
    //   sh 'docker rmi -f $(docker images -q) 2>/dev/null || true'
    //   echo "Cleaning workspace and removing Docker images"
    // }
  }
}
