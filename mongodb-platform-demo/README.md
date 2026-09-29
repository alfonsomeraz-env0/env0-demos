# MongoDB Platform Demo

| Folder | What it shows | Deployable in env0 today |
|---|---|---|
| `onboarding/` | One-entry PR creates a sub-project per system (`env0_project`) | Yes; needs `ENV0_API_KEY`/`ENV0_API_SECRET` env vars and `parent_project_id` |
| `staged-workflow/` | One run deploys dev, then staging, then waits for approval before prod | Yes; reuses the `s3-bucket` template |
| `role-session-flow/` | Custom flow naming the AWS role session after the env0 deployment ID, for CloudTrail traceability | Needs an IAM role (`AWS_ROLE_ARN`) trusting the agent; verify `ENV0_DEPLOYMENT_LOG_ID` is the ID you want |

## Staged workflow setup

1. Template `mongodb-staged-workflow`, type **Workflow**, path `mongodb-platform-demo/staged-workflow`.
2. Create the environment with `deploy-manifest.yaml` to set per-stage bucket names.
3. Prod stops at approval; approve it to finish.

The `s3-bucket` template must already exist in the project (workflow resolves it by name).
