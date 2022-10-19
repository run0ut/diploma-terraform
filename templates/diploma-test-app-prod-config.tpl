<?xml version='1.1' encoding='UTF-8'?>
<org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject plugin="workflow-multibranch@716.vc692a_e52371b_">
  <actions/>
  <description></description>
  <displayName>diploma-test-app-prod</displayName>
  <properties/>
  <folderViews class="jenkins.branch.MultiBranchProjectViewHolder" plugin="branch-api@2.1046.v0ca_37783ecc5">
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
  </folderViews>
  <healthMetrics/>
  <icon class="jenkins.branch.MetadataActionFolderIcon" plugin="branch-api@2.1046.v0ca_37783ecc5">
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
  </icon>
  <orphanedItemStrategy class="com.cloudbees.hudson.plugins.folder.computed.DefaultOrphanedItemStrategy" plugin="cloudbees-folder@6.758.vfd75d09eea_a_1">
    <pruneDeadBranches>true</pruneDeadBranches>
    <daysToKeep>1</daysToKeep>
    <numToKeep>1</numToKeep>
    <abortBuilds>false</abortBuilds>
  </orphanedItemStrategy>
  <triggers>
    <com.cloudbees.hudson.plugins.folder.computed.PeriodicFolderTrigger plugin="cloudbees-folder@6.758.vfd75d09eea_a_1">
      <spec>* * * * *</spec>
      <interval>60000</interval>
    </com.cloudbees.hudson.plugins.folder.computed.PeriodicFolderTrigger>
  </triggers>
  <disabled>false</disabled>
  <sources class="jenkins.branch.MultiBranchProject$BranchSourceList" plugin="branch-api@2.1046.v0ca_37783ecc5">
    <data>
      <jenkins.branch.BranchSource>
        <source class="jenkins.plugins.git.GitSCMSource" plugin="git@4.12.1">
          <id>ca28478c-f18f-41bc-ab5e-53c66be01846</id>
          <remote>https://github.com/${login}/diploma-test-app.git</remote>
          <credentialsId></credentialsId>
          <traits>
            <jenkins.plugins.git.traits.TagDiscoveryTrait/>
            <jenkins.plugins.git.traits.CleanBeforeCheckoutTrait>
              <extension class="hudson.plugins.git.extensions.impl.CleanBeforeCheckout">
                <deleteUntrackedNestedRepositories>true</deleteUntrackedNestedRepositories>
              </extension>
            </jenkins.plugins.git.traits.CleanBeforeCheckoutTrait>
            <jenkins.plugins.git.traits.PruneStaleTagTrait>
              <extension class="hudson.plugins.git.extensions.impl.PruneStaleTag">
                <pruneTags>true</pruneTags>
              </extension>
            </jenkins.plugins.git.traits.PruneStaleTagTrait>
          </traits>
        </source>
        <strategy class="jenkins.branch.DefaultBranchPropertyStrategy">
          <properties class="empty-list"/>
        </strategy>
        <buildStrategies>
          <jenkins.branch.buildstrategies.basic.TagBuildStrategyImpl plugin="basic-branch-build-strategies@1.3.2">
            <atLeastMillis>-1</atLeastMillis>
            <atMostMillis>604800000</atMostMillis>
          </jenkins.branch.buildstrategies.basic.TagBuildStrategyImpl>
        </buildStrategies>
      </jenkins.branch.BranchSource>
    </data>
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
  </sources>
  <factory class="org.jenkinsci.plugins.workflow.multibranch.WorkflowBranchProjectFactory">
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
    <scriptPath>Jenkinsfile-prod</scriptPath>
  </factory>
</org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject>