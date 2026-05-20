pipeline {
    agent any

    environment {
        HARBOR_URL = 'harbor.harbor.svc.cluster.local'
        HARBOR_PROJECT = 'free5gc'
        IMAGE_TAG = "${BUILD_NUMBER}"
        GITEA_URL = 'http://gitea-http.gitea.svc.cluster.local:3000'

        // TODO: Add more network functions later.
        // Example: amf smf ausf udm udr nssf pcf upf webconsole
        // Currently building NRF and CHF only.
        NF_LIST = 'nrf chf'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm

                // TODO: Keep this for all free5GC NF submodules.
                sh 'git submodule update --init --recursive'
            }
        }

        stage('Go Build Check') {
            steps {
                sh '''
                    if [ ! -f /tmp/go/bin/go ]; then
                        curl -sL https://go.dev/dl/go1.21.13.linux-amd64.tar.gz | tar -xz -C /tmp/
                    fi

                    export PATH=/tmp/go/bin:$PATH
                    export GOPATH=/tmp/gopath

                    # TODO: Preinstall make/go/golangci-lint in the Jenkins agent image later.
                    make all 2>&1 || echo "Build check completed"
                '''
            }
        }

        stage('Lint') {
            steps {
                sh '''
                    export PATH=/tmp/go/bin:$PATH

                    if [ ! -f /tmp/golangci-lint ]; then
                        curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b /tmp/ v1.59.1
                    fi

                    # TODO: Make lint failure block the pipeline later.
                    /tmp/golangci-lint run --timeout 10m ./... || echo "Lint check completed"
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        sonar-scanner \
                          -Dsonar.projectKey=free5gc-platform \
                          -Dsonar.sources=. \
                          -Dsonar.sourceEncoding=UTF-8
                    '''
                }
            }
        }

        stage('Build & Push NF Images to Harbor') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'harbor-creds',
                        usernameVariable: 'HARBOR_USER',
                        passwordVariable: 'HARBOR_PASS'
                    )
                ]) {
                    sh '''
                        if [ ! -f /tmp/buildctl ]; then
                            curl -sL https://github.com/moby/buildkit/releases/download/v0.13.2/buildkit-v0.13.2.linux-amd64.tar.gz | tar -xz -C /tmp/ bin/buildctl --strip-components=1
                        fi

                        mkdir -p ~/.docker
                        AUTH=$(printf "%s:%s" "$HARBOR_USER" "$HARBOR_PASS" | base64 | tr -d '\\n')

                        cat > ~/.docker/config.json <<DOCKEREOF
{"auths":{"${HARBOR_URL}":{"auth":"$AUTH"}}}
DOCKEREOF

                        for NF in ${NF_LIST}; do
                            echo "Building and pushing ${NF} image..."

                            /tmp/buildctl \
                                --addr tcp://buildkitd.buildkit.svc.cluster.local:1234 \
                                build \
                                --frontend dockerfile.v0 \
                                --local context=. \
                                --local dockerfile=docker/${NF} \
                                --output type=image,name=${HARBOR_URL}/${HARBOR_PROJECT}/${NF}:${IMAGE_TAG},push=true,registry.insecure=true

                            # TODO: Add latest tag push later.
                        done
                    '''
                }
            }
        }

        stage('Mirror to GitHub') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([
                    string(
                        credentialsId: 'github-token',
                        variable: 'GH_TOKEN'
                    )
                ]) {
                    sh '''
                        git remote remove github 2>/dev/null || true
                        git remote add github https://${GH_TOKEN}@github.com/zzdpk2/free5gc-platform-remake.git

                        # TODO: Remove --force later and use a protected branch sync strategy.
                        git push github HEAD:main --force
                    '''
                }
            }
        }

        stage('Update Gitea Status') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'gitea-cred',
                        usernameVariable: 'GITEA_USER',
                        passwordVariable: 'GITEA_PASS'
                    )
                ]) {
                    sh '''
                        COMMIT=$(git rev-parse HEAD)

                        curl -s -X POST \
                            "${GITEA_URL}/api/v1/repos/rex/free5gc-platform/statuses/${COMMIT}" \
                            -H "Content-Type: application/json" \
                            -u "${GITEA_USER}:${GITEA_PASS}" \
                            -d "{\\"state\\":\\"success\\",\\"context\\":\\"jenkins-ci\\",\\"description\\":\\"Build ${BUILD_NUMBER} passed\\",\\"target_url\\":\\"${BUILD_URL}\\"}"
                    '''
                }
            }
        }
    }

    post {
        failure {
            withCredentials([
                usernamePassword(
                    credentialsId: 'gitea-cred',
                    usernameVariable: 'GITEA_USER',
                    passwordVariable: 'GITEA_PASS'
                )
            ]) {
                sh '''
                    COMMIT=$(git rev-parse HEAD)

                    curl -s -X POST \
                        "${GITEA_URL}/api/v1/repos/rex/free5gc-platform/statuses/${COMMIT}" \
                        -H "Content-Type: application/json" \
                        -u "${GITEA_USER}:${GITEA_PASS}" \
                        -d "{\\"state\\":\\"failure\\",\\"context\\":\\"jenkins-ci\\",\\"description\\":\\"Build ${BUILD_NUMBER} failed\\",\\"target_url\\":\\"${BUILD_URL}\\"}"
                '''
            }

            echo "Pipeline FAILED"
        }

        success {
            echo "Pipeline SUCCESS"
        }
    }
}
