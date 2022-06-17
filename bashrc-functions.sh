#!/bin/bash

# To use, type ansible-play followed by 2+ arguments: playbook filename without extension, environment to play it against, and any ansible-playbook arguments to add
# i.e.
# ansible-play myplaybook.yaml dev -e "myvar=superduper" -vvv
ansible-play() {
    docker run -it \
    --add-host host.docker.internal:host-gateway \
    --env-file=$HOME/.env \
    -e GIT_BRANCH=$(git branch --show-current) \
    -v $HOME/.ssh:/opt/app/src/.ssh \
    -v $HOME/.kube:/opt/app/src/.kube \
    -v $HOME/.config:/opt/app/src/.config \
    -v $PWD:/opt/app/src/ansible/ \
    -w /opt/app/src/ansible \
    cmdr:latest \
    ansible-playbook -i environments/$2/ $1 ${@:3} --vault-password-file=~/.vault_pass
}

# To use, type ansible-requirements in a directory that has a requirements.yaml file
# i.e.
# ansible-requirements
ansible-requirements() {
    docker run -it \
    --add-host host.docker.internal:host-gateway \
    --env-file=$HOME/.env \
    -v $HOME/.ssh:/opt/app/src/.ssh \
    -v $HOME/.kube:/opt/app/src/.kube \
    -v $HOME/.config:/opt/app/src/.config \
    -v $PWD:/opt/app/src/ansible/ \
    -w /opt/app/src/ansible \
    cmdr:latest \
    ansible-galaxy install -r requirements.yaml
}

# To use, type ansible-debug in an ansible project to enter a shell with all the dependencies installed
# i.e.
# ansible-debug
ansible-debug() {
    docker run -it --rm \
    --add-host host.docker.internal:host-gateway \
    --env-file=$HOME/.env \
    -e GIT_BRANCH=$(git branch --show-current) \
    -v $HOME/.ssh:/opt/app/src/.ssh \
    -v $HOME/.kube:/opt/app/src/.kube \
    -v $HOME/.config:/opt/app/src/.config \
    -v $PWD:/opt/app/src/ansible/ \
    -w /opt/app/src/ansible \
    cmdr:latest /bin/bash
}
