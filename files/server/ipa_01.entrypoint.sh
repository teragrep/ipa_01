#!/usr/bin/bash
ipa_01_poweroff() {
    echo "Failure detected, powering off";
    systemctl start poweroff.target;
}

trap 'ipa_01_poweroff' ERR;

IPA_01_SERVER_FLAGS="${IPA_01_SERVER_FLAGS:---auto-reverse --setup-dns --no-forwarders --no-ntp}";
for required_env_var in IPA_01_DOMAIN IPA_01_MANAGER_PASSWORD IPA_01_ADMIN_PASSWORD; do
    if [ "${!required_env_var}" == "" ]; then
        echo "Failed to find value for '${required_env_var}', failing";
        exit 1;
    fi;
done;

for file in /ipa_01.conf.d/pre/*.sh; do
    [[ -x "${file}" ]] && bash "${file}";
done;

# shellcheck disable=SC2086 # Server flags are intentionally without quotes.
ipa-server-install --unattended --domain "${IPA_01_DOMAIN,,}" --realm "${IPA_01_DOMAIN^^}" --ds-password "${IPA_01_MANAGER_PASSWORD}" --admin-password "${IPA_01_ADMIN_PASSWORD}" ${IPA_01_SERVER_FLAGS};

for file in /ipa_01.conf.d/post/*.sh; do
    [[ -x "${file}" ]] && bash "${file}";
done;

touch /ipa_01.ready;

exit 0;
