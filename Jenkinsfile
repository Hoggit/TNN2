pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                sh 'squish --uglify'
                sh "ldoc ${env.WORKSPACE}"
            }
        }
        stage('Deploy') {
            when {
                anyOf { tag 'release-*'; branch 'master' }
            }

            steps {
                script {
                    if (env.TAG_NAME && env.TAG_NAME =~ /release-/) {
                        TAG = env.TAG_NAME
                    } else {
                        TAG = env.BRANCH_NAME
                    }
                }
                sh "python3 /opt/tnn_releaser/releaser.py ${env.WORKSPACE} ${TAG}"
            }
        }
    }
}