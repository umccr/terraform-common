# Terraform Common

Common modules/units/stacks used by reference from our Terraform (possibly Terragrunt)
infrastructure.

## How to commit

`release-please` reads https://www.conventionalcommits.org/ to decide version bumps. The scope
ties a commit to a specific module:

```
feat(aws-seqera-iam-setup): add EFS support         → minor bump
fix(aws-seqera-iam-setup): correct policy ARN       → patch bump
feat(aws-seqera-iam-setup)!: rename variable        → major bump
```

Commits without a matching scope are ignored for that module's release.




## How to add a new module

Add an entry to release-please-config.json and .release-please-manifest.json:

```json5
// release-please-config.json
"modules/new-module": {
  "release-type": "simple",
  "component": "new-module",
  "changelog-path": "CHANGELOG.md",
  "bump-minor-pre-major": true
}

// .release-please-manifest.json
"modules/new-module": "0.0.0"
```

