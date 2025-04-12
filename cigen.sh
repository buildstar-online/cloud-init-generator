#!/bin/bash

set -Eeuo pipefail

trap - SIGINT SIGTERM ERR EXIT

# Verify that all required system deps are installed
[[ ! -x "$(command -v date)" ]] && echo "💥 date command not found." && exit 1
[[ ! -x "$(command -v bc)" ]] && echo "💥 bc command not found." && exit 1
[[ ! -x "$(command -v mkpasswd)" ]] && echo "💥 gettext-base command not found." && exit 1
[[ ! -x "$(command -v whois)" ]] && echo "💥 whois command not found." && exit 1
[[ ! -x "$(command -v git)" ]] && echo "💥 git command not found." && exit 1
[[ ! -x "$(command -v cloud-init)" ]] && echo "💥 cloud-init command not found." && exit 1
[[ ! -x "$(command -v wget)" ]] && echo "💥 wget command not found." && exit 1
[[ ! -x "$(command -v curl)" ]] && echo "💥 curl command not found." && exit 1

# Default Variable Declarations
export ENVSUBST="false"
export WIREGUARD_PATH=""
export USER_DATA_SECRET_PATH=""
export USER_DATA_PATH="/tmp/user-data.yaml"
export SALT="saltsaltlettuce"
export QUIET="false"

# Parse and validate user inputs.
parse_params() {
        while :; do
                case "${1-}" in
                -h | --help) usage ;;
                -v | --verbose) set -x ;;
                -e | --envsubst) export ENVSUBST="true" ;;
                -q | --quiet) export QUIET="true" ;;
                -s | --salt)
                        export SALT="${2-}"
                        shift
                        ;;
                -u | --userdata)
                        export USER_DATA_SECRET_PATH="${2-}"
                        shift
                        ;;
                -wg | --wireguard-config)
                        export WIREGUARD_PATH="${2-}"
                        shift
                        ;;


               -?*) die "Unknown option: $1" ;;
                *) break ;;
                esac
                shift
        done
    }

# help text
usage(){
        cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-u <path to file>] [-e] [-s <string>] [-wg <path to file>]

💁 This script will quickly modify a cloud-init user-data template that can be used to provision virtual-machines, metal, and containers.

Available options:

-h, --help              Print this help and exit

-v, --verbose           Print script debug info

-u, --userdata          Path to cloud-init user-data file (required)

-e, --envsubst          Enable usage of envsubst, disabled by default (optional)

-s, --salt              Salt to use when encrypting password (optional)

-w, --wireguard         Path to a Wireguard config file (optional)

EOF
        exit
}

# Run envsubst against the user-data file
#
# Note:
# This function will use all existing env vars to replace matching variable
# declarations. This can cause issues where a plain-text command uses a variable.
#
# Scripts that use a plain-text varibale should be encoded into a write_files entry
# to avoid this issue.
run_envsubst(){
    if [ "${ENVSUBST}" == "true" ]; then
        log "running envsubst against $USER_DATA_PATH..."
        envsubst < "${USER_DATA_PATH}" > /tmp/tmp.yaml
        mv /tmp/tmp.yaml "${USER_DATA_PATH}"
    fi
}

# Hash and insert passwd field for each specified user
admin_password(){
    read -ra users <<< $(yq '.users[].name' $USER_DATA_PATH |xargs)
    export COUNT=0

    for user in "${users[@]}"; do
        CHECK=$(yq '.users[env(COUNT)].passwd' $USER_DATA_PATH)
        if [ "${CHECK}" != "null" ]; then
            log "Setting hashed password for user: $user"
            CAP_USER=$(echo "${user}" | tr '[:lower:]' '[:upper:]')
            PASSWORD=$(env |grep "${CAP_USER}_PASSWORD" |cut -d '=' -f2)
            export HASHED_PASSWORD=$(mkpasswd --method=SHA-512 --rounds=4096 "${PASSWORD}" -s "${SALT}")
            yq -i '.users[env(COUNT)].passwd = env(HASHED_PASSWORD)' $USER_DATA_PATH
        fi
        export COUNT=$(($COUNT + 1))
    done
}

# Download, gzip, then b64 encode files from specified URLs
download_files(){
    read -ra urls <<< $(yq '.write_files[].url' "${USER_DATA_PATH}" |xargs)
    export COUNT=0

    for url in "${urls[@]}"; do
        if [ "${url}" != "null" ]; then
            log "Downloading and compressing file: $(basename $url)"
            export B64GZ_STRING=$(curl -s "${url}" |gzip |base64 -w0)
            yq -i '.write_files[env(COUNT)].content = env(B64GZ_STRING)' $USER_DATA_PATH
            yq -i '.write_files[env(COUNT)].encoding = "gz+b64"' $USER_DATA_PATH
            yq -i 'del(.write_files[env(COUNT)].url)' $USER_DATA_PATH
            check_size
        fi
        export COUNT=$(($COUNT + 1))
    done
}

# Check the size of the user-data file against ec2 16Kb limit
check_size(){
    log "Checking the size of the user-data file..."
    export SIZE=$(stat -c%s $USER_DATA_PATH)
    export REMAINDER=$((16000 - $SIZE))
    export FULL=$(echo "scale=2; 100-(($REMAINDER/16000)*100)" |bc -l)
    log "  - user-data file is $SIZE bytes - $FULL% of 16Kb limit."
    if [[ $SIZE -gt 16000 ]]; then
        echo "Warn: user-data file exceeds the 16KB limit"
    fi
}

# Validate user-data is properly formatted
validate(){
    log "Linting the user-data file..."
    CONFIG_VALID=$(cloud-init schema --config-file $USER_DATA_PATH)
    log "  - $CONFIG_VALID"
}

# Add wireguard configs from secrets
wireguard(){
    read -ra interfaces <<< $(yq '.wireguard.interfaces[].name' "${USER_DATA_PATH}" |xargs)
    export COUNT=0

    for interface in "${interfaces[@]}"; do
        if [ "${interface}" != "null" ]; then
            log "Adding wireguard interface ${interface}"
            IFS= read -rd '' output < <(/bin/cat "${interface}".conf)
            output=$output yq -i '.wireguard.interfaces[env(COUNT)].content = strenv(output)' $USER_DATA_PATH
        fi
        export COUNT=$(($COUNT + 1))
    done
}

# Generic logging method to return a timestamped string
log() {
    echo >&2 -e "[$(date +"%Y-%m-%d %H:%M:%S")] ${1-}" >> /tmp/log.txt
}

# kill on error
die() {
        local MSG=$1
        local CODE=${2-1}
        # Bash parameter expansion - default exit status 1.
        # See https://wiki.bash-hackers.org/syntax/pe#use_a_default_value
        log "${MSG}"
        exit "${CODE}"
}


# Main Application Loop
main(){

    # Check and validate inputs
    parse_params $@

    log "Starting Cloud-Init Optomizer"

    # Copy read-only file to an editable version
    cp $USER_DATA_SECRET_PATH $USER_DATA_PATH

    # Check the initial size of the cloud-init config
    check_size

    # Replace all $VAR definitions with matching ENV vars
    run_envsubst

    # Insert wireguard configurations into cloud-init file
    wireguard

    # Hash/encrypt password from secret or input
    admin_password

    # Download, compress, and encode files specified in write_files section
    download_files

    # Lint the resulting cloud-init file
    validate

    # Do a final size check of our modified config file
    check_size

    # Move the final file to the output directory
    #log "Optimized file saved to /output/user-data.yaml"
    #cp $USER_DATA_PATH /ouput/user-data.yaml
    cat $USER_DATA_PATH
}

main $@
