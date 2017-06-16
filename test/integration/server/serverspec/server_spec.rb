require 'serverspec'

set :backend, :exec

describe package('rdiff-backup') do
  it { should be_installed }
end

describe user('rdiff-backup-server') do
  it { should exist }
end

describe file('/home/rdiff-backup-server/exclude/192.168.60.11/_help_me_obiwan') do
  it { should be_owned_by 'rdiff-backup-server' }
  it { should be_grouped_into 'rdiff-backup-server' }
  it { should be_mode 644 }
end

describe file('/home/rdiff-backup-server/scripts/192.168.60.11/_help_me_obiwan') do
  it { should be_owned_by 'rdiff-backup-server' }
  it { should be_grouped_into 'rdiff-backup-server' }
  it { should be_mode 775 }
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
