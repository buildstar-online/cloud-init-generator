#!/bin/bash

set -e

export KUBECONFIG=/kube/config
export USER_DATA_PATH=""
export NETWORK_DATA_PATH=""
export NETWORK_DATA_PRESENT="false"
export QUIET="false"

# Parse and validate user inputs.
parse_params() {
        while :; do
                case "${1-}" in
                -h | --help) usage ;;
                -v | --verbose) set -x ;;
                -q | --quiet) export QUIET="true" ;;
                -u | --userdata)
                        export USER_DATA_PATH="${2-}"
                        shift
                        ;;
                -n | --networkdata)
                        export NETWORK_DATA_PATH="${2-}"
                        shift
                        ;;
                -s | --secretname)
                        export SECRET_NAME="${2-}"
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

-q, --quiet             Only print final userdata

-u, --userdata          Path to cloud-init user-data file (required)

-n, --networkdata       Path to cloud-init networkdata file (optional)

EOF
        exit
}

# Find if the networkdata file exists
detect_networkdata(){
    if [[ ! -z "$NETWORK_DATA_PATH" ]]; then
        if [ -f "$NETWORK_DATA_PATH" ]; then
            export NETWORK_DATA_PRESENT="true"
        fi
    fi
}

secret_exists(){
    export SECRET_EXISTS=$(kubectl get secret ${SECRET_NAME} -o yaml |grep -o "${SECRET_NAME}" |wc -l)

    if [ "${SECRET_EXISTS}" -gt 0 ]; then
        log "Kubernetes secret ${SECRET_NAME} exists and will be replaced"
        kubectl patch secret ${SECRET_NAME} -p '{"metadata":{"finalizers":null}}' --type=merge
        kubectl delete secret ${SECRET_NAME}
    fi
}

cretae_userdata_secret(){
    if [ "$NETWORK_DATA_PRESENT" == "true" ]; then
        log "Creating kubernetes secret ${SECRET_NAME} from ${USER_DATA_PATH} & ${NETWORK_DATA_PATH}"
        kubectl create secret generic ${SECRET_NAME} \
            --from-file=userdata="${USER_DATA_PATH}" \
            --from-file=networkdata="${NETWORK_DATA_PATH}"
    else
        log "Creating kubernetes secret ${SECRET_NAME} from ${USER_DATA_PATH}"
        kubectl create secret generic ${SECRET_NAME} --from-file=userdata="${USER_DATA_PATH}"
    fi
    annotate_userdata_secret
}

annotate_userdata_secret(){
    log "Adding argocd tracking annotation."
    kubectl annotate --overwrite secret ${SECRET_NAME} \
        argocd.argoproj.io/tracking-id="${ARGOCD_APP_NAME}:v1/Secret:${NAMESPACE}/${SECRET_NAME}"

    log "Adding argocd sync options."
    kubectl annotate --overwrite secret ${SECRET_NAME} \
        argocd.argoproj.io/sync-options="Prune=false,Delete=false"

    log "Adding argocd comparison options."
    kubectl annotate --overwrite secret ${SECRET_NAME} \
        argocd.argoproj.io/compare-options="IgnoreExtraneous"
}

# Generic logging method to return a timestamped string
log() {
    if [ "${QUIET}" == "true" ]; then
        echo >&2 -e "{ \"date\": \"$(date +"%Y-%m-%d %H:%M:%S")\", \"message\": \"${1-}\"}" >> /tmp/log.txt
    fi

    if [ "${QUIET}" == "false" ]; then
        echo >&2 -e "{\"date\": \"$(date +"%Y-%m-%d %H:%M:%S")\", \"message\": \"${1-}\"}"
    fi
}

main(){
    parse_params $@
    secret_exists
    if [[ ! -z "$USER_DATA_PATH" ]]; then
        detect_networkdata
        cretae_userdata_secret
    fi
}

main $@
