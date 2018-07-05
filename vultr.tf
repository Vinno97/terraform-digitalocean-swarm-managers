provider "vultr" {
  api_key = "${var.vultr_key}"
}

data "vultr_region" "selected_region" {
  filter {
    name   = "name"
    values = ["${var.region}"]
  }
}

data "vultr_os" "selected_os" {
  filter {
    name   = "family"
    values = ["${var.os}"]
  }
}

data "vultr_plan" "selected_plan" {
  name_regex = "${var.plan}"
}

data "vultr_ssh_key" "selected_keys" {
  count = "${length(var.ssh_keys)}"

  filter {
    name   = "name"
    values = ["${element(var.ssh_keys, count.index)}"]
  }
}
