pipeline {
    agent any
    options {
        // skip the automatic, job‐configured checkout
        skipDefaultCheckout()
    }
    stages {
        stage("Checkout") {
            steps {
                // explicitly fetch the main branch from the same repo
                checkout([
                    $class: 'GitSCM',
                    branches: [[ name: '*/main' ]],
                    userRemoteConfigs: scm.userRemoteConfigs
                ])
            }
        }
        stage("Test Connection") {
            steps {
                echo "Connection to Jenkins successful!"
            }
        }
    }
}
