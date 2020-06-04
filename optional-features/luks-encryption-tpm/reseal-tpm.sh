#!/usr/bin/bash

readonly SECRET_BIN="/root/cryptroot.bin"
readonly TMP_POLICY_DIGEST="/tmp/policy.digest"
readonly TMP_PRIMARY_CTX="/tmp/primary.context"
readonly TMP_OBJ_PUB="/tmp/obj.pub"
readonly TMP_OBJ_KEY="/tmp/obj.key"
readonly TMP_LOAD_CTX="/tmp/load.context"

readonly OBJ_ATTR="noda|adminwithpolicy|fixedparent|fixedtpm"
readonly TPM_HANDLE="0x81000000"
readonly PCR_POLICY="sha1:0,2,4,7"
readonly QUIET_FLAG=("--quiet")

readonly TMP_FILES=( \
    "$TMP_POLICY_DIGEST" \
    "$TMP_PRIMARY_CTX" \
    "$TMP_OBJ_PUB" \
    "$TMP_OBJ_KEY" \
    "$TMP_LOAD_CTX" \
)



function check_object() {
    if tpm2_readpublic ${QUIET_FLAG[@]} -c "$TPM_HANDLE"; then
        return 0
    fi
    return 1
}

function clear_tpm_handle() {
    if check_object; then
        echo "TPM object found at handle $TPM_HANDLE"
        echo "Evicting object at $TPM_HANDLE..."
        tpm2_evictcontrol -C o -c "$TPM_HANDLE"
    fi
}

function try_unseal() {
    if tpm2_unseal ${QUIET_FLAG[@]} -c "$TPM_HANDLE" -p "pcr:$PCR_POLICY" > /dev/null; then
        return 0
    fi
    return 1
}

function seal_tpm() {
    echo "Creating new policy..."
    tpm2_createpolicy ${QUIET_FLAG[@]} --policy-pcr -l "$PCR_POLICY" \
        -L "$TMP_POLICY_DIGEST"

    echo "Creating new primary key..."
    tpm2_createprimary ${QUIET_FLAG[@]} -C e -g sha1 -G rsa \
        -c "$TMP_PRIMARY_CTX"

    echo "Creating new child key..."
    tpm2_create ${QUIET_FLAG[@]} -g sha256 -u "$TMP_OBJ_PUB" \
        -r "$TMP_OBJ_KEY" -C "$TMP_PRIMARY_CTX" -L "$TMP_POLICY_DIGEST" \
        -a "$OBJ_ATTR" -i "$SECRET_BIN"

    echo "Loading secret..."
    tpm2_load ${QUIET_FLAG[@]} -C "$TMP_PRIMARY_CTX" -u "$TMP_OBJ_PUB" \
        -r "$TMP_OBJ_KEY" -c "$TMP_LOAD_CTX"

    echo "Persisting secret..."
    tpm2_evictcontrol ${QUIET_FLAG[@]} -C o -c "$TMP_LOAD_CTX" "$TPM_HANDLE"
}

function cleanup() {
    echo "Cleaning up temp files..."
    rm -f "${TMP_FILES[@]}"
}


if [[ "$EUID" -ne 0 ]]
  then echo "Please run as root"
  exit
fi

if ! try_unseal; then
    echo "TPM could not be unsealed"
    echo "Resealing TPM with new PCRs..."

    clear_tpm_handle

    seal_tpm

    cleanup

    echo "Done"
else
    echo "TPM is intact"
    echo "No further action is needed"
fi
