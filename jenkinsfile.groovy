def repository = 'hydro-serving-sidecar'

def buildFunction = {
    def curVersion = getVersion()
    sh "docker build -t hydrosphere/serving-sidecar:${curVersion} ."
}

pipelineCommon(
        repository,
        false, //needSonarQualityGate,
        ["hydrosphere/serving-sidecar"],
        {},//collectTestResults, do nothing
        buildFunction,
        buildFunction,
        buildFunction,
        null,
        "",
        "",
        {},
        commitToCD("sidecar", "dev")
)
