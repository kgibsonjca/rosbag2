def Customer = "JCA"
def Project = "ROS"
def binaries = 'deploy/*.deb'
def title = "${JOB_NAME}_${env.BRANCH_NAME}"
def aptly_target = "aptly@jcaros.repo.jca"
def aptly_dist = "foxy"
def ros_build_registry = "jcaros.registry.jca"
def ros_build_image = "jcaros2:0.1.3"
def pylint_threshold = "8"

// Git Branches
def develop_branch = "develop"
def release_branch = "rc"
def master_branch = "master"
def hotfix_branch = "hotfix"

pipeline {
        agent {
                node { label 'Linux-new' }
        }

        options {
                timeout(time: 1, unit: 'HOURS')
        }

        stages {
                stage('Prepare Workspace') {
                        steps {
                                notifyBitbucket buildStatus: 'INPROGRESS', buildName: env.BUILD_TAG, commitSha1: '', considerUnstableAsSuccess: false, credentialsId: '', disableInprogressNotification: false, ignoreUnverifiedSSLPeer: false, includeBuildNumberInKey: false, prependParentProjectKey: false, projectKey: '', stashServerBaseUrl: ''
                                script {
                                        echo "My branch is: ${env.BRANCH_NAME}"
                                }

                                //Always have set showing, for build diagnostics
                                sh("set")
                                sh("ls")
                        }
                }

//                stage('Run Tests') {
//                        steps {
//                                echo "Running Tests\n===============================\n"
//                                sh("ros-build-tools/test-in-docker.sh amd64 ${ros_build_version}")
//                                sh("sudo chown -R ${USER}:${USER} ./")
//                                sh("pylint --rcfile=./ros-build-tools/pylintrc --output-format=parseable --reports=y nodes/* src/* > pylint.log || echo ''")
//                        }
//                }

//                stage('Publish Test / Lint / Coverage Results') {
//                        steps {
//                                echo "Publish Test Results\n===============================\n"
//                                junit '*UnitTestResults*.xml'
//                                cobertura coberturaReportFile: '*coverage.xml'
//                                script{
//                                        def pylint=scanForIssues blameDisabled: true, tool: pyLint(pattern: "pylint.log")
//                                        publishIssues issues: [pylint], name: 'Static Analysis Results'
//                                }
//                                sh("./ros-build-tools/fail-on-pylint-score.sh ${pylint_threshold} pylint.log")
//                        }
//                }

                stage('Build'){

                        parallel{
                                stage('Build amd64') {
                                        steps {
                                                sh("tree")
                                                sh("docker run --rm --name ros2-build-amd64 --entrypoint \"/home/jca/workspace/src/package/rosbag2/build_package.sh\" -e BRANCH_NAME -e BUILD_NUMBER -v $PWD:/home/jca/workspace/src/package -t ${ros_build_registry}/amd64/${ros_build_image}")
                                        }
                                }

 //                               stage('Build armhf') {
 //                                       steps {
 //                                               sh("ros-build-tools/build-in-docker.sh armhf ${ros_build_version}")
 //                                       }
 //                               }

                                stage('Build arm64') {
                                        steps {
                                                sh("docker run --rm --name ros2-build-arm64 --entrypoint \"/home/jca/workspace/src/package/rosbag2/build_package.sh\" -e BRANCH_NAME -e BUILD_NUMBER -v $PWD:/home/jca/workspace/src/package -t ${ros_build_registry}/arm64/${ros_build_image}")
                                        }
                                }
                        }
                }
                stage('Publish'){
                        steps {
                                script {
                                        if(env.BRANCH_NAME=="master" || (env.BRANCH_NAME).startsWith("hotfix"))
                                        {
                                            sh("ros-build-tools/push-aptly-repo.sh \"${binaries}\" ${aptly_target} ${aptly_dist} release-foxy")
                                        }
                                        else if (env.BRANCH_NAME=="develop")
                                        {
                                            sh("ros-build-tools/push-aptly-repo.sh \"${binaries}\" ${aptly_target} ${aptly_dist} develop-foxy")
                                        }
                                        else if ((env.BRANCH_NAME).startsWith("rc"))
                                        {
                                            sh("ros-build-tools/push-aptly-repo.sh \"${binaries}\" ${aptly_target} ${aptly_dist} rc-foxy")
                                        }
                                        else
                                        {
                                            sh("ros-build-tools/push-aptly-repo.sh \"${binaries}\" ${aptly_target} ${aptly_dist} experimental-foxy")
                                        }
                                }
                        }
                }
        }

        post {
                always {
                        emailext(body: '${DEFAULT_CONTENT}', mimeType: 'text/html', replyTo: '$DEFAULT_REPLYTO', subject: '${DEFAULT_SUBJECT}', to: emailextrecipients([culprits(), requestor()]))
                        step([$class: 'Mailer', notifyEveryUnstableBuild: true, recipients: emailextrecipients([culprits(), requestor()]), sendToIndividuals: false])

                        script {
                                if (env.BRANCH_NAME == "master") {
                                        properties([buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '10'))])
                                        sh("git tag \$(dpkg-deb -f \$(ls deploy/*.deb | head -n 1) Version)")
                                        sh("git push --tags")
                                } else {
                                        properties([buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '5'))])
                                }
                        }
                }

                success {
                        archiveArtifacts artifacts: binaries, fingerprint: true

                        notifyBitbucket buildStatus: 'SUCCESS', buildName: env.BUILD_TAG, commitSha1: '', considerUnstableAsSuccess: false, credentialsId: '', disableInprogressNotification: false, ignoreUnverifiedSSLPeer: false, includeBuildNumberInKey: false, prependParentProjectKey: false, projectKey: '', stashServerBaseUrl: ''
                }

                unstable {
                        archiveArtifacts artifacts: binaries, fingerprint: false
                }

                failure {
                        notifyBitbucket buildStatus: 'FAILURE', buildName: env.BUILD_TAG, commitSha1: '', considerUnstableAsSuccess: false, credentialsId: '', disableInprogressNotification: false, ignoreUnverifiedSSLPeer: false, includeBuildNumberInKey: false, prependParentProjectKey: false, projectKey: '', stashServerBaseUrl: ''
                }

                cleanup {
                        cleanWs()
                }
        }
}
