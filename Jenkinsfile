
pipeline {
    agent {label 'sentry-linux'}

    stages {
        stage("Checkout") {
            steps {
                sh 'printenv'
                deleteDir()
                sh 'docker rm -vf pigen_work_sentry || true' 
                //
                // Using rfbuilder credentials for git, but the build logs into the jshw-02 build machine using jenkins user.
                // The keys for rfbuider are in ~/.ssh for the jenkins user
                //
                git branch: "$BRANCH_NAME", credentialsId: '2fe6ce4e-eddc-41c6-af0b-186bbdc71728', url: "git@github.com:rfcode/pi-gen.git"
                sh 'git submodule update --init --recursive'
            }
        }
        stage("Build") {
            steps {
                sh './build-docker.sh'
            }
        }
    }
}

