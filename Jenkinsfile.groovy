import java.util.Base64
def onDistrib(app, distr) {
    stage('printenv') {
        script {
            sh "printenv"
        }
    }

    stage('Build go') {
        withDockerRegistry(credentialsId: 'sa-synd', url: "https://reg-ci.works.prod.sbt") {
            sh "make build"
        }
    }

    stage ('Scanning Sonar') {
        script {
            withSonarQubeEnv(installationName:'SonarQube') {
                withCredentials(bindings: [string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_TOKEN')]) {
                    def sonarScanner = tool 'sonar-scanner'
                    sh (label: "sonar-scanner", script: """
                      ${sonarScanner}/sonar-scanner \
                       -Dproject.settings=sonar-project.properties \
                       -Dsonar.login=$SONAR_TOKEN \
                       -Dsonar.branch.name=${env.CONFIG_BRANCH} \
                    """ )
                }
            }
        }
    }
}
return wrapJenkinsfile(this)