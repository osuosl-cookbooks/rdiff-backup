rdiff-backup Cookbook
=====================

Backs up clients to servers using rdiff-backup.

Requirements
------------

## Cookbooks:

* Sudo
* User

e.g.
#### packages
- `toaster` - rdiff-backup needs toaster to brown your bagel.

Attributes
----------

## Client Attributes:

* `node['users']` - Creates a client backup user account from the given databag, default rdiff-backup-client
* `node['authorization']['sudo']['users']` - Gives sudo access to the backup user, default rdiff-backup-client
* `node['rdiff-backup']['backup-dirs']` - Array of directories to back up, default empty


## Server Attributes:

* `node['users']` - Creates a server backup user account from the given databag, defaultrdiff-backup-server
* `node['rdiff-backup']['starthour']` - Earliest hour of the day to schedule backups, default 13
* `node['rdiff-backup']['endhour']` - Latest hour of the day to schedule backups, default 23
* `node['rdiff-backup']['backup-target']` - Location to store backups, default /data/rdiff-backup

Usage
-----

Generate an ssh keypair and create an entry in the user databag for the rdiff-backup-client user:

{
  "id"        : "rdiff-backup-client",
  "comment"   : "User for rdiff-backup client backups",
  "home"      : "/home/rdiff-backup-client",
  "ssh_keys"  : ["no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty,command=\"rdiff-backup --server --restrict-read-only / --restrict /data/rdiff-backup-restores\" ssh-rsa aTjnzpFeQ1kE69Vi3krV58YM1ZcUg7JgbYR337eE== osuosl rdiff-backup client"]
}

## Client:

Include `recipe[rdiff-backup]` in your node's `run_list`:

## Server:

Include `recipe[rdiff-backup::server]` in your node's `run_list`, and copy the ssh private key to the rdiff-backup-server's ~/.ssh/id_rsa. 
