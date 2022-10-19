repos:
- id: github.com/${login}/diploma-terraform
  branch: /.*/
  allowed_overrides: [apply_requirements, workflow, delete_source_branch_on_merge]
  allow_custom_workflows: true
  delete_source_branch_on_merge: false
