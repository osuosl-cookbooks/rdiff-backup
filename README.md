rdiff-backup Cookbook
=====================

Backs up clients to servers using rdiff-backup.

Requirements
------------

## Cookbooks:

* chef-user
* sudo (unless using root as rdiff-backup-client)
* nagios (for nagios alerts regarding backup statuses)

Features
--------

* Can back up clients managed by Chef
* Can back up clients not managed by Chef
* [Planned] Can back up MySQL and PostgreSQL databases
* [Planned] Can send Nagios alerts when backups fail or do not run

Attributes
----------

## Server Attributes:

* `node['rdiff-backup']['server']['starthour']` - Earliest hour of the day to schedule backups, default "13"
* `node['rdiff-backup']['server']['endhour']` - Latest hour of the day to schedule backups, default "23"
* `node['rdiff-backup']['server']['user']` - User to run backups with on the server side, default "rdiff-backup-server"
* `node['rdiff-backup']['server']['restrict-to-own-environment']` - Whether to back up all rdiff-backup clients or only the ones in the same environment as the server, default "true"

## Client Attributes:

* `node['rdiff-backup']['client']['ssh-port']` - SSH port to connect to, default "22"
* `node['rdiff-backup']['client']['source-dirs']` - Array of directories to back up, default ""
* `node['rdiff-backup']['client']['destination-dir']` - Location to store backups on the server side, default "/data/rdiff-backup"
* `node['rdiff-backup']['client']['retention-period']` - String defining how long to keep backups, default "3M" (see rdiff-backup manual for --remove-older-than format)
* `node['rdiff-backup']['client']['additional-args']` - Additional arguments to pass to rdiff-backup, default empty
* `node['rdiff-backup']['client']['user']` - User to run backups with on the client side, default "rdiff-backup-client"

Usage
-----

Note: It is not advised to let the rdiff-backup server also be an rdiff-backup client because the client attributes that the server has will be used as the defaults for all unmanaged hosts.

To set up this cookbook, generate an ssh keypair and create a myclientbackupusername.json in the "user" databag for the rdiff-backup client user containing the pubkey and its user id.

Example data_bags/user/rdiff-backup-client.json:

{
  "id"        : "rdiff-backup-client",
  "ssh_keys"  : ["no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty,command=\"sudo rdiff-backup --server --restrict-read-only /\" ssh-rsa aTjnzpFeQ1kE69Vi3krV58YM1ZcUg7JgbYR337eE== rdiff-backup client"]
}

To allow two rdiff-backup servers to run independently of each other in different environments, each with their own keys and clients, you must use different usernames.

## Server:

Include `recipe[rdiff-backup::server]` in your node's `run_list`, and copy the ssh private key to the rdiff-backup-server's ~/.ssh/id_rsa.

## Client (managed):

Include `recipe[rdiff-backup]` or `recipe[rdiff-backup::client]` in your node's `run_list` and set the node['rdiff-backup']['source-dirs'] attribute for it (preferably in a role).

## Client (unmanaged):

Install rdiff-backup on the client, create the backup user, give it passwordless sudo access, and add the server user's pubkey to its authorized_keys.  Then, in the rdiff-backup_unmanagedhosts databag, create an entry with the client's info.  At the very least, each entry must have an id that corresponds to its fqdn (with underscores replacing all periods), but they may also specify rdiff-backup client attributes, as well as an "environment" to make sure the host gets backed up by the right server.  If not specified in the databag, the environment will default to "_default" and the rdiff-backup client attributes will default to whatever client attributes the server has.  Managed hosts can also have databag entries if managing their attributes through node definitions is not ideal.  Note that if a managed host has a databag entry, any attributes set in the host's node definition will be ignored entirely.

Example data_bags/rdiff-backup_unmanagedhosts/myserver.mydomain.com.json:

{
    "id": "myserver_mydomain_com",
    "environment": "dev"
    "source-dirs": ["/etc","/var/log"],
    "retention-period": "5m"
}
