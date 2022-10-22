#!/bin/bash
##########################################################################
# Simple template modification script to customize cloud-init user-data 
# cloud-init logs are in /run/cloud-init/result.json
# <3 max
#
# If we want to debug the user-data in cloud-init, we can try the following steps:
# https://cloudinit.readthedocs.io/en/latest/topics/debugging.html
#
#    # Reset and re-run
#    sudo rm -rf /var/lib/cloud/*
#    sudo cloud-init init
#    sudo cloud-init modules -m final
#    
#    # Analyze logs
#    sudo cloud-init analyze show -i /var/log/cloud-init.log
#    sudo cloud-init analyze dump -i /var/log/cloud-init.log
#    sudo cloud-init analyze blame -i /var/log/cloud-init.log
#    
#    # Run single module
#    sudo cloud-init single --name cc_ssh --frequency always
#########################################################################
set -o pipefail

parse_params() {
        while :; do
                case "${1-}" in
                -h | --help) usage ;;
                -v | --verbose) set -x ;;
                -s | --slim) export SLIM="true" ;;
                -upd | --update) export UPDATE="true" ;;
                -upg | --upgrade) export UPGRADE="true" ;;
                -p | --password)
                        export PASSWD="${2-}"
                        shift
                        ;;
                -u | --username)
                        export USER="${2-}"
                        shift
                        ;;
                -gh | --github-username)
                        export GITHUB_USER="${2-}"
                        shift
                        ;;
                -n | --vm-name)
                        export VM_NAME="${2-}"
                        export VM_ADMIN="${VM_NAME}admin"
                        shift
                        ;;
                -ip | --ip-address)
                        export IP_ADDRESS="${2-}"
                        shift
                        ;;
                -gw | --gateway)
                        export GATEWAY="${2-}"
                        shift
                        ;;
                -dns | --dns-server)
                        export DNS="${2-}"
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

        if [ ! $SLIM ]; then
            export SLIM="false"
        fi

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

-s, --slim              Use a minimal version of the user-data template.

-upd, --update          Update apt packages during provisioning

-upg, --upg             Upgrade packages during provisioning

-p, --password          Password to set up for the VM Users.

-u, --username          Username for non-system account

-i, --ip-address        IP address for netplan to apply.

-gw, --gateway          IP address for the default network gateway

-dns, --dns-server      IP address for your DNS server

-gh, --github-username  Github username from which to pull public keys

-n, --vm-name           Hostname/name for the Virtual Machine. Influences the name of the syste account - no special chars plz.

EOF
        exit
}

# create a ssh key for the user and save as a file w/ prompt
create_ssh_key(){
  log "🔐 Create an SSH key for the VM admin user"

  yes |ssh-keygen -C "$VM_ADMIN" \
    -f "${VM_ADMIN}" \
    -N '' \
    -t rsa 1> /dev/null

  export VM_KEY_FILE=$(find "$(cd ..; pwd)" -name "${VM_ADMIN}")
  export VM_KEY=$(cat "${VM_KEY_FILE}".pub)
  log " - Done."

}

verify_deps(){
    log "🔎 Checking for required utilities..."
    [[ ! -x "$(command -v whois)" ]] && die "💥 whois is not installed. On Ubuntu, install  the 'whois' package."
    log " - All required utilities are installed."
}



create_slim_user_data(){
log "📝 Create a minimal user-data file"

cat > user-data <<EOF

EOF

log " - Done."
}

create_full_user_data(){
log "📝 Create a full user-data file"

cat > user-data <<EOF

EOF

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

main(){
create_ssh_key

if [ "$SLIM" == "true" ]; then
  create_slim_user_data
else
  #create_ansible_user_data
  create_full_user_data
fi
}

parse_params "$@"
main

