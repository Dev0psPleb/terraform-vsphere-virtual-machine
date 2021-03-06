resource "vsphere_virtual_machine" "virtual_machine_bare" {
  count            = "${var.template_os_family == "" ? var.vm_count : 0}"
  name             = "${var.vm_name_prefix}${count.index}"
  resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
  datastore_id     = "${data.vsphere_datastore.ds.id}"
  firmware         = "${var.vm_firmware}"
  folder           = "${var.vsphere_folder}"
  num_cpus = "${var.num_cpus}"
  memory   = "${var.memory}"
  guest_id = "${var.guest_id}"

  wait_for_guest_net_timeout = "${var.wait_for_guest_net_timeout}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label = "disk0"
    size  = "${var.disk_size}"
  }
}