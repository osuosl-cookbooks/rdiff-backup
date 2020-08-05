# CHANGELOG for rdiff-backup

This file is used to list changes made in each version of rdiff-backup.

4.1.0 (2020-08-05)
------------------
- Upgrade to centos 8

4.0.0 (2020-06-26)
------------------
- Chef 15 fixes

3.2.0 (2020-06-13)
------------------
- Remove nagios cookbook dependency

3.1.0 (2019-07-15)
------------------
- Manage client ssh keys directly instead of using ssh-keys cookbook

3.0.2 (2018-10-15)
------------------
- Allow sudo for nrpe with check_rdiff plugin

3.0.1 (2018-08-29)
------------------
- Properly remove cron job in rdiff_backup delete action

3.0.0 (2018-08-23)
------------------
- Chef 13 compatibility fixes

2.0.12 (2018-08-13)
-------------------
- Remove dep lock on nagios < 8.0.0 since we need to update it now

2.0.11 (2018-07-23)
-------------------
- Fix cookbook dependency issues

2.0.10 (2017-07-21)
-------------------
- Recursively delete scripts dir when removing backup. 

2.0.9 (2016-12-13)
------------------
- Check if ChefSpec is defined before defining custom matchers.

2.0.8 (2016-12-09)
------------------
- Rdiff backup tests

2.0.7 (2016-11-28)
------------------
- Remove unneeded nagios plugin dir attribute

## 2.0.6:

* PR [38](https://github.com/osuosl-cookbooks/rdiff-backup/pull/38) Fix :delete action for rdiff_backup resource.

## 0.1.0:

* Initial release of rdiff-backup

- - -
Check the [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax) for help with Markdown.

The [Github Flavored Markdown page](http://github.github.com/github-flavored-markdown/) describes the differences between markdown on github and standard markdown.
