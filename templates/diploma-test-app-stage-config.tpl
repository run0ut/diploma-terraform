<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@1239.v71b_b_a_124a_725">
  <actions>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobAction plugin="pipeline-model-definition@2.2114.v2654ca_721309"/>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction plugin="pipeline-model-definition@2.2114.v2654ca_721309">
      <jobProperties>
        <string>jenkins.model.BuildDiscarderProperty</string>
      </jobProperties>
      <triggers>
        <string>hudson.triggers.SCMTrigger</string>
      </triggers>
      <parameters/>
      <options/>
    </org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction>
    <org.jenkinsci.plugins.workflow.multibranch.JobPropertyTrackerAction plugin="workflow-multibranch@716.vc692a_e52371b_">
      <jobPropertyDescriptors>
        <string>org.jenkinsci.plugins.workflow.job.properties.DisableConcurrentBuildsJobProperty</string>
      </jobPropertyDescriptors>
    </org.jenkinsci.plugins.workflow.multibranch.JobPropertyTrackerAction>
  </actions>
  <description></description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <jenkins.model.BuildDiscarderProperty>
      <strategy class="hudson.tasks.LogRotator">
        <daysToKeep>-1</daysToKeep>
        <numToKeep>10</numToKeep>
        <artifactDaysToKeep>-1</artifactDaysToKeep>
        <artifactNumToKeep>10</artifactNumToKeep>
      </strategy>
    </jenkins.model.BuildDiscarderProperty>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <hudson.triggers.SCMTrigger>
          <spec>* * * * *</spec>
          <ignorePostCommitHooks>false</ignorePostCommitHooks>
        </hudson.triggers.SCMTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
    <org.jenkinsci.plugins.workflow.job.properties.DisableConcurrentBuildsJobProperty>
      <abortPrevious>false</abortPrevious>
    </org.jenkinsci.plugins.workflow.job.properties.DisableConcurrentBuildsJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2802.v5ea_628154b_c2">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.12.1">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/${login}/diploma-test-app.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/*</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>