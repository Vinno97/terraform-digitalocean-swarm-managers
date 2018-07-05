data "template_file" "provision_first_manager" {
  template = "${file("${path.module}/scripts/provision-first-manager.sh")}"

  vars {
    docker_cmd = "${var.docker_cmd}"

    # availability = "${var.availability}"
  }
}

data "template_file" "provision_manager" {
  template = "${file("${path.module}/scripts/provision-manager.sh")}"

  vars {
    docker_cmd = "${var.docker_cmd}"

    # availability = "${var.availability}"
  }
}

resource "vultr_instance" "manager" {
  count     = "${var.total_instances}"
  name      = "${var.name}-manager-${count.index}"
  hostname  = "${var.name}-manager-${count.index}"
  region_id = "${data.vultr_region.selected_region.id}"
  plan_id   = "${data.vultr_plan.selected_plan.id}"
  os_id     = "${data.vultr_os.selected_os.id}"
  name      = "${var.name}-manager-${count.index}"
  tag       = "${var.tag}"

  # ssh_key_ids = ["${data.vultr_ssh_key.selected_keys.*.id}"]
  ssh_key_ids = ["${data.vultr_ssh_key.selected_keys.*.id}"]

  # ssh_key_ids = "[${data.vultr_ssh_key.selected_keys.id}]"


  #   firewall_group_id  = "${vultr_firewall_group.cluster.id}"
  # user_data          = "${data.ct_config.node_ipxe_ignition.rendered}"
  # startup_script_id = "${vultr_startup_script.ipxe.id}"

  private_networking = true

  # resource "digitalocean_droplet" "manager" {
  #   ssh_keys           = "${var.ssh_keys}"
  #   image              = "${var.image}"
  #   region             = "${var.region}"
  #   size               = "${var.size}"
  #   private_networking = true
  #   backups            = "${var.backups}"
  #   ipv6               = false
  #   tags               = ["${var.tags}"]
  #   user_data          = "${var.user_data}"
  #   count              = "${var.total_instances}"
  #   name               = "${format("%s-%02d.%s.%s", var.name, count.index + 1, var.region, var.domain)}"

  connection {
    type        = "ssh"
    user        = "${var.provision_user}"
    private_key = "${file("${var.provision_ssh_key}")}"
    timeout     = "10m"
  }
  provisioner "file" {
    content     = "${data.template_file.provision_first_manager.rendered}"
    destination = "/tmp/provision-first-manager.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provision-first-manager.sh",
      "if [ ${count.index} -eq 0 ]; then /tmp/provision-first-manager.sh ${self.ipv4_address}; fi",
    ]
  }
  provisioner "remote-exec" {
    when = "destroy"

    inline = [
      "timeout 25 docker swarm leave --force",
    ]

    on_failure = "continue"
  }
}

# Optionally expose Docker API using certificates
resource "null_resource" "manager_api_access" {
  count = "${var.remote_api_key == "" || var.remote_api_certificate == "" || var.remote_api_ca == "" ? 0 : var.total_instances}"

  triggers {
    cluster_instance_ids = "${join(",", vultr_instance.manager.*.id)}"
    certificate          = "${md5(file("${var.remote_api_certificate}"))}"
  }

  connection {
    host        = "${element(vultr_instance.manager.*.ipv4_address, count.index)}"
    type        = "ssh"
    user        = "${var.provision_user}"
    private_key = "${file("${var.provision_ssh_key}")}"
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p ~/.docker",
    ]
  }

  provisioner "file" {
    source      = "${var.remote_api_ca}"
    destination = "~/.docker/ca.pem"
  }

  provisioner "file" {
    source      = "${var.remote_api_certificate}"
    destination = "~/.docker/server-cert.pem"
  }

  provisioner "file" {
    source      = "${var.remote_api_key}"
    destination = "~/.docker/server-key.pem"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/certs/default.sh"
    destination = "~/.docker/install_certificates.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ~/.docker/install_certificates.sh",
      "~/.docker/install_certificates.sh",
    ]
  }
}

data "external" "swarm_tokens" {
  program    = ["bash", "${path.module}/scripts/get-swarm-join-tokens.sh"]
  depends_on = ["null_resource.manager_api_access"]

  query = {
    host        = "${element(vultr_instance.manager.*.ipv4_address, 0)}"
    user        = "${var.provision_user}"
    private_key = "${var.provision_ssh_key}"
  }
}

resource "null_resource" "bootstrap" {
  count      = "${var.total_instances}"
  depends_on = ["null_resource.manager_api_access"]

  triggers {
    cluster_instance_ids = "${join(",", vultr_instance.manager.*.id)}"
  }

  connection {
    host        = "${element(vultr_instance.manager.*.ipv4_address, count.index)}"
    type        = "ssh"
    user        = "${var.provision_user}"
    private_key = "${file("${var.provision_ssh_key}")}"
    timeout     = "2m"
  }

  provisioner "file" {
    content     = "${data.template_file.provision_manager.rendered}"
    destination = "/tmp/provision-manager.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provision-manager.sh",
      "/tmp/provision-manager.sh ${vultr_instance.manager.0.ipv4_address} ${lookup(data.external.swarm_tokens.result, "manager")}",
    ]
  }
}

resource "vultr_dns_record" "api" {
  count  = "${var.total_instances}"
  domain = "${var.domain}"
  name   = "${var.name}"
  type   = "A"
  data   = "${element(vultr_instance.manager.*.ipv4_address, count.index)}"
  ttl    = 300
}
