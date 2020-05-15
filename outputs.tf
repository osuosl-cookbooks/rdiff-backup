output "chef_zero" {
    value = "${openstack_compute_instance_v2.chef_zero.network.0.fixed_ip_v4}"
}
output "client" {
    value = "${openstack_compute_instance_v2.client.network.0.fixed_ip_v4}"
}
output "server" {
    value = "${openstack_compute_instance_v2.server.network.0.fixed_ip_v4}"
}
