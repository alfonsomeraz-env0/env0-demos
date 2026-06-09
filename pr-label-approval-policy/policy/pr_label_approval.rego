package env0

# Import all three future keywords. env0's OPA (0.46.1) needs these explicit
# imports to accept the `allow contains msg if { ... }` rule-head syntax;
# newer OPA (1.x) accepts the imports too, so this parses on both.
import future.keywords.contains
import future.keywords.if
import future.keywords.in

# ===========================================================================
# Dynamic PR Label-Driven Approval Policy
#
# Decision flow (initial request):
#   CI deploy + no "skip-approval" label + no deletions  -> auto-approve
#   "skip-approval" label present                        -> hold for approval
#   plan contains deletions                              -> hold for approval
#   anything else                                        -> hold (env0 default)
#
# After a human approves, env0 RE-EVALUATES the policy on a "resume" pass
# (deploymentRequest.type = deployResume / destroyResume). The hold conditions
# (the label, the deletions) are still true on that pass, so without a guard
# the policy would return `pending` again and the deployment would get stuck in
# an approve -> re-hold loop. We therefore:
#   * only apply the `pending` rules on the INITIAL request, and
#   * explicitly `allow` on the resume pass (it was already approved).
#
# Inputs env0 provides automatically:
#   input.deploymentRequest.type         - deploy | destroy | deployResume | destroyResume
#   input.deploymentRequest.triggerName  - "cd" for CI, "manual"/"user" otherwise
#   input.plan.resource_changes[]        - terraform plan, per-resource actions
#   input.policyData.pr_labels[]         - injected by the env0.yaml custom flow
# ===========================================================================

# --- Helpers ---------------------------------------------------------------

# True on the post-approval re-evaluation (deployResume / destroyResume).
is_resume if {
	endswith(input.deploymentRequest.type, "Resume")
}

# True if the plan deletes (or replaces) any resource.
has_deletions if {
	input.plan.resource_changes[_].change.actions[_] == "delete"
}

# True if a given PR label is present.
has_label(label) if {
	input.policyData.pr_labels[_] == label
}

# --- AUTO-APPROVE: already approved, resuming ------------------------------
# Without this, a resume pass returns no result and env0 holds by default,
# which is the approve -> re-hold loop.
allow contains msg if {
	is_resume
	msg := "Deployment resumed after approval — proceeding ✅"
}

# --- AUTO-APPROVE: initial CI deploy, no skip label, no deletions ----------
allow contains msg if {
	not is_resume
	input.deploymentRequest.triggerName == "cd"
	not has_label("skip-approval")
	not has_deletions
	msg := "CI deploy, no deletions, no skip-approval label — auto-approved"
}

# --- HOLD: explicit label (initial request only) ---------------------------
pending contains msg if {
	not is_resume
	has_label("skip-approval")
	msg := "PR label 'skip-approval' present — manual approval required"
}

# --- HOLD: destructive plan (initial request only) -------------------------
pending contains msg if {
	not is_resume
	has_deletions
	msg := "Plan includes resource deletions — manual approval required"
}
