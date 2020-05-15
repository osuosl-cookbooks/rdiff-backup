resource "openstack_networking_network_v2" "openstack_network" {
    name            = "rdiff_backup_openstack_network"
    admin_state_up  = "true"
}

resource "openstack_networking_subnet_v2" "openstack_subnet" {
    network_id      = "${openstack_networking_network_v2.openstack_network.id}"
    cidr            = "192.168.60.0/24"
    enable_dhcp     = "false"
    no_gateway      = "true"
}

resource "openstack_compute_instance_v2" "chef_zero" {
    name            = "chef-zero"
    image_name      = "${var.centos_atomic_image}"
    flavor_name     = "m1.small"
    key_pair        = "${var.ssh_key_name}"
    security_groups = ["default"]
    connection {
        user = "centos"
    }
    network {
        uuid = "${data.openstack_networking_network_v2.network.id}"
    }
    provisioner "remote-exec" {
        inline = [
            "until [ -S /var/run/docker.sock ] ; do sleep 1 && echo 'docker not started...' ; done",
            "sudo docker run -d -p 8889:8889 --name chef-zero osuosl/chef-zero"
        ]
    }
    provisioner "local-exec" {
        command = "rake knife_upload"
        environment = {
            CHEF_SERVER = "${openstack_compute_instance_v2.chef_zero.network.0.fixed_ip_v4}"
        }
    }
}

resource "openstack_compute_instance_v2" "client" {
    name            = "client"
    image_name      = "${var.centos_image}"
    flavor_name     = "m1.medium"
    key_pair        = "${var.ssh_key_name}"
    security_groups = ["default"]
    connection {
        user = "centos"
    }
    network {
        uuid = "${data.openstack_networking_network_v2.network.id}"
    }
    network {
        uuid = "${openstack_networking_network_v2.openstack_network.id}"
        fixed_ip_v4 = "192.168.60.11"
    }
    provisioner "chef" {
        run_list        = ["recipe[rdiff-backup-test::network]", "recipe[rdiff-backup-test::client]"]
        node_name       = "client"
        secret_key      = "${file("test/integration/encrypted_data_bag_secret")}"
        server_url      = "http://${openstack_compute_instance_v2.chef_zero.network.0.fixed_ip_v4}:8889"
        recreate_client = true
        user_name       = "fakeclient"
        user_key        = "${file("test/chef-config/fakeclient.pem")}"
        version         = "${var.chef_version}"
    }
}

resource "openstack_compute_instance_v2" "server" {
    name            = "server"
    image_name      = "${var.centos_image}"
    flavor_name     = "m1.medium"
    key_pair        = "${var.ssh_key_name}"
    security_groups = ["default"]
    depends_on      = ["openstack_compute_instance_v2.client"]
    connection {
        user = "centos"
    }
    network {
        uuid = "${data.openstack_networking_network_v2.network.id}"
    }
    network {
        uuid = "${openstack_networking_network_v2.openstack_network.id}"
        fixed_ip_v4 = "192.168.60.12"
    }
    provisioner "chef" {
        run_list        = ["recipe[rdiff-backup-test::network]", "recipe[rdiff-backup-test::create_server]"]
        node_name       = "server"
        secret_key      = "${file("test/integration/encrypted_data_bag_secret")}"
        server_url      = "http://${openstack_compute_instance_v2.chef_zero.network.0.fixed_ip_v4}:8889"
        recreate_client = true
        user_name       = "fakeclient"
        user_key        = "${file("test/chef-config/fakeclient.pem")}"
        version         = "${var.chef_version}"
    }
}
