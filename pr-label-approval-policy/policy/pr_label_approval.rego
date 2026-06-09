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
# Decision flow:
#   CI deploy + no "skip-approval" label + no deletions  -> auto-approve
#   "skip-approval" label present                        -> hold for approval
#   plan contains deletions                              -> hold for approval
#   anything else (no allow rule fires)                  -> hold (env0 default)
#
# Inputs env0 provides automatically:
#   input.deploymentRequest.triggerName  - "cd" for CI, "manual"/"user" otherwise
#   input.plan.resource_changes[]        - terraform plan, per-resource actions
#   input.policyData.pr_labels[]         - injected by the env0.yaml custom flow
# ===========================================================================

# --- Helpers ---------------------------------------------------------------

# True if the plan deletes (or replaces) any resource.
has_deletions if {
	some change in input.plan.resource_changes
	"delete" in change.change.actions
}

# True if a given PR label is present.
has_label(label) if {
	some l in input.policyData.pr_labels
	l == label
}

# --- AUTO-APPROVE ----------------------------------------------------------
# CI-triggered deploy, no skip-approval label, no deletions in the plan.
allow contains msg if {
	input.deploymentRequest.triggerName == "cd"
	not has_label("skip-approval")
	not has_deletions
	msg := "CI deploy, no deletions, no skip-approval label — auto-approved"
}

# --- HOLD: explicit label --------------------------------------------------
pending contains msg if {
	has_label("skip-approval")
	msg := "PR label 'skip-approval' present — manual approval required"
}

# --- HOLD: destructive plan ------------------------------------------------
pending contains msg if {
	has_deletions
	msg := "Plan includes resource deletions — manual approval required"
}
