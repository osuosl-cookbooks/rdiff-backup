rdiff-backup Cookbook
=====================

Backs up hosts using rdiff-backup.

Requirements
------------

* `Chef >= 12.18`

## Required Cookbooks:

* `yum` (for installing rdiff-backup)
* `yum-epel` (for installing rdiff-backup)

## Optional Cookbooks:

* `sudo` (for reading files to back up and so the nrpe user can read the status of repos)
* `nrpe` (for nagios alerts regarding backup statuses)

## Optional External Cookbooks:

* `nagios` (for nagios alerts regarding backup statuses)

Features
--------

* Can back up clients managed by Chef
* Can back up clients not managed by Chef
* Can send Nagios alerts if backups fail, start late, run too long, grow too quickly, or become corrupted
* [Planned] Can back up MySQL and PostgreSQL databases

Overview
--------

Jobs can be specified through node definitions, roles, cookbooks, and/or
databags for both the rdiff-backup server and each rdiff-backup client.  Jobs
run within a certain time period once every night.  One rdiff-backup server may
find and back up all hosts on the same chef server (or just within the same
environment) via Chef search, and is capable of backing up non-chef hosts as
well, as long as a databag is created for it.  When Chef runs on the
rdiff-backup server, jobs are created for each directory on each host to be
backed up.  Each job has an entry added to the crontab (at
`/etc/cron.d/rdiff-backup`) and a backup script added to
`/home/rdiff-backup-server/scripts`.  These simple bash scripts are generally
run by cron, but may be run manually at any time to start a job if it is not
already running.  A job will back up the source directory on the given host to
`/data/rdiff-backup` (or other specified directory) on the rdiff-backup server.
Additional log files are generated at `/var/log/rdiff-backup`, and include both
a general log for all backups as well as more verbose logs for each individual
job.

The rdiff-backup server may also act as a client and back up its own local
directories.  This is useful for backing up locally-mounted network
filesystems.  Backing up the rdiff-backup data directory is not recommended.

It is worth noting that rdiff-backup is run with `--exclude-other-filesystems`
by default, which means that subdirectories on different volumes/filesystems
will not be backed up.  For example, if /var and /var/www are on different
filesystems, both must be specified as backup dirs explicitly to back both of
them up, as rdiff-backup will not recurse into /var/www from within the /var
backup.

## Nagios

If Nagios alerts are enabled, checks will be added for new backups after they
run for the first time, after which they will alert if the backups fail, start
late, run too long, grow too quickly, or become corrupted.

Attributes
----------

## Server Attributes:

* `node['rdiff-backup']['server']['start-hour']` - Earliest hour of the day to schedule jobs, default "13"
* `node['rdiff-backup']['server']['end-hour']` - Latest hour of the day to schedule jobs, default "23"
* `node['rdiff-backup']['server']['restrict-to-own-environment']` - Whether to back up all rdiff-backup clients or only the ones in the same environment as the server, default "true"
* `node['rdiff-backup']['server']['restrict-to-environments']` - If `restrict-to-own-environment` is false, the rdiff-backup server will only back up clients in this given list of environments, defaults to all environments (effectively disabling all environment restrictions)
* `node['rdiff-backup']['server']['mailto']` - The email address(es) (comma delimited) to mail cron reports to, default "" (no mail is sent)
* `node['rdiff-backup']['server']['nagios']['alerts']` - Whether to provide Nagios alerts for the status of each job, default "true" (must be enabled for any alerts to be created)
* `node['rdiff-backup']['server']['user']` - User to run backups with on the server side, default "rdiff-backup-server"
* `node['rdiff-backup']['server']['jobs']` - Map of jobs to run for all clients, where each key is a source dir to back up (or 'default') and each value is a hash of attributes specific to that job, defaults below

## Client Attributes:

* `node['rdiff-backup']['client']['ssh_keys']` - Array of public ssh keys. default ``[]``
* `node['rdiff-backup']['client']['ssh-port']` - SSH port to connect to, default "22"
* `node['rdiff-backup']['client']['user']` - User to run backups with on the client side, default "rdiff-backup-client"
* `node['rdiff-backup']['client']['jobs']` - Map of jobs to run for a particular client, where each key is a source dir to back up (or 'default') and each value is a hash of attributes specific to that job, default empty

## Job Attributes:

Job attributes may be set on either the server or the client.  When set on the
server, the attributes will be used as the defaults for all jobs unless
overridden by job attributes that are set on a client.

* `node['rdiff-backup']['<server|client>']['jobs']['default']` - Map of optional attributes to be used as defaults for all jobs on this client, defaults below
* `node['rdiff-backup']['<server|client>']['jobs']['default']['destination-dir']` - Location to store backups on the server side, default "/data/rdiff-backup"
* `node['rdiff-backup']['<server|client>']['jobs']['default']['exclude-dirs']` - A set of files and directories not to ignore (not back up), default empty
* `node['rdiff-backup']['<server|client>']['jobs']['default']['retention-period']` - String defining how long to keep backups, default "3M" (see rdiff-backup manual for --remove-older-than format)
* `node['rdiff-backup']['<server|client>']['jobs']['default']['additional-args']` - String of additional arguments to pass to rdiff-backup, default ""
* `node['rdiff-backup']['<server|client>']['jobs']['default']['nagios']['alerts']` - Whether to provide Nagios alerts for the status of the backup, default "true" (no effect if server has all alerts disabled)
* `node['rdiff-backup']['<server|client>']['jobs']['default']['nagios']['max-change']` - How many megabytes the backup repo can change by from a single backup before a warning alert is sent, default 1024
* `node['rdiff-backup']['<server|client>']['jobs']['default']['nagios']['max-late-start']` - How late (in hours) the job can start before a critical alert is sent, default 2
* `node['rdiff-backup']['<server|client>']['jobs']['default']['nagios']['max-late-finish-warning']` - How long (in hours) the job can run before a warning alert is sent, default 4
* `node['rdiff-backup']['<server|client>']['jobs']['default']['nagios']['max-late-finish-critical']` - How long (in hours) the job can run before a critical alert is sent, default 8

* `node['rdiff-backup']['<server|client>']['jobs']['default']['retention-period'] = '3M'` - Example of how to set the default retention-period for all jobs
* `node['rdiff-backup']['<server|client>']['jobs']['/etc']['retention-period'] = '2W'` - Example of how to set the retention-period for the `/etc` job, overriding the default

## Attribute Precedence:

Attributes for jobs are applied in the following order, with later attributes
overriding earlier ones:

1. Cookbook defaults, as specified above as well as at the top of
   recipes/server.rb and recipes/client.rb.  These are the base defaults.

2. Server node default attributes, as specified by
   `['rdiff-backup']['server']['jobs']['default']` in the server's node
   definition (usually set through roles).
3. Server databag default attributes, as specified by
   `['rdiff-backup']['server']['jobs']['default']` in the
   `data_bags/rdiff-backup_hosts/myserver_mydomain_com.json` databag.
   (Optional)
4. Client node default attributes, as specified by
   `['rdiff-backup']['client']['jobs']['default']` in the client's node
   definition (usually set through roles).
5. Client databag default attributes, as specified by
   `['rdiff-backup']['client']['jobs']['default']` in the
   `data_bags/rdiff-backup_hosts/myclient_mydomain_com.json` databag.
   (Optional)

6. Server node job-specific attributes, as specified by
   `['rdiff-backup']['server']['jobs']['/path/to/back/up']` in the server's
   node definition (usually set through roles). (Not usually used)
7. Server databag job-specific attributes, as specified by
   `['rdiff-backup']['server']['jobs']['/path/to/back/up']` in the
   `data_bags/rdiff-backup_hosts/myserver_mydomain_com.json` databag.
   (Optional, not usually used)
8. Client node job-specific attributes, as specified by
   `['rdiff-backup']['client']['jobs']['/path/to/back/up']` in the client's
   node definition (usually set through roles).
9. Client databag job-specific attributes, as specified by
   `['rdiff-backup']['client']['jobs']['/path/to/back/up']` in the
   `data_bags/rdiff-backup_hosts/myclient_mydomain_com.json` databag.
   (Optional)

In general, it may be easier to remember that databag attributes override node
attributes, client attributes override server attributes, and job-specific
attributes override 'default' job attributes.  It is also possible to simply
ignore most of the order and set up backups entirely through one level, such as
entirely through roles or entirely through databags.

Usage
-----

To set up an rdiff-backup server, first generate an ssh keypair (such as with `ssh-keygen`) and add the public key to
``node['rdiff-backup']['client']['ssh_keys']``

Example:
``` ruby
node.default['rdiff-backup']['client']['ssh_keys'] =
  [
    'no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty,command=\"sudo rdiff-backup --server --restrict-read-only /\" ssh-rsa aTjnzpFeQ1kE69Vi3krV58YM1ZcUg7JgbYR337eE== rdiff-backup client'
  ]
include_recipe 'rdiff-backup::client'
```

To allow two rdiff-backup servers to run independently of each other in different environments, each with their own
keys and clients, you must use different usernames.

## Server:

Include `recipe[rdiff-backup::server]` in your node's `run_list`, and copy the
ssh private key to the rdiff-backup server's `~/.ssh/id_rsa`.

## Client (managed):

Include `recipe[rdiff-backup]` or `recipe[rdiff-backup::client]` in your node's
`run_list`.  If the server has the jobs you want specified, those will be used.
Otherwise, set the `node['rdiff-backup']['client']['jobs']` attribute for it
(preferably in a role or databag).  All other attributes are optional, and the
defaults of the cookbook and/or rdiff-backup server will be used.

## Client (unmanaged):

Install rdiff-backup on the client, create the backup user, give it
passwordless sudo access, and add the server user's pubkey to its
`authorized_keys`.  Then, in the `rdiff-backup_hosts` databag, create an entry
with the client's info.  At the very least, each entry must have an id that
corresponds to its fqdn (with underscores replacing all periods), but they may
also specify rdiff-backup client attributes, as well as an "environment" to
make sure the host gets backed up by the right server.  If not specified in the
databag, the environment will default to `_default` and the rdiff-backup client
attributes will default to whatever client attributes the server has.  Managed
hosts can also have databag entries if managing their attributes through node
definitions is not ideal.  Note that if a managed host has a databag entry, any
attributes set in the host's node definition will be ignored entirely.

Example `data_bags/rdiff-backup_hosts/myclient_mydomain_com.json`:

``` json
{
  "id": "myclient_mydomain_com",
  "chef_environment": "dev",
  "rdiff-backup": {
    "client": {
      "ssh-port": 2222,
      "user": "my-special-rdiff-backup-user",
      "jobs": {
        "default": {
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
  }
}
```

Additionally, a databag for the rdiff-backup server may contain both server
attributes (to be used as defaults for all jobs) and client attributes (for
backing up itself).

Provisioning Environment
------------------------

### Prereqs

- ChefDK 2.5.3 or later
- Terraform
- kitchen-terraform
- OpenStack cluster

Ensure you have the following in your ``.bashrc`` (or similar):

```bash
export TF_VAR_ssh_key_name="$OS_SSH_KEYPAIR"
```

### General Layout

This cookbook contains a [kitchen-terraform](https://github.com/newcontext-oss/kitchen-terraform)
environment that can be used to test multi-node configurations. You can spin up
this environment using `kitchen test multi-node`.

If you want to create/converge only 1 VM you can use any of these commands:

VM | Command
---- | --------------
client | `terraform apply -target openstack_compute_instance_v2.client`
server | `terraform apply -target openstack_compute_instance_v2.server`

You can login to a VM by using one of these commands:
```bash
$ ssh centos@$(terraform output client)
$ ssh centos@$(terraform output server)
```

When you are done testing the provisioning environment run
``kitchen destroy multi-node``.

Here is a table showing what each IP points to:

Host   | IP
------ | --------------
client | `192.168.60.11`
server | `192.168.60.12`

### Interacting with the chef-zero server

All of these nodes are configured using a Chef Server which is a container
running chef-zero. You can interact with the chef-zero server by doing the
following:

```bash
$ CHEF_SERVER="$(terraform output chef_zero)" knife node list -c test/chef-config/knife.rb
client
server
```

In addition, on any node that has been deployed, you can re-run ``chef-client``
like you normally would on a production system. This should allow you to do
development on your multi-node environment as needed. **Just make sure you
include the knife config otherwise you will be interacting with our production
Chef server!**

### Using Terraform directly

You do not need to use kitchen-terraform directly if you're just doing
development. It's primarily useful for testing the multi-node cluster using
inspec. You can simply deploy the cluster using terraform directly by doing
the following:

```bash
# Sanity check
$ terraform plan
# Deploy the cluster
$ terraform apply
# Destroy the cluster
$ terraform destroy
```
