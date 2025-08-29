pipeline {
  agent any
  stages {
    stage('Run Robot with fresh venv') {
      steps {
        sh '''
          python3 -m venv .venv
          . .venv/bin/activate
          pip install -U pip robotframework
          mkdir -p results
          robot -d results robot/tests
        '''
      }
    }
  }
  post {
    always {
      archiveArtifacts artifacts: 'results/**', fingerprint: true
      script {
        try {
          robot outputPath: 'results', outputFileName: 'output.xml',
                reportFileName: 'report.html', logFileName: 'log.html'
        } catch (e) { echo 'Install Robot Framework plugin to see reports.' }
      }
    }
  }
}
