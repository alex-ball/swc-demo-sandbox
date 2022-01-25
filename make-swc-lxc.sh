#!/usr/bin/env bash

if lxd --help > /dev/null
then
    echo "Creating Linux container for SWC teaching..."
    lxc launch -p default ubuntu:21.10 swc
    lxc exec swc -- cloud-init status --wait
else
    echo "Please install LXD first, e.g. `snap install lxd`."
    exit 1
fi

echo "Populating home folder..."
lxc exec --user 1000 swc -- mkdir /home/ubuntu/{Applications,Desktop,Documents,Downloads,Library,Movies,Music,Pictures,Public}

echo "Setting up tmux package manager..."
lxc exec --user 1000 swc -- mkdir -p /home/ubuntu/.tmux/plugins/
lxc exec --user 1000 swc -- git clone https://github.com/tmux-plugins/tpm /home/ubuntu/.tmux/plugins/tpm

echo "Installing useful packages..."
lxc exec swc -- apt update
lxc exec swc -- apt install xsel unzip

echo "Setting up tmux..."
lxc file push tmux.conf swc/home/ubuntu/.tmux.conf
lxc exec --user 1000 swc -- tmux new-session -d -s "setup" "tmux source /home/ubuntu/.tmux.conf; /home/ubuntu/.tmux/plugins/tpm/bin/install_plugins"

echo "Copying scripts..."
lxc exec --user 1000 swc -- mkdir -p /home/ubuntu/.local/bin/
lxc file push demo-terminal.sh setup-*.sh swc/home/ubuntu/.local/bin/

echo "Creating swc/clean snapshot..."
lxc snapshot swc clean

echo "Creating alias..."
if [[ $(lxc alias list | grep "| usercmd |") ]]
then
    echo Replacing alias $(lxc alias list | grep "| usercmd |")
    lxc alias remove usercmd
fi
lxc alias add usercmd "exec @ARGS@ --user 1000 --group 1000 --env HOME=/home/ubuntu -- /bin/bash --login -c \$CMD"

echo "Done!"
