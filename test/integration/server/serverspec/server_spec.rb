require 'serverspec'

set :backend, :exec

describe package('rdiff-backup') do
  it { should be_installed }
end

describe user('rdiff-backup-server') do
  it { should exist }
  it { should have_home_directory '/home/rdiff-backup-server' }
end

describe file('/var/log/rdiff-backup') do
  it { should be_directory }
  it { should be_writable.by_user('rdiff-backup-server') }
end

describe file('/etc/cron.d/rdiff-backup') do
  it { should be_file }
end
