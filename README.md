# cmdr
DevOps-y toolkit for ansible, terraform, kubectl, and other cloud CLI. Ansible aspects inspired by https://hub.docker.com/r/geerlingguy/docker-ubuntu1604-ansible/

The purpose of this docker image is two-fold:
1. For development reasons, having one grouped set of dependencies reduces the 'works on my machine' issues down dramatically. Additionally, pre-loading all dependencies can be very helpful, it can almost be treated as a binary. Upgrading is also exceptionally easy if you have access to a docker registry. You pull the latest version and use it.
2. Useful for for continuous integration pipeline, more portable

## To Build:
from this project directory:
```bash
docker build --build-arg user_id=$UID -t cmdr:latest .
```
or if you want to supply your own pypi registry
```bash
docker build --build-arg user_id=$UID --build-arg pypi_registry=https://artifactory.local/repository/pypi --build-arg pypi_host=artifactory.local -t cmdr:latest .
```

## Prereqs:
from the ansible project directory:
```bash
docker run \
    --env-file=</path-to-env-file/>.env \
    -v $HOME/.ssh:/opt/app/src/.ssh \
    -v $HOME/.kube:/opt/app/src/.kube \
    -v $HOME/.config:/opt/app/src/.config \
    -v $PWD:/opt/app/src/ansible \
    -w /opt/app/src/ansible \
    cmdr:latest \
    ansible-galaxy install -r requirements.yaml
```

## Playbook:
from the ansible project directory:
```bash
docker run -it \
    --add-host host.docker.internal:host-gateway \
    --env-file=</path-to-env-file/>.env \
    -v $HOME/.ssh:/opt/app/src/.ssh \
    -v $HOME/.kube:/opt/app/src/.kube \
    -v $HOME/.config:/opt/app/src/.config \
    -v $PWD:/opt/app/src/ansible \
    -w /opt/app/src/ansible \
    cmdr:latest \
    ansible-playbook -i environments/dev/ playbook.yaml --vault-password-file=~/.vault_pass
```
See `.env.example` for supported Environment variables.

See `examples/` for included prereq role invocations / usage 

See bashrc-functions.sh for functional versions of these commands that can be copied into your .bashrc or your .zshrc

To utilize the host.docker.internal and 2375 tcp port, follow instructions at https://gist.github.com/styblope/dc55e0ad2a9848f2cc3307d4819d819f

The above will allow you do use the docker host that this image runs on to run other containers. 

NOTE: it's less secure than the unix socket so use firewalls as appropriate:

```yaml
- name: Create container
  community.docker.docker_container:
    name: my-container
    image: busybox:latest
    command: "echo $HOST"
    docker_host: "tcp://host.docker.internal:2375"
```
