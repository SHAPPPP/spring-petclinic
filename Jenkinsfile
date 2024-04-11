pipeline {
    agent any

    tools {
        maven "m3"
        jdk "jdk17"
    }
        environment{
        REGION = 'ap-northeast-2'
        EKS_API = 'https://FD9DEE3966F529DE38A0FA90811AFDCC.gr7.ap-northeast-2.eks.amazonaws.com'
        EKS_CLUSTER_NAME = "project05-02-eks-work-cluster"
        EKS_JENKINS_CREDENTIAL_ID = 'kubectl-deploy-credential'
        ECR_PATH = '257307634175.dkr.ecr.ap-northeast-2.amazonaws.com'
        ECR_IMAGE = 'project05-ecr'
        AWS_CREDENTIAL_ID = 'awscredentials'
        ECR_DOCKER_IMAGE = "${ECR_PATH}/${ECR_IMAGE}"   
    }
    
    stages {
         stage('Git Clone') {
             steps {
                 echo 'Git Clone'
                 git url: 'https://github.com/SHAPPPP/spring-petclinic.git',
                 branch: 'wavefront', credentialsId: 'githubid'
             }
             post {
                 success {
                     echo 'success clone project'
                 }
                 failure {
                     error 'fail clone project' // exit pipeline
                 }
             }
         }
        
         stage ('mvn Build') {
             steps {
                sh 'mvn -Dmaven.test.failure.ignore=true install' 
            }
            post {
                success {
                    junit '**/target/surefire-reports/TEST-*.xml' 
                }
            }
         }

         stage ('Docker Build') {
            steps {
                dir("${env.WORKSPACE}") {
                    sh """
                      docker build -t $ECR_DOCKER_IMAGE:$BUILD_NUMBER .
                      docker tag $ECR_DOCKER_IMAGE:$BUILD_NUMBER $ECR_DOCKER_IMAGE:latest
                    """
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                echo "Push Docker Image to ECR"
                script{
                    // cleanup current user docker credentials
                    sh 'rm -f ~/.dockercfg ~/.docker/config.json || true' 
                    docker.withRegistry("https://${ECR_PATH}" , "ecr:${REGION}:${AWS_CREDENTIAL_ID}" ) {
                        docker.image("${ECR_DOCKER_IMAGE}:${BUILD_NUMBER}").push()
                        docker.image("${ECR_DOCKER_IMAGE}:latest").push()
                    }
                    
                }
            }
            post {
                success {
                    echo "Push Docker Image success!"
                }
            }
        }

        stage('Clean Up Docker Images on Jenkins Server') {
            steps {
                echo 'Cleaning up unused Docker images on Jenkins server'

                // Clean up unused Docker images, including those created within the last hour
                sh "docker image prune -f --all --filter \"until=1h\""
            }
        }

        stage('Deploy to k8s') {
            steps {
                withKubeConfig([credentialsId: "kubectl-deploy-credential",
                                serverUrl: "${EKS_API}",
                                clusterName: "${EKS_CLUSTER_NAME}"]){
                    sh "sed 's/IMAGE_VERSION/v${env.BUILD_ID}/g' service.yaml > output.yaml"
                    sh "aws eks --region ${REGION} update-kubeconfig --name ${EKS_CLUSTER_NAME}"
                    sh "kubectl apply -f output.yaml"
                    sh "rm output.yaml"
                    }
                }    
        }
  }       
}
