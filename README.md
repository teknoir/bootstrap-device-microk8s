# Teknoir MicroK8s Device Bootstrapping
This is very much a repo in BETA.

## Installation
The following steps are required to bootstrap a device with the Teknoir MicroK8s configuration.
```bash
./build_local.sh -c gke_teknoir_us-central1-c_teknoir-cluster -n teknoir-ai -d trainer-2x-rtx3090
```
This generates a script named by the device name, in this case `bootstrap_trainer-2x-rtx3090.sh` that can be run on the device to install the Teknoir MicroK8s configuration.
The generated script will only install the TOE agent config, and will not install MicroK8s or any other dependencies(see MicroK8s Installation below).

## MicroK8s Installation
The following steps are required to install the addon manually. Please note that the channel can be changed to the desired version.
```bash
snap install microk8s --classic --channel=1.31
microk8s addons repo add teknoir https://github.com/teknoir/microk8s-teknoir-addons
microk8s enable toe
microk8s enable metrics-server
```

## GPU Support
If the device has a NVIDIA GPU, the GPU addon can be enabled. The GPU addon requires the NVIDIA container toolkit to be installed on the host system.
```bash
apt-get install nvidia-container-runtime
microk8s enable gpu
kubectl set env -n gpu-operator-resources ds nvidia-container-toolkit-daemonset -c nvidia-validator DISABLE_DEV_CHAR_SYMLINK_CREATION=true
kubectl set env -n gpu-operator-resources ds nvidia-operator-validator -c nvidia-validator DISABLE_DEV_CHAR_SYMLINK_CREATION=true
```

# DUMP
Put the generated file here: /var/snap/microk8s/common/.microk8s.yaml