package pymag.dsl

class IsDockerInstalled implements Serializable {
	private boolean check

	IsDockerInstalled(){
		this.check=false
		Check()
	}

	def getCheck(){
		return this.check
	}
	private void Check(){
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
			echo "Docker version: ${info["Server Version"]}"
			this.check=true
		} else {
			echo serr
		}
	}
}
