#!/usr/bin/bash
# shellcheck disable=SC2329 # This is invoked via trap
ipa_01_poweroff() {
    echo "Failure detected, powering off";
    systemctl start poweroff.target;
}

trap 'ipa_01_poweroff' ERR;

IPA_01_CLIENT_FLAGS="${IPA_01_CLIENT_FLAGS:---no-ntp --force-join}";
for required_env_var in IPA_01_SERVER_HOSTNAME IPA_01_DOMAIN IPA_01_ADMIN_PASSWORD; do
    if [ "${!required_env_var}" == "" ]; then
        echo "Failed to find value for '${required_env_var}', failing";
        exit 1;
    fi;
done;

for file in /ipa_01.conf.d/pre/*.sh; do
    [[ -x "${file}" ]] && bash "${file}";
done;

# shellcheck disable=SC2086 # Client flags are intentionally without quotes.
ipa-client-install --unattended --server "${IPA_01_SERVER_HOSTNAME}" --domain "${IPA_01_DOMAIN,,}" --principal "admin@${IPA_01_DOMAIN^^}" --password "${IPA_01_ADMIN_PASSWORD}" ${IPA_01_CLIENT_FLAGS};

for file in /ipa_01.conf.d/post/*.sh; do
    [[ -x "${file}" ]] && bash "${file}";
done;

touch /ipa_01.ready;

exit 0;
