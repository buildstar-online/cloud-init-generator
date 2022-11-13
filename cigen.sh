#!/bin/bash
##########################################################################
# Simple template modification script to customize cloud-init user-data
# cloud-init logs are in /run/cloud-init/result.json
# <3 max
#########################################################################
set -o pipefail

parse_params() {
        while :; do
                case "${1-}" in
                -h | --help) usage ;;
                -v | --verbose) set -x ;;
                -upd | --update) export UPDATE="true" ;;
                -upg | --upgrade) export UPGRADE="true" ;;
                -t | --template)
                        export TEMPLATE="${2-}"
                        shift
                        ;;
                -p | --password)
                        PASSWD=$(mkpasswd -m sha-512 --rounds=4096 \
                            "${2-}" -s "saltsaltlettuce")
                        shift
                            ;;
                -u | --username)
                        export USERNAME="${2-}"
                        shift
                        ;;
                -gh | --github-username)
                        export GITHUB_USER="${2-}"
                        shift
                        ;;
                -n | --vm-name)
                        export VM_NAME="${2-}"
                        shift
                        ;;
                -e | --extra-vars)
                        IFS=','
                        read -r -a VAR_ARRAY <<< "${2-}"
                        for ELEMENT in "${VAR_ARRAY[@]}"
                        do
                            export "$ELEMENT"
                            log "Export extra var: $ELEMENT"
                        done
                        IFS=' '
                        shift
                        ;;
                -?*) die "Unknown option: $1" ;;
                *) break ;;
                esac
                shift
        done

        if [ ! $UPDATE ]; then
            export UPDATE="false"
        fi

        if [ ! $UPGRADE ]; then
            export UPGRADE="false"
        fi

        if [ ! $TEMPLATE ]; then
            TEMPLATE="slim.yaml"
        fi

        if [ ! $USERNAME ]; then
            export USERNAME=$USER
        fi

        if [ ! $GITHUB_USER ]; then
            export GH_USER_IMPORT="False"
        fi

        if [ ! $PASSWORD ]; then
            PASSWORD=$(mkpasswd -m sha-512 --rounds=4096 \
                "password" -s "saltsaltlettuce")
        fi

        if [ ! $VM_NAME ]; then
            export VM_NAME=$(cat /dev/urandom | env LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        fi

        export VM_ADMIN="${VM_NAME}admin"
        return 0
}

# help text
usage(){
        cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-s] [-upd] [-upg] [-p <password>] [-u <user>] [-gh <user>] [-n <name>]

💁 This script will quickly modify a cloud-init user-data template that can be used to provision virtual-machines, metal, and containers.

Available options:

-h, --help              Print this help and exit

-v, --verbose           Print script debug info

-upd, --update          Update apt packages during provisioning
                        Defaults to False

-upg, --upg             Upgrade packages during provisioning
                        Defaults to False

-t, --template          The template to use as the base for clopud-init.
                        Templates are located in the templates directory.
                        Defaults to 'slim.yaml' if no value specified.

-p, --password          Password to set up for the VM Users.
                        Defaults to 'password' if no value is specified

-u, --username          Username for non-system account
                        Defaults to the current shell user

-gh, --github-username  (Optional) Github username from which to pull public keys

-n, --vm-name           Hostname/name for the Virtual Machine. Influences the
                        name of the syste account - no special chars plz.

-e, --extra-vars        Some templates will require extra values.
                        Use this option to supply these values as
                        Key-Value-Pairs separated via commas.
                        Example: -e "VAR0='some string'","VAR1=$(pwd)"

EOF
        exit
}

verify_deps(){
    log "🔎 Checking for required utilities..."
    [[ ! -x "$(command -v whois)" ]] && die "💥 whois is not installed. On Ubuntu, install  the 'whois' package."
    log " - All required utilities are installed."
}

create_user_data(){
log "📝 Creating user-data file"

VALUES=$(envsubst < ${TEMPLATE})
echo -e "$VALUES" > user-data.yaml

log "📝 Checking against the cloud-inint schema..."

RESULT=$(cloud-init schema --config-file user-data.yaml)
log "$RESULT"
mv user-data.yaml /output/user-data.yaml

if [ "$RESULT" != "Valid cloud-config: user-data.yaml" ]; then
    log "user-data.yaml failed validation with error: $RESULT"
    exit
fi

log " - Done."
}

log() {
    echo >&2 -e "[$(date +"%Y-%m-%d %H:%M:%S")] ${1-}"
}

# kill on error
die() {
        local MSG=$1
        local CODE=${2-1} # Bash parameter expansion - default exit status 1. See https://wiki.bash-hackers.org/syntax/pe#use_a_default_value
        log "${MSG}"
        exit "${CODE}"
}

verify_deps
parse_params "$@"
create_user_data
