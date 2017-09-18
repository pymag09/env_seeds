package com.pymag.dsl


class Docker implements Serializable {
    String containerName
    Map<String, String> dockerInfo

    Docker(String container){
        this.containerName=container
        CheckDockerInstalled()
    }

    @NonCPS
    private String DockerExecCommand(String command){
        def sout = new StringBuilder()
        def serr = new StringBuilder()
        def proc = "sudo ${command}".execute()

        proc.consumeProcessOutput(sout, serr)
        proc.waitForOrKill(1000)
        assert !proc.exitValue() : "${serr}"
        return sout.toString()
    }

    @NonCPS
    private void CheckDockerInstalled() {
        String d_comm_res = DockerExecCommand("docker info")
        dockerInfo = d_comm_res.
                split("\\r?\\n").
                each { it.trim() }.
                collectEntries {
                    def key_val = it.split(": ")
                    [(key_val.first()): key_val.last()]
                }
    }

    @NonCPS
    boolean IsContainerNotRunnig(){
        return DockerExecCommand("docker ps -f \"name=${containerName}\" -q").isEmpty()
    }
}