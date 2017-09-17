package pymag.dsl


class Docker implements Serializable {
	boolean IsDockerInstalled

	Docker(){
		this.IsDockerInstalled=false
		CheckDockerInstalled()
	}
	def getIsDockerInstalled(){
		return this.IsDockerInstalled
	}

    private void CheckDockerInstalled(){
		def sout = new StringBuilder()
		def serr = new StringBuilder()
		def proc = 'sudo docker info'.execute()

		proc.consumeProcessOutput(sout, serr)
		proc.waitForOrKill(1000)
		if (!proc.exitValue()) {
			def info=sout.toString().split("\\r?\\n").each{ it.trim() }.collectEntries {
				def key_val=it.split(": ")
				[(key_val.first()):key_val.last()]
			}
			//println "Docker version: ${info["Server Version"]}"
			this.IsDockerInstalled=true
		}
//        else {
//			println serr
//		}
	}
}
