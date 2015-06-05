require 'serverspec'

set :backend, :exec

describe package('rdiff-backup') do
  it { should be_installed }
end

describe user('rdiff-backup-server') do
  it { should exist }
  it { should have_home_directory '/home/rdiff-backup-server' }
end

describe file('/home/rdiff-backup-server/scripts/fs_localhost_-etc-cron.d') do
  it { should be_file }
  it { should be_executable.by_user('rdiff-backup-server') }
end
describe file('/home/rdiff-backup-server/scripts/fs_localhost_-var') do
  it { should be_file }
  it { should be_executable.by_user('rdiff-backup-server') }
end

describe file('/home/rdiff-backup-server/exclude/fs_localhost_-etc-cron.d') do
  it { should be_file }
  it { should be_readable.by_user('rdiff-backup-server') }
end
describe file('/home/rdiff-backup-server/exclude/fs_localhost_-var') do
  it { should be_file }
  it { should be_readable.by_user('rdiff-backup-server') }
end

describe file('/etc/cron.d/rdiff-backup') do
  it { should be_file }
  its(:content) { should match 'MAILTO=example' }
  its(:content) { should match %r{0 5 \* \* \* rdiff-backup-server /home/rdiff-backup-server/scripts/fs_localhost_-etc-cron.d} }
  its(:content) { should match %r{0 9 \* \* \* rdiff-backup-server /home/rdiff-backup-server/scripts/fs_localhost_-var} }
end

describe file('/var/log/rdiff-backup') do
  it { should be_directory }
  it { should be_writable.by_user('rdiff-backup-server') }
end

describe file('/home/rdiff-backup-server/logs') do
  it { should be_symlink }
end
