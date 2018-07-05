# Terraform - Vultr Docker Swarm mode managers

Terraform module to provision and bootstrap a Docker Swarm mode cluster with multiple managers on DigitalOcean.

> This module is a port of [terraform-digitalocean-swarm-managers]() by thojkooi. Most functionalities are ported from DigitalOcean to Vultr, though there might be cases that do not yet work. If you find any cases that are not yet supported, please do not hesitate to submit an issue.

<!-- TODO: Migrate to own CI pipeline  -->
<!-- [![CircleCI](https://circleci.com/gh/thojkooi/terraform-digitalocean-swarm-managers/tree/master.svg?style=svg)](https://circleci.com/gh/thojkooi/terraform-digitalocean-swarm-managers/tree/master) -->

- [Requirements](#requirements)
- [Usage](#usage)
- [Examples](#examples)

## Requirements

- Terraform >= 0.11.7
- Vultr account / API token with write access
- SSH Keys added to your Vultr account
- [jq](https://github.com/stedolan/jq)

## Usage

```hcl
module "swarm-cluster" {
  source          = "github.com/vinno97/terraform-vultr-swarm-managers?ref=v0.1.0"
  domain          = "example.com"
  total_instances = 3
  ssh_keys        = [key1, key2, ...]
  providers {}
}
```

### SSH Key

Terraform uses an SSH key to connect to the created droplets in order to issue `docker swarm join` commands. By default this uses `~/.ssh/id_rsa`. If you wish to use a different key, you can modify this using the variable `provision_ssh_key`. You also need to ensure the public key is added to your Vultr account and it's ID is listed in the `ssh_keys` list.

### Exposing the Docker API

> This feature is untested for this repo. The code is the same as [terraform-digitalocean-swarm-managers]() by thojkooi.


You can expose the Docker API to interact with the cluster remotely. This is done by providing a certificate and private key. See the [Docker TLS example](https://github.com/thojkooi/terraform-digitalocean-swarm-managers/tree/master/examples/remote-api-tls).

```hcl
module "swarm_mode_cluster" {
  source          = "github.com/vinno97/terraform-vultr-swarm-managers?ref=v0.1.0"

  domain          = "example.com"
  total_instances = 3
  ssh_keys        = [key1, key2, ...]

  remote_api_ca          = "${path.module}/certs/ca.pem"
  remote_api_certificate = "${path.module}/certs/server.pem"
  remote_api_key         = "${path.module}/certs/server-key.pem"

  plan = "1024 MB RAM,25 GB SSD"
  providers = {}
}
```

### Notes

This module does not set up a firewall or modifies any other security settings. Please configure this by providing user data for the manager nodes. Also set up firewall rules on Vultr for the cluster, to ensure only cluster members can access the internal Swarm ports.

## Examples


For examples, see the [examples directory](https://github.com/thojkooi/terraform-digitalocean-swarm-managers/tree/master/examples).
> Note: These examples are not yet properly ported from thojkooi's [terraform-digitalocean-swarm-managers]().

## Swarm set-up

First a single Swarm mode manager is provisioned. This is the leader node. If you have additional manager nodes, these will be provisioned after this step. Once the manager nodes have been provisioned, Terraform will initialize the Swarm on the first manager node and retrieve the join tokens. It will then have all the managers join the cluster.

If the cluster is already up and running, Terraform will check with the first leader node to refresh the join tokens. It will join any additional manager nodes that are provisioned automagically to the Swarm.
