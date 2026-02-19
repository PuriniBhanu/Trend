pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "bhanusiva/trend-app:latest"
        DOCKER_CREDENTIALS_ID = "dockerhub-creds"
    }

    stages {

        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Clone Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/PuriniBhanu/Trend.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $DOCKER_IMAGE .'
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: DOCKER_CREDENTIALS_ID,
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    docker push $DOCKER_IMAGE
                    '''
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh 'kubectl apply -f k8s/deployment.yaml'
                sh 'kubectl apply -f k8s/service.yaml'
            }
        }
    }
}
