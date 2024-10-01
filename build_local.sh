#!/bin/bash
set -e

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -c|--context)
    export CONTEXT="$2"
    shift # past argument
    shift # past value
    ;;
    -n|--namespace)
    export NAMESPACE="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--device)
    export DEVICE="$2"
    shift # past argument
    shift # past value
    ;;
    -s|--skip-upload)
    export SKIP_UPLOAD=1
    shift # past argument
    ;;
    -h|--help|*)
    echo "$0 -c(--context) <kubectl-context> -n(--namespace) <namespace> -d(--device) <device-name>"
    exit 0
    ;;
esac
done

export ZONE=us-central1-c
export _GCP_PROJECT=$(if [ "$CONTEXT" == "gke_teknoir-poc_us-central1-c_teknoir-dev-cluster" ]; then echo "teknoir-poc"; else echo "teknoir"; fi)
export _DOMAIN=$([ "$_GCP_PROJECT" == 'teknoir' ] && echo "teknoir.cloud" || echo "teknoir.info")
export _IOT_REGISTRY=${NAMESPACE}
export _DEVICE_ID=${DEVICE}

gcloud config set project ${_GCP_PROJECT}
gcloud config set compute/zone ${ZONE}

export DEVICE_MANIFEST="$(kubectl --context $CONTEXT -n $NAMESPACE get device.teknoir.org $DEVICE -o yaml)"
if [ -z ${DEVICE_MANIFEST+x} ] || [ "${DEVICE_MANIFEST}" = "" ]; then
  echo "DEVICE_MANIFEST not found"
  exit 1
fi
export _RSA_PRIVATE="$(echo "$DEVICE_MANIFEST" | yq eval .spec.keys.data.rsa_private - | base64 -d)"
export _FIRST_USER_NAME="$(echo "$DEVICE_MANIFEST" | yq eval .spec.keys.data.username - | base64 -d)"
export _FIRST_USER_PASS="$(echo "$DEVICE_MANIFEST" | yq eval .spec.keys.data.userpassword - | base64 -d)"
export _FIRST_USER_KEY="$(echo "$DEVICE_MANIFEST" | yq eval .spec.keys.data.publicsshkey - | base64 -d)"

export AR_SECRET="$(kubectl --context $CONTEXT -n $NAMESPACE get secret artifact-registry-secret -o yaml)"
export _AR_DOCKER_SECRET="$(echo "${AR_SECRET}" | yq eval '.data[".dockerconfigjson"]' -)"

export _BOOTSTRAP_FILE="bootstrap_${_DEVICE_ID}.sh"

echo "_GCP_PROJECT   = ${_GCP_PROJECT}"
echo "_DOMAIN        = ${_DOMAIN}"
echo "_IOT_REGISTRY  = ${_IOT_REGISTRY}"
echo "_DEVICE_ID     = ${_DEVICE_ID}"
echo "_BOOTSTRAP_FILE= ${_BOOTSTRAP_FILE}"

TEMPLATES_PATH=$(realpath ./templates)
source build_bootstrap_script.sh

# Truncate the bootstrap file to ensure it is empty
: > ${_BOOTSTRAP_FILE}

BOOTSTRAP_FILE=${_BOOTSTRAP_FILE}
build_bootstrap_script ${BOOTSTRAP_FILE} ${TEMPLATES_PATH}

replace_placeholder_with_variable() {
  local input_file=$1
  local placeholder=$2
  local variable_content=$3

  sed -i -e "/${placeholder}/{
      r /dev/stdin
      d
  }" ${input_file} <<< "${variable_content}"
}

sed -i '' "s/###_DEVICE_ID###/${_DEVICE_ID}/g" "${BOOTSTRAP_FILE}"
sed -i '' "s/###_IOT_REGISTRY###/${_IOT_REGISTRY}/g" "${BOOTSTRAP_FILE}"
sed -i '' "s/###_AR_DOCKER_SECRET###/${_AR_DOCKER_SECRET}/g" ${BOOTSTRAP_FILE}
sed -i '' "s/###_GCP_PROJECT###/${_GCP_PROJECT}/g" ${BOOTSTRAP_FILE}
sed -i '' "s/###_FIRST_USER_NAME###/${_FIRST_USER_NAME}/g" ${BOOTSTRAP_FILE}
sed -i '' "s/###_FIRST_USER_PASS###/${_FIRST_USER_PASS}/g" ${BOOTSTRAP_FILE}
sed -i '' "s/###_FIRST_USER_KEY###/${_FIRST_USER_KEY}/g" ${BOOTSTRAP_FILE}

replace_placeholder_with_variable ${BOOTSTRAP_FILE} "###_RSA_PRIVATE###" "${_RSA_PRIVATE}"


#if [ -n "${SKIP_UPLOAD}" ]; then
#  echo "Skipping upload of drop-in script to secure bucket"
#  exit 0
#fi

#BUCKET="${NAMESPACE}.${_DOMAIN}"
#gsutil cp ${BOOTSTRAP_FILE} gs://${BUCKET}/downloads/${DEVICE}/${BOOTSTRAP_FILE}
#SIGNED_URL=$(gsutil -q -i kubeflow-admin@${_GCP_PROJECT}.iam.gserviceaccount.com signurl -d 12h -u gs://${BUCKET}/downloads/${DEVICE}/${BOOTSTRAP_FILE})
#
#echo "Drop-in script for device generated and uploaded to secure bucket!"
#echo "Run the following command on the device:"
#echo "bash <(curl -LsS \"https${SIGNED_URL#*https}\")"
