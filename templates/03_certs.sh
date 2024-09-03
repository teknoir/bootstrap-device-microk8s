info "Install device specific keys"
export CONFIG_PATH=/etc/teknoir
$SUDO mkdir -p ${CONFIG_PATH}
$SUDO mkdir -p /toe_conf && $SUDO rm -rf /toe_conf && $SUDO ln -s ${CONFIG_PATH}/ /toe_conf # For backward compatibility
download ${CONFIG_PATH}/roots.pem https://pki.goog/roots.pem
$SUDO chmod 440 ${CONFIG_PATH}/roots.pem
$SUDO chown 65532:root ${CONFIG_PATH}/roots.pem
$SUDO cat << EOF > ${CONFIG_PATH}/rsa_private.pem
###_RSA_PRIVATE###
EOF
$SUDO chmod 440 ${CONFIG_PATH}/rsa_private.pem
$SUDO chown 65532:root ${CONFIG_PATH}/rsa_private.pem
