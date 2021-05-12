resource "vsphere_virtual_machine" "virtual_machine_windows" {
  count            = "${var.template_os_family == "windows" ? var.vm_count : 0}"
  name             = "${var.vm_name_prefix}${count.index}"
  resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
  datastore_id     = "${data.vsphere_datastore.ds.id}"
  firmware         = "${var.firmware}"
  folder           = "${var.folder}"
  num_cpus         = "${var.num_cpus}"
  memory           = "${var.memory}"
  guest_id         = "${data.vsphere_virtual_machine.template.guest_id}"
  scsi_type        = "${data.vsphere_virtual_machine.template.scsi_type}"

  wait_for_guest_net_timeout = "${var.wait_for_guest_net_timeout}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "disk0"
    size             = "${var.disk_size != "" ? var.disk_size : data.vsphere_virtual_machine.template.disks.0.size}"
    thin_provisioned = "${var.linked_clone == "true" ? data.vsphere_virtual_machine.template.disks.0.thin_provisioned : true}"
    eagerly_scrub    = "${var.linked_clone == "true" ? data.vsphere_virtual_machine.template.disks.0.eagerly_scrub: false}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
    linked_clone  = "${var.linked_clone}"
    timeout       = "${var.timeout}"

    customize {
      timeout = "${var.timeout}"
      windows_options {
        computer_name  = "${var.vm_name_prefix}${count.index}"
        admin_password = "${var.admin_password}"
        workgroup      = "${var.workgroup}"
        time_zone      = "${var.time_zone != "" ? var.time_zone : "85"}"
        /*
        join_domain = "cloud.local"
	      domain_admin_user = "administrator@cloud.local"
	      domain_admin_password = "password"
        */
        run_once_command_list = [
          "winrm quickconfig -force",
          "winrm set winrm/config @{MaxEnvelopeSizekb=\"100000\"}",
          "winrm set winrm/config/Service @{AllowUnencrypted=\"true\"}",
          "winrm set winrm/config/Service/Auth @{Basic=\"true\"}",
          "netsh advfirewall set allprofiles state off",
        ]
      }

      network_interface {
        ipv4_address    = "${var.ipv4_network_address != "0.0.0.0/0" ? cidrhost(var.ipv4_network_address, var.ipv4_address_start + count.index) : ""}"
        ipv4_netmask    = "${var.ipv4_network_address != "0.0.0.0/0" ? element(split("/", var.ipv4_network_address), 1) : 0}"
        dns_server_list = ["${var.dns_servers}"]
        dns_domain      = "${var.domain_name}"
      }

      ipv4_gateway = "${var.ipv4_gateway}"
    }
  }
}
