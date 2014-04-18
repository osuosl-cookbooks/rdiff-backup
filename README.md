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
* Can send Nagios alerts when backups fail or do not run
* [Planned] Can back up MySQL and PostgreSQL databases

Attributes
----------

## Server Attributes:

* `node['rdiff-backup']['server']['start-hour']` - Earliest hour of the day to schedule jobs, default "13"
* `node['rdiff-backup']['server']['end-hour']` - Latest hour of the day to schedule jobs, default "23"
* `node['rdiff-backup']['server']['user']` - User to run backups with on the server side, default "rdiff-backup-server"
* `node['rdiff-backup']['server']['restrict-to-own-environment']` - Whether to back up all rdiff-backup clients or only the ones in the same environment as the server, default "true"
* `node['rdiff-backup']['server']['mailto']` - The email address(es) (comma delimited) to mail cron reports to, default "" (no mail is sent)
* `node['rdiff-backup']['server']['nagios']['alerts']` - Whether to provide Nagios alerts for the status of each job, default "true" (must be enabled for any alerts to be created)
* `node['rdiff-backup']['server']['nagios']['plugin-dir']` - The directory to store the `check_rdiff` nagios plugin, default "/usr/lib64/nagios/plugins"

## Client Attributes:

* `node['rdiff-backup']['client']` - Map of jobs to run, where each key is a source dir to back up (or 'default') and each value is a hash of attributes specific to that job, default empty
* `node['rdiff-backup']['client']['\etc']` - (Example) Map of optional attributes to be used for the `/etc` job on this client, default empty
* `node['rdiff-backup']['client']['default']` - Map of optional attributes to be used as defaults for all jobs on this client, default empty
* `node['rdiff-backup']['client']['default']['ssh-port']` - SSH port to connect to, default "22"
* `node['rdiff-backup']['client']['default']['user']` - User to run backups with on the client side, default "rdiff-backup-client"
* `node['rdiff-backup']['client']['default']['destination-dir']` - Location to store backups on the server side, default "/data/rdiff-backup"
* `node['rdiff-backup']['client']['default']['exclude-dirs']` - A set of files and directories not to ignore (not back up), default empty
* `node['rdiff-backup']['client']['default']['retention-period']` - String defining how long to keep backups, default "3M" (see rdiff-backup manual for --remove-older-than format)
* `node['rdiff-backup']['client']['default']['additional-args']` - String of additional arguments to pass to rdiff-backup, default ""
* `node['rdiff-backup']['client']['default']['nagios']['alerts']` - Whether to provide Nagios alerts for the status of the backup, default "true" (no effect if server has all alerts disabled)
* `node['rdiff-backup']['client']['default']['nagios']['max-change']` - How many megabytes the backup repo can change by from a single backup before a warning alert is sent, default 1024
* `node['rdiff-backup']['client']['default']['nagios']['max-late-start']` - How late (in hours) the job can start before a critical alert is sent, default 2
* `node['rdiff-backup']['client']['default']['nagios']['max-late-finish-warning']` - How long (in hours) the job can run before a warning alert is sent, default 4
* `node['rdiff-backup']['client']['default']['nagios']['max-late-finish-critical']` - How long (in hours) the job can run before a critical alert is sent, default 8

Usage
-----

Note: The rdiff-backup server cannot also be an rdiff-backup client.  The client attributes that the server has are simply used as defaults for its clients.  Attributes for jobs take precedence in the following order, with job-specific attributes overriding everything:

1. Cookbook defaults, as specified in attributes/client.rb.  These are the base defaults.
2. Server attributes, as specified by its node definition or any roles it is in.  More precisely, these are simply the client attributes that the server has (i.e. anything under `['rdiff-backup']['client']['default']`).
3. Server databag attributes (optional).
4. Client attributes, as specified by its node definition or any roles it is in (N/A for unmanaged hosts).
5. Client databag attributes (optional for managed hosts).
6. Job-specific attributes.  These attributes may optionally be specified in a map under a specific job and will override all other attributes.

To set up this cookbook, generate an ssh keypair and create a myclientbackupusername.json in the "user" databag for the rdiff-backup client user containing the pubkey and its user id.

Example `data_bags/users/rdiff-backup-client.json`:

`{
  "id"        : "rdiff-backup-client",
  "ssh_keys"  : ["no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty,command=\"sudo rdiff-backup --server --restrict-read-only /\" ssh-rsa aTjnzpFeQ1kE69Vi3krV58YM1ZcUg7JgbYR337eE== rdiff-backup client"]
}`

To allow two rdiff-backup servers to run independently of each other in different environments, each with their own keys and clients, you must use different usernames.

## Server:

Include `recipe[rdiff-backup::server]` in your node's `run_list`, and copy the ssh private key to the rdiff-backup server's `~/.ssh/id_rsa`.

## Client (managed):

Include `recipe[rdiff-backup]` or `recipe[rdiff-backup::client]` in your node's `run_list` and set the `node['rdiff-backup']['client']['jobs']` attribute for it (preferably in a role or databag, but also possible through the node definition itself via `knife node edit`).

## Client (unmanaged):

Install rdiff-backup on the client, create the backup user, give it passwordless sudo access, and add the server user's pubkey to its `authorized_keys`.  Then, in the `rdiff-backup_hosts` databag, create an entry with the client's info.  At the very least, each entry must have an id that corresponds to its fqdn (with underscores replacing all periods), but they may also specify rdiff-backup client attributes, as well as an "environment" to make sure the host gets backed up by the right server.  If not specified in the databag, the environment will default to `_default` and the rdiff-backup client attributes will default to whatever client attributes the server has.  Managed hosts can also have databag entries if managing their attributes through node definitions is not ideal.  Note that if a managed host has a databag entry, any attributes set in the host's node definition will be ignored entirely.

Example `data_bags/rdiff-backup_hosts/myserver.mydomain.com.json`:

`{
    "id": "myserver_mydomain_com",
    "chef_environment": "dev",
    "rdiff-backup": {
        "client": {
            "default": {
                "ssh-port": 2222,
                "user": "my-special-rdiff-backup-user",
                "retention-period": "3M",
                "exclude-dirs": [
                    "/etc/keys",
                    "/var/log/apache",
                    "/var/log/nginx"
                ]
            },
            "/etc": {},
            "/home": {},
            "/var/log": {
                "retention-period": "2W"
            }
        }
    }
}`
