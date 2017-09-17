package com.pymag.dsl


class Docker implements Serializable {
	boolean IsDockerInstalled
    def containerName
    Map<String, String> dockerInfo

	Docker(){
		this.IsDockerInstalled=false
        this.containerName=""
		CheckDockerInstalled()
	}
    Docker(container){
        this.IsDockerInstalled=false
        this.containerName=container
        CheckDockerInstalled()
    }

	boolean getIsDockerInstalled(){
		return this.IsDockerInstalled
	}

    @NonCPS
    private String DockerExecCommand(String command){
        def sout = new StringBuilder()
        def serr = new StringBuilder()
        def proc = "sudo ${command}".execute()

        proc.consumeProcessOutput(sout, serr)
        proc.waitForOrKill(1000)
        return proc.exitValue() ? null : sout.toString()
    }

    @NonCPS
    private void CheckDockerInstalled() {
        String d_comm_res

        d_comm_res = DockerExecCommand("docker info")
        if (!d_comm_res.isEmpty()) {
            dockerInfo = d_comm_res.
                    split("\\r?\\n").
                    each { it.trim() }.
                    collectEntries {
                        def key_val = it.split(": ")
                        [(key_val.first()): key_val.last()]
                    }
            this.IsDockerInstalled = true
        }
    }

    @NonCPS
    boolean IsContainerRunnig(){
        if (!DockerExecCommand("docker ps -f \"name=${containerName}\" -q").isEmpty())
            return true
    }
}