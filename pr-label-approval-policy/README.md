# 🏷️ Dynamic PR Label-Driven Approval Policy

Auto-approve routine CI deploys, but **hold for a human** when a PR is explicitly
flagged or when the plan would delete resources. Combines two env0 primitives:

1. **Custom Flow** (`env0.yaml`) — fetches the merged PR's GitHub labels and writes
   them into a policy-data JSON file.
2. **Approval Policy** (`policy/pr_label_approval.rego`, OPA/Rego) — reads that data
   via `input.policyData` plus the Terraform plan, and decides: auto-approve or hold.

```
PR merged → CI triggers deploy → plan runs → custom flow fetches PR labels
   → writes policyData JSON → OPA policy evaluates:
       ├── "skip-approval" label?     → HOLD for approval 🔒
       ├── plan contains deletions?   → HOLD for approval 🗑️
       └── neither (CI trigger)?      → AUTO-APPROVE ✅
```

## What's in this folder

| File | Purpose |
|---|---|
| `main.tf` / `variables.tf` / `outputs.tf` | Small S3 demo. The optional `logs` bucket lets you produce a `delete` action on demand |
| `terraform.auto.tfvars` | Default variables |
| `env0.yaml` | Custom flow — fetches PR labels into `ENV0_POLICY_DATA_PATH` after `terraformPlan` |
| `policy/pr_label_approval.rego` | The approval logic |

---

## Decision Matrix

| `triggerName` | `skip-approval` label | Deletions | Result |
|---|---|---|---|
| `cd` | ❌ | ❌ | ✅ Auto-approve |
| `cd` | ✅ | ❌ | 🔒 Pending |
| `cd` | ❌ | ✅ | 🔒 Pending |
| `cd` | ✅ | ✅ | 🔒 Pending |
| `user` / any | any | any | 🔒 Pending (no `allow` rule fires → env0 default) |

---

## Step-by-Step Setup

### 1. Create the env0 Template

In env0: **Templates → Add New → Terraform**.

| Field | Value |
|---|---|
| **IaC Type** | Terraform |
| **Repository** | this repo |
| **Working Directory** | `pr-label-approval-policy` |
| **Terraform Version** | `>= 1.0` |

The `env0.yaml` in this folder is picked up automatically.

### 2. Set Environment Variables on the Template (or Project)

| Variable | Value | Notes |
|---|---|---|
| `GITHUB_TOKEN` | a PAT with repo read | **Mark as Sensitive** |
| `GITHUB_ORG` | e.g. `env0` | repo owner |
| `GITHUB_REPO` | e.g. `env0-demos` | repo name |
| `ENV0_POLICY_DATA_PATH` | `/tmp/policy_data.json` | where the flow writes labels and the policy reads them |
| `bucket_prefix` | a globally-unique prefix | Terraform var |

> For a quick demo without GitHub wiring, set `DEMO_PR_LABELS` instead (see
> [Demo Walkthrough](#demo-walkthrough)) — the flow skips the API call entirely.

### 3. Create the Approval Policy

In env0: **Organization Settings → Approval Policies → Add Approval Policy**.

- Point it at a repo/path containing `policy/pr_label_approval.rego` (a dedicated
  policy repo or this folder's `policy/` directory).
- Package name is `env0` and the rules are `allow` / `pending` — env0's expected contract.

### 4. Assign the Policy

Attach the Approval Policy to this **template** (or the **project** it lives in).
With the policy assigned, every deployment evaluates the Rego before apply.

### 5. (Optional) Inspect the policy input while testing

Set `ENV0_PRINT_POLICY_INPUT=true` on the template to dump the full `input`
(plan + `deploymentRequest` + merged `policyData`) into the deploy log — handy
for confirming labels landed where the policy expects them.

---

## Demo Walkthrough

You can drive all four matrix outcomes without touching GitHub by setting
`DEMO_PR_LABELS` (a JSON array) and/or toggling `create_logs_bucket`.

**A) Auto-approve — the happy path**
- Trigger: a CI/`cd` deploy (or set `DEMO_PR_LABELS='[]'`)
- `create_logs_bucket = true` (no deletions on first apply)
- → Policy returns `allow` → deploy proceeds with no human gate ✅

**B) Hold — flagged PR**
- Set `DEMO_PR_LABELS='["skip-approval"]'`
- → `pending` fires → deployment waits for manual approval 🔒

**C) Hold — destructive plan**
- After a successful apply, set `create_logs_bucket = false` and re-deploy
- The plan now shows the `logs` bucket being **deleted**
- → `pending` fires on the deletion branch 🗑️

**D) Hold — manual trigger**
- Trigger a deploy manually (`triggerName` ≠ `cd`)
- → no `allow` rule matches → env0 holds by default 🔒

---

## How It Fits Together

- The custom flow runs in `terraformPlan.after`, so `/tmp/policy_data.json` exists
  **before** the approval policy is evaluated (policies run after plan, before apply).
- env0 merges that file into `input.policyData`, and provides `input.plan` and
  `input.deploymentRequest` automatically.
- The Rego reads all three and emits `allow` (auto-approve) or `pending` (hold).

## Extending

Add more labels and rules as guardrails grow:

```rego
pending contains msg if {
	has_label("production-deploy")
	msg := "Production deploy flagged — manual approval required 🔒"
}
```

Other ideas: `needs-security-review`, environment-scoped rules keyed on
`input.deploymentRequest`, or holding on specific resource types in the plan.
