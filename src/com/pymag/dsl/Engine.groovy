package com.pymag.dsl

class Engine implements Serializable {
  private boolean runInParallel
  private boolean runSonarTests

  Engine(def params){
    runInParallel = params.containsKey('run_parallel') ? params.run_parallel.toBoolean() : null
    runSonarTests = params.containsKey('run_sonar') ? params.run_sonar.toBoolean() : null
  }
  def parallelEnabled(){
    return runInParallel ? runInParallel : false
  }
  def includeSonarTests(){
    return runSonarTests ? runSonarTests : false
  }
}
