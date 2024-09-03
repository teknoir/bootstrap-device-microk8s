info "Install TOE Helm Values"
$SUDO cat << EOF > ${CONFIG_PATH}/values.yaml
toe:
  deviceID: ###_DEVICE_ID###
  teamSpace: ###_IOT_REGISTRY###
  pullSecret: ###_AR_DOCKER_SECRET###
  gcpProject: ###_GCP_PROJECT###
  configHostPath: ${CONFIG_PATH}
  defaultNamespace: "teknoir"
EOF
$SUDO sudo chown 65532:root ${CONFIG_PATH}/values.yaml
$SUDO sudo chmod 440 ${CONFIG_PATH}/values.yaml
