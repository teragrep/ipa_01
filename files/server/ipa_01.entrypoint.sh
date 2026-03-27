#!/usr/bin/bash
# shellcheck disable=SC2329 # This is invoked via trap
ipa_01_poweroff() {
    echo "Failure detected, powering off";
    systemctl start poweroff.target;
}

trap 'ipa_01_poweroff' ERR;

IPA_01_SERVER_FLAGS="${IPA_01_SERVER_FLAGS:---auto-reverse --setup-dns --no-forwarders --no-ntp}";
for required_env_var in IPA_01_DOMAIN IPA_01_MANAGER_PASSWORD IPA_01_ADMIN_PASSWORD IPA_01_ENROLL_USER_PASSWORD; do
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

echo "${IPA_01_ADMIN_PASSWORD}" | kinit admin;
echo "${IPA_01_ENROLL_USER_PASSWORD}" | ipa user-add srv-ipa_01 --first=ipa_01 --last=ServiceUser --shell /sbin/nologin --password;
ipa user-mod srv-ipa_01 --password-expiration="$(date -d "+1 year" +"%Y-%m-%d 00:00:00Z")";
ipa privilege-add "Host Enrollment Privilege" --desc="Privilege for enrolling new hosts";
ipa privilege-add-permission "Host Enrollment Privilege" --permissions="System: Add Hosts" --permissions="System: Enroll a Host" --permissions="System: Manage Host Keytab";
ipa role-add "Host Enrollment Role" --desc="Host enrollment only"
ipa role-add-privilege "Host Enrollment Role" --privileges="Host Enrollment Privilege"
ipa role-add-member "Host Enrollment Role" --users=srv-ipa_01;
kdestroy -A;

for file in /ipa_01.conf.d/post/*.sh; do
    [[ -x "${file}" ]] && bash "${file}";
done;

touch /ipa_01.ready;

exit 0;
