# Single source of truth for the envsubst allowlist — the ONLY variables rendered
# into templated manifests. Sourced by lib/labkit.sh (apply/render at runtime) and
# by validate.sh (static render check), so the two can never drift.
#
# Allowlisting (vs. a bare `envsubst`) keeps shell-looking tokens in third-party
# YAML — e.g. the NGINX IC's $(POD_NAMESPACE) — untouched.
#
# When you add a topology variable to lab-vars.env.example, add it here too.
LABKIT_SUBST='${BIGIP_MGMT} ${BIGIP_PARTITION} ${CIS_IMAGE} ${CIS_NAMESPACE} ${NODEPORT_VIP} ${CLUSTER_VIP} ${NGINX_FRONT_VIP} ${INGRESSLINK_VIP} ${AS3_SCHEMA_VERSION} ${AS3_TENANT}'
