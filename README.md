rdiff-backup Cookbook
=====================

Backs up clients to servers using rdiff-backup.

Requirements
------------

## Cookbooks:

* Sudo
* User

Attributes
----------

## Server Attributes:

* `node['rdiff-backup']['server']['starthour']` - Earliest hour of the day to schedule backups, default "13"
* `node['rdiff-backup']['server']['endhour']` - Latest hour of the day to schedule backups, default "23"
* `node['rdiff-backup']['server']['user']` - User to run backups with on the server side, default "rdiff-backup-server"

## Client Attributes:

* `node['rdiff-backup']['client']['ssh-port']` - SSH port to connect to, default "22"
* `node['rdiff-backup']['client']['source-dirs']` - Array of directories to back up, default none
* `node['rdiff-backup']['client']['destination-dir']` - Location to store backups on the server side, default "/data/rdiff-backup"
* `node['rdiff-backup']['client']['retention-period']` - String defining how long to keep backups, default "3M" (see rdiff-backup manual for --remove-older-than format)
* `node['rdiff-backup']['client']['additional-args']` - Additional arguments to pass to rdiff-backup, default empty
* `node['rdiff-backup']['client']['user']` - User to run backups with on the client side, default "rdiff-backup-client"

Usage
-----

Generate an ssh keypair and create a myclientbackupusername.json in the "user" databag for the rdiff-backup client user containing the pubkey and its user id.

Example data_bags/user/rdiff-backup-client.json:

{
  "id"        : "rdiff-backup-client",
  "ssh_keys"  : ["no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty,command=\"rdiff-backup --server --restrict-read-only / --restrict /data/rdiff-backup-restores\" ssh-rsa aTjnzpFeQ1kE69Vi3krV58YM1ZcUg7JgbYR337eE== rdiff-backup client"]
}

## Server:

Include `recipe[rdiff-backup::server]` in your node's `run_list`, and copy the ssh private key to the rdiff-backup-server's ~/.ssh/id_rsa.

## Client (managed):

Include `recipe[rdiff-backup]` in your node's `run_list` and set the node['rdiff-backup']['source-dirs'] attribute for it (preferably in a role).

## Client (unmanaged):

Install rdiff-backup on the client, create the backup user, give it passwordless sudo access, and add the server user's pubkey to its authorized_keys.  Then, in the rdiff-backup_unmanagedhosts databag, create an entry with the client's info.  At the very least, each entry must have an id and an fqdn, but they may also specify any rdiff-backup client attributes.  The recipe defaults will be used for any attributes not specified in the databag.  Managed hosts can also have databag entries if managing their attributes through node definitions is not ideal.  Note that if a managed host has a databag entry, any attributes set in the host's node definition will be ignored entirely.

Example data_bags/rdiff-backup_unmanagedhosts/myserver.mydomain.com.json:

{
    "id": "myserver",
    "fqdn": "myserver.mydomain.com",
    "source-dirs": ["/etc","/var/log"],
    "retention-period": "5m"
}
