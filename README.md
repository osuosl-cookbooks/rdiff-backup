rdiff-backup Cookbook
=====================

Backs up hosts using rdiff-backup.

Requirements
------------

* `Chef >= 11.10`

## Required Cookbooks:

* `yum` (for installing rdiff-backup)
* `yum-epel` (for installing rdiff-backup)
* `chef-user` (for setting up user accounts)

## Optional Cookbooks:

* `partial_search` (for more efficient chef search)
* `sudo` (for reading files to back up and so the nrpe user can read the status of repos)
* `nrpe` (for nagios alerts regarding backup statuses)

## Optional External Cookbooks:

* `nagios >= ???` (for nagios alerts regarding backup statuses)

Features
--------

* Can back up clients managed by Chef
* Can back up clients not managed by Chef
* Can send Nagios alerts if backups fail, start late, run too long, grow too quickly, or become corrupted
* Can back up MySQL databases
* [Planned] Can back up PostgreSQL databases

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

These attributes are set on the rdiff-backup server and apply defaults to all
jobs that run on it.

All starting with `node['rdiff-backup']['server']`:

* `['start-hour']` - Earliest hour of the day to schedule jobs, default "13"
* `['end-hour']` - Latest hour of the day to schedule jobs, default "23"
* `['user']` - User to run backups with on the server side, default "rdiff-backup-server"
* `['sudo']` - Whether to provide sudo access to the rdiff-backup-server user, default "true" (may cause adverse effects if disabled)
* `['restrict-to-own-environment']` - Whether to back up all rdiff-backup clients or only the ones in the same environment as the server, default "true"
* `['mailto']` - A string of email address(es) (comma delimited) to mail cron reports to, default "" (no mail is sent)
* `['nagios']['enable']` - Whether to provide Nagios alerts for the status of each job, default "true" (must be enabled for any alerts to be created)
* `['nagios']['plugin-dir']` - The directory to store the `check_rdiff` nagios plugin, default "/usr/lib64/nagios/plugins"

### Filesystem Attributes:

* `['fs']['enable']` - Whether to perform filesystem backups of clients, default "true" (must be enabled for any filesystem backups to run)
* `['fs']['job-defaults']` - Map of job attributes to use as the defaults for all filesystem jobs running on the server, defaults below
* `['fs']['jobs']` - Map of jobs to run for all clients, where each key is a source dir to back up and each value is a map of job attributes specific to all jobs of the same name (filesystem path) running on the server, defaults below

### MySQL Attributes:

* `['mysql']['enable']` - Whether to perform MySQL backups of clients, default "true" (must be enabled for any mysql backups to run)
* `['mysql']['job-defaults']` - Map of job attributes to use as the defaults for all MySQL jobs running on the server, defaults below
* `['mysql']['jobs']` - Map of jobs to run for all clients, where each key is the name of a MySQL database to back up and each value is a map of job attributes specific to all jobs of the same name (MySQL database name) running on the server, defaults below

## Client Attributes:

These attributes are set on rdiff-backup clients and apply defaults to all jobs
for that client, overriding server defaults.

All starting with `node['rdiff-backup']['client']`:

* `['ssh-port']` - SSH port to connect to, default "22"
* `['user']` - User to run backups with on the client side, default "rdiff-backup-client"
* `['sudo']` - Whether to provide sudo access to the rdiff-backup-client user, default "true" (may cause adverse effects if disabled)

### Filesystem Attributes:

* `['fs']['enable']` - Whether to perform filesystem backups of this client, default "true"
* `['fs']['job-defaults']` - Map of job attributes to use as the defaults for all filesystem jobs on this client, defaults below
* `['fs']['jobs']` - Map of jobs to run for this client, where each key is a source dir to back up and each value is a map of job attributes specific to that job on this client, defaults below

### MySQL Attributes:

* `['mysql']['enable']` - Whether to perform MySQL backups of this client, default "false"
* `['mysql']['job-defaults']` - Map of job attributes to use as the defaults for all MySQL jobs on this client, defaults below
* `['mysql']['jobs']` - Map of jobs to run for this client, where each key is the name of a MySQL database to back up and each value is a map of job attributes specific to that job on this client, defaults below

## Job Attributes:

Job attributes may be set on either the server or the client.  When
`['job-defaults']` is set, those values will be used as the defaults for all
jobs.  Client attributes override server attributes, and job-specific
attributes (i.e. for a job in the `['jobs']` list rather than
`['job-defaults']`) override both.

All starting with `node['rdiff-backup']['<server|client>']`:

* `['<fs|mysql>']['job-defaults']` - Map of optional attributes to be used as defaults for all jobs on this client, defaults below
* `['<fs|mysql>']['job-defaults']['enable']` - Whether to run the job, default "true" (useful for disabling a specific job that would normally done be by default)
* `['<fs|mysql>']['job-defaults']['destination-dir']` - Location to store backups on the server side, default "/data/rdiff-backup"
* `['<fs|mysql>']['job-defaults']['retention-period']` - String defining how long to keep backups, default "3M" (see rdiff-backup manual for --remove-older-than format)
* `['<fs|mysql>']['job-defaults']['additional-args']` - String of additional arguments to pass to rdiff-backup, default ""
* `['<fs|mysql>']['job-defaults']['nagios']['enable']` - Whether to provide Nagios alerts for the status of the backup, default "true" (no effect if server has all alerts disabled)
* `['<fs|mysql>']['job-defaults']['nagios']['max-change']` - How many megabytes the backup repo can change by from a single backup before a warning alert is sent, default 8192
* `['<fs|mysql>']['job-defaults']['nagios']['max-late-start']` - How late (in hours) the job can start before a critical alert is sent, default 2
* `['<fs|mysql>']['job-defaults']['nagios']['max-late-finish-warning']` - How long (in hours) the job can run before a warning alert is sent, default 4
* `['<fs|mysql>']['job-defaults']['nagios']['max-late-finish-critical']` - How long (in hours) the job can run before a critical alert is sent, default 8

### Filesystem Attributes:

* `['fs']['job-defaults']['exclude-dirs']` - A set of files and directories to ignore (not back up), default empty

### MySQL Attributes:

* `['mysql']['job-defaults']['single-transaction']` - Whether to run MySQL dumps with `--single-transaction`, default "true"

## Examples

To set the default retention period for all filesystem jobs:
* `node['rdiff-backup']['server']['fs']['job-defaults']['retention-period'] = '3M'`

To set the retention period for all `/etc` jobs, overriding the above default:
* `node['rdiff-backup']['server']['fs']['jobs']['/etc']['retention-period'] = '2W'`

To set the retention period for all MySQL jobs:
* `node['rdiff-backup']['server']['mysql']['job-defaults']['retention-period'] = '2W'`

To set the retention period for all MySQL jobs with databases named `drupal`, overriding the above default:
* `node['rdiff-backup']['server']['mysql']['jobs']['drupal']['retention-period'] = '10D'`

To set the retention period for the `drupal` MySQL database job on a particular client, overriding the above default:
* `node['rdiff-backup']['client']['mysql']['jobs']['drupal']['retention-period'] = '20D'`

## Attribute Precedence:

Attributes for jobs are applied in the following order, with later attributes
overriding earlier ones:

1. Cookbook defaults, as specified above as well as at the top of
   recipes/server.rb and recipes/client.rb.  These are the base defaults.

2. Server node default attributes, as specified by
   `['rdiff-backup']['server']['<fs|mysql>']['job-defaults']` in the server's
   node definition (usually set through roles).
3. Server databag default attributes, as specified by
   `['rdiff-backup']['server']['<fs|mysql>']['job-defaults']` in the
   `data_bags/rdiff-backup_hosts/myserver_mydomain_com.json` databag.
   (Optional)
4. Client node default attributes, as specified by
   `['rdiff-backup']['client']['<fs|mysql>']['job-defaults']` in the client's
   node definition (usually set through roles).
5. Client databag default attributes, as specified by
   `['rdiff-backup']['client']['<fs|mysql>']['job-defaults']` in the
   `data_bags/rdiff-backup_hosts/myclient_mydomain_com.json` databag.
   (Optional)

6. Server node job-specific attributes, as specified by
   `['rdiff-backup']['server']['<fs|mysql>']['jobs']['/path/to/back/up']` in
   the server's node definition (usually set through roles). (Not usually used)
7. Server databag job-specific attributes, as specified by
   `['rdiff-backup']['server']['<fs|mysql>']['jobs']['/path/to/back/up']` in
   the `data_bags/rdiff-backup_hosts/myserver_mydomain_com.json` databag.
   (Optional, not usually used)
8. Client node job-specific attributes, as specified by
   `['rdiff-backup']['client']['<fs|mysql>']['jobs']['/path/to/back/up']` in
   the client's node definition (usually set through roles).
9. Client databag job-specific attributes, as specified by
   `['rdiff-backup']['client']['<fs|mysql>']['jobs']['/path/to/back/up']` in
   the `data_bags/rdiff-backup_hosts/myclient_mydomain_com.json` databag.
   (Optional)

In general, it may be easier to remember that databag attributes override node
attributes, client attributes override server attributes, and job-specific
attributes override default (`['job-defaults']`) job attributes.  It is also
possible to simply ignore most of the order and set up backups entirely through
one level, such as entirely through roles or entirely through databags.

Usage
-----

To set up an rdiff-backup server, first generate an ssh keypair (such as with
`ssh-keygen`) and create a myclientbackupusername.json in the "user" databag
for the rdiff-backup client user containing the pubkey and its user id.

Example `data_bags/users/rdiff-backup-client.json`:

`{
  "id"        : "rdiff-backup-client",
  "ssh_keys"  : ["no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty,command=\"sudo rdiff-backup --server --restrict-read-only /\" ssh-rsa aTjnzpFeQ1kE69Vi3krV58YM1ZcUg7JgbYR337eE== rdiff-backup client"]
}`

To allow two rdiff-backup servers to run independently of each other in
different environments, each with their own keys and clients, you must use
different usernames.  This is a limitation of the user cookbook.

## Server:

Include `recipe[rdiff-backup::server]` in your node's `run_list`, and copy the
ssh private key to the rdiff-backup server's `~/.ssh/id_rsa`.

## Client (managed):

Include `recipe[rdiff-backup]` or `recipe[rdiff-backup::client]` in your node's
`run_list`.  If the server has the jobs you want specified, those will be used.
Otherwise, set the `node['rdiff-backup']['client']['<fs|mysql>']['jobs']`
attribute for it (preferably in a role or databag).  All other attributes are
optional, and the defaults of the cookbook and/or rdiff-backup server will be
used.

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

`{
    "id": "myclient_mydomain_com",
    "chef_environment": "dev",
    "rdiff-backup": {
        "client": {
            "ssh-port": 2222,
            "user": "my-special-rdiff-backup-user",
            "fs": {
                "job-defaults": {
                    "retention-period": "3M",
                    "exclude-dirs": [
                        "/etc/keys",
                        "/var/log/apache",
                        "/var/log/nginx"
                    ]
                },
                "jobs": {
                    "/etc": {},
                    "/home": {},
                    "/var/log": {
                        "retention-period": "2W"
                    }
                }
            }
        }
    }
}`

Additionally, a databag for the rdiff-backup server may contain both server
attributes (to be used as defaults for all jobs) and client attributes (for
backing up itself).
