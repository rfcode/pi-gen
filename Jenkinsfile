
pipeline {
    agent {label 'sentry-linux'}

	stages {
		stage("Checkout") {
			git credentialsId '2fe6ce4e-eddc-41c6-af0b-186bbdc71728', url: "git@github.com:rfcode/pi-gen.git"
		}
	}
}

