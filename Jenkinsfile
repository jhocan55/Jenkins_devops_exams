pipeline {
    agent any

    stages {
        stage("Checkout") {
            steps {
                // explicitly fetch the main branch
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[url: 'YOUR_REPO_URL.git']]
                ])
            }
        }

        stage("Datascientest Variables") {
            steps {
                sh "printenv"
            }
        }
    }
}
