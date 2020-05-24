#!/usr/bin/bash

SECRET_FILE="/root/cryptroot.bin"
POLICY_DIGEST_FILE="/tmp/policy.digest"
PRIMARY_CTX_FILE="/tmp/primary.context"
OBJ_PUB_FILE="/tmp/obj.pub"
OBJ_KEY_FILE="/tmp/obj.key"
LOAD_CTX_FILE="/tmp/load.context"
OBJ_ATTR="noda|adminwithpolicy|fixedparent|fixedtpm"
TPM_HANDLE="0x81000000"

PCR_POLICY="sha1:0,2,4,7"

QUIET_FLAG="--quiet"

TMP_FILES=( \
    "$POLICY_DIGEST_FILE" \
    "$PRIMARY_CTX_FILE" \
    "$OBJ_PUB_FILE" \
    "$OBJ_KEY_FILE" \
    "$LOAD_CTX_FILE" \
)


function check_object() {
    if tpm2_readpublic $QUIET_FLAG -c "$TPM_HANDLE"; then
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
    if tpm2_unseal $QUIET_FLAG -c "$TPM_HANDLE" -p "pcr:$PCR_POLICY" > /dev/null; then
        return 0
    fi
    return 1
}

function seal_tpm() {
    echo "Creating new policy..."
    tpm2_createpolicy $QUIET_FLAG --policy-pcr -l "$PCR_POLICY" \
        -L "$POLICY_DIGEST_FILE"

    echo "Creating new primary key..."
    tpm2_createprimary $QUIET_FLAG -C e -g sha1 -G rsa \
        -c "$PRIMARY_CTX_FILE"

    echo "Creating new child key..."
    tpm2_create $QUIET_FLAG -g sha256 -u "$OBJ_PUB_FILE" \
        -r "$OBJ_KEY_FILE" -C "$PRIMARY_CTX_FILE" -L "$POLICY_DIGEST_FILE" \
        -a "$OBJ_ATTR" -i "$SECRET_FILE"

    echo "Loading secret..."
    tpm2_load $QUIET_FLAG -C "$PRIMARY_CTX_FILE" \
        -u "$OBJ_PUB_FILE" -r "$OBJ_KEY_FILE" -c "$LOAD_CTX_FILE"

    echo "Persisting secret..."
    tpm2_evictcontrol $QUIET_FLAG -C o -c "$LOAD_CTX_FILE" \
        "$TPM_HANDLE"
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
