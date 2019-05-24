%w(
  cronolog
  rdiff-backup
).each do |p|
  describe package p do
    it { should be_installed }
  end
end

describe file('/usr/lib64/nagios/plugins/check_rdiff') do
  it { should exist }
  its('mode') { should cmp 0755 }
  its('owner') { should eq 'nrpe' }
  its('group') { should eq 'nrpe' }
  its('content') { should match(/rdiff_check.pl/) }
end

describe user('rdiff-backup-server') do
  it { should exist }
end

describe group('rdiff-backup-server') do
  it { should exist }
end

describe file('/etc/sudoers.d/rdiff-backup-server') do
  it { should exist }
  its('content') { should match(/NOPASSWD/) }
end

describe file('/etc/sudoers.d/check_rdiff') do
  it { should exist }
  its('content') { should match(%r{^nrpe ALL=\(ALL\) NOPASSWD:/usr/lib64/nagios/plugins/check_rdiff$}) }
  its('content') { should match(%r{^nrpe ALL=\(ALL\) NOPASSWD:/usr/lib64/nagios/plugins/check_rdiff_log$}) }
end

describe file('/var/rdiff-backup/locks') do
  it { should exist }
  it { should be_directory }
  its('mode') { should cmp 0755 }
  its('owner') { should eq 'rdiff-backup-server' }
  its('group') { should eq 'rdiff-backup-server' }
end

describe file('/home/rdiff-backup-server/.ssh') do
  it { should exist }
  it { should be_directory }
  its('mode') { should cmp 0700 }
  its('owner') { should eq 'rdiff-backup-server' }
  its('group') { should eq 'rdiff-backup-server' }
end

describe file('/home/rdiff-backup-server/.ssh/id_rsa') do
  it { should exist }
  its('mode') { should cmp 0600 }
  its('owner') { should eq 'rdiff-backup-server' }
  its('content') { should match(/BEGIN RSA PRIVATE KEY/) }
end

describe file('/var/log/rdiff-backup') do
  it { should exist }
  its('mode') { should cmp 0755 }
  its('owner') { should eq 'rdiff-backup-server' }
  its('group') { should eq 'rdiff-backup-server' }
end

describe file('/home/rdiff-backup-server/exclude/192.168.60.11/_help_me_obiwan') do
  its('owner') { should eq 'rdiff-backup-server' }
  its('group') { should eq 'rdiff-backup-server' }
  its('mode') { should cmp 0644 }
end

describe file('/home/rdiff-backup-server/scripts/192.168.60.11/_help_me_obiwan') do
  its('owner') { should eq 'rdiff-backup-server' }
  its('group') { should eq 'rdiff-backup-server' }
  its('mode') { should cmp 0775 }
end

%w(
  /home/rdiff-backup-server/exclude/192.168.60.12
  /home/rdiff-backup-server/exclude/192.168.60.12/_test2
  /home/rdiff-backup-server/scripts/192.168.60.12
  /home/rdiff-backup-server/scripts/192.168.60.12/_test2
).each do |f|
  describe file(f) do
    it { should_not exist }
  end
end

describe crontab('rdiff-backup-server').commands('/usr/bin/flock /var/rdiff-backup/locks/test1 /home/rdiff-backup-server/scripts/192.168.60.11/_help_me_obiwan') do
  its('minutes') { should cmp '0' }
  its('hours') { should cmp '0' }
  its('days') { should cmp '*' }
  its('months') { should cmp '*' }
  its('weekdays') { should cmp '*' }
end

describe crontab('rdiff-backup-server') do
  its('commands') { should_not include '/usr/bin/flock /var/rdiff-backup/locks/test2 /home/rdiff-backup-server/scripts/192.168.60.12/_test2' }
  its('commands') { should_not include '/usr/bin/flock /var/rdiff-backup/locks/delete_tatooine /home/rdiff-backup-server/scripts/192.168.60.25/_help_me_boba_fett' }
end
