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

* `node['rdiff-backup']['starthour']` - Earliest hour of the day to schedule backups, default "13"
* `node['rdiff-backup']['endhour']` - Latest hour of the day to schedule backups, default "23"

## Client Attributes:

* `node['users']` - Creates a client backup user account from the given databag, default "rdiff-backup-client"
* `node['authorization']['sudo']['users']` - Gives sudo access to the backup user, default "rdiff-backup-client"
* `node['rdiff-backup']['source-dirs']` - Array of directories to back up, default empty
* `node['rdiff-backup']['destination-dir']` - Location to store backups, default "/data/rdiff-backup"
* `node['rdiff-backup']['retention-period']` - String defining how long to keep backups, default "3M" (see rdiff-backup manual for --remove-older-than format)
* `node['rdiff-backup']['additional-args']` - Additional arguments for rdiff-backup when backing up nodes, default empty

Usage
-----

Generate an ssh keypair and create a myclientbackupusername.json in the "user" databag for the rdiff-backup client user containing the pubkey and its user id.

Example rdiff-backup-client.json:

{
  "id"        : "rdiff-backup-client",
  "ssh_keys"  : ["no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty,command=\"rdiff-backup --server --restrict-read-only / --restrict /data/rdiff-backup-restores\" ssh-rsa aTjnzpFeQ1kE69Vi3krV58YM1ZcUg7JgbYR337eE== rdiff-backup client"]
}

## Server:

Include `recipe[rdiff-backup::server]` in your node's `run_list`, and copy the ssh private key to the rdiff-backup-server's ~/.ssh/id_rsa.

## Client (managed):

Include `recipe[rdiff-backup]` in your node's `run_list` and set the node['rdiff-backup']['source-dirs'] attribute for it (preferably in a role).

## Client (unmanaged):

Install rdiff-backup on the client, create the backup user, give it passwordless sudo access, and add the server user's pubkey to its authorized_keys.  Then create/edit the rdiff-backup databag and add the client's info to unmanaged-clients.json, using the client's fqdn for each entry, and adding rdiff-backup client attributes under that.  The recipe defaults will be used for any attributes not specified here.

Example unmanaged-clients.json:

{
  
}
