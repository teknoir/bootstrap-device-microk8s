warn "To enable tunneling, the user ${_FIRST_USER_NAME} has to be created."

on_sudo() {
  $SUDO sh -- "$@"
}

setup_user() {
  $SUDO mkdir -p /home/${_FIRST_USER_NAME}
  if ! id -u ${_FIRST_USER_NAME} >/dev/null 2>&1; then
    $SUDO adduser --disabled-password --gecos "" ${_FIRST_USER_NAME}
  fi

  if command -v chpasswd &> /dev/null; then
    echo "${_FIRST_USER_NAME}:${_FIRST_USER_PASS}" | $SUDO chpasswd
  elif command -v passwd &> /dev/null; then
    echo -e "${_FIRST_USER_PASS}\n${_FIRST_USER_PASS}" | passwd ${_FIRST_USER_NAME}
  elif command -v usermod &> /dev/null && command -v openssl &> /dev/null; then
    usermod --password $(openssl passwd -1 ${_FIRST_USER_PASS}) ${_FIRST_USER_NAME}
  else
      warn "Could not set password for user ${_FIRST_USER_NAME}"
      info "Skipping tunneling setup"
      exit
  fi

  on_sudo << EOF
mkdir -p /home/${_FIRST_USER_NAME}/.ssh
cp ${CONFIG_PATH}/rsa_private.pem /home/${_FIRST_USER_NAME}/.ssh/id_rsa
ssh-keygen -y -f ${CONFIG_PATH}/rsa_private.pem > /home/${_FIRST_USER_NAME}/.ssh/id_rsa.pub
cat /home/${_FIRST_USER_NAME}/.ssh/id_rsa.pub > /home/${_FIRST_USER_NAME}/.ssh/authorized_keys
if [ -z ${_FIRST_USER_KEY+x} ] || [ "${_FIRST_USER_KEY}" = "" ]; then
  echo "[INFO] _FIRST_USER_KEY is not set, will continue with only password auth";
else
  echo "${_FIRST_USER_KEY}" >> /home/${_FIRST_USER_NAME}/.ssh/authorized_keys
fi
chmod 600 /home/${_FIRST_USER_NAME}/.ssh/*
chmod 744 /home/${_FIRST_USER_NAME}/.ssh
chown -R ${_FIRST_USER_NAME}:${_FIRST_USER_NAME} /home/${_FIRST_USER_NAME}

# Add root user to users and sudo groups
if [ -e /etc/group ]; then
    sed -i "/^users:/s/\(.*\)/\1,${_FIRST_USER_NAME}/;s/:,/:/" /etc/group
    sed -i "/^sudo:/s/\(.*\)/\1,${_FIRST_USER_NAME}/;s/:,/:/" /etc/group
fi
EOF
}

CREATE_USER=${CREATE_USER:-ask}
if [ ${OS_BUILD} ] || [ "${CREATE_USER}" = true ]; then
  setup_user
else
  if id -u ${_FIRST_USER_NAME} >/dev/null 2>&1; then
    warn "The user ${_FIRST_USER_NAME} already exist! This operation will change the password and OVERWRITE ssh keys for this users."
  fi
  warn "Do you want to add \"${_FIRST_USER_NAME}\" as a user and enable tunneling? [yY]"
  read REPLY

  case ${REPLY} in
    [Yy]* )
      setup_user
      ;;
    * )
      info "Skipping tunneling setup"
      ;;
  esac
fi
