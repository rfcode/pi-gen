
pipeline {
    agent {label 'sentry-linux'}

	stages {
		stage("Checkout") {
			steps {
                deleteDir()
                sh 'printenv'
				git branch: "$BRANCH_NAME", credentialsId: '2fe6ce4e-eddc-41c6-af0b-186bbdc71728', url: "git@github.com:rfcode/pi-gen.git"
                sh 'git submodule update --init --recursive'
			}
		}
	}
}

