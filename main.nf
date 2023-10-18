#!/usr/bin/env nextflow
nextflow.enable.dsl=2 

params.fail = false
params.computeEnvironment = "main"
params.repoOwner = "nextflow-io"
params.repoName = "rnaseq-nf"
params.commit = "466e03efdd4d33f5e16e0b83ebd19e8f4d1474ca"

log.info """\
 ===================================
 fail                : ${params.fail}
 computeEnvironment  : ${params.computeEnvironment}
 repoOwner           : ${params.repoOwner}
 repoName            : ${params.repoName}
 commit              : ${params.commit}
 ===================================
 """

process sayHello {
  input: 
    val exitCode
  output:
    stdout
  script:
    """
    echo 'Hello world!'
    exit $exitCode
    """
}

workflow {
  sayHello(params.fail ? 1 : 0)
}

workflow.onComplete {
    if (!workflow.success) {
        println "Workflow failed :("
        return
    }

    println "Workflow completed :)"

    def beakerUrl = System.getenv('BEAKER_URL')
    def beakerToken = System.getenv('BEAKER_TOKEN')

    def body = groovy.json.JsonOutput.toJson([
        computeEnvironment: params.computeEnvironment,
        name: "Subsequent workflow",
        workflow: [
            repo: [
                owner: params.repoOwner,
                repo: params.repoName
            ],
            ref: [
                type: "COMMIT",
                value: params.commit
            ],
            type: "GITHUB_REPO"
        ]
    ])

    def apiRequest = new URL("${beakerUrl}/api/v1/workflow-runs").openConnection()
    apiRequest.setRequestProperty("Authorization", "Bearer ${beakerToken}")
    apiRequest.setRequestMethod("POST")
    apiRequest.setDoOutput(true)
    apiRequest.setRequestProperty("Content-Type", "application/json")
    apiRequest.getOutputStream().write(body.getBytes("UTF-8"))

    def res = new groovy.json.JsonSlurper().parseText(apiRequest.getInputStream().getText())
    println("Next workflow started at: ${res.workflowRun.webUrl}")
}