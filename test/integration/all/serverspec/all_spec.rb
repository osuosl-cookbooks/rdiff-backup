require 'serverspec'

set :backend, :exec

# Make sure scripts exist
describe file('/home/rdiff-backup-server/scripts/fs_localhost_-etc-cron.d') do
  it { should be_file }
  it { should be_executable.by_user('rdiff-backup-server') }
end
describe file('/home/rdiff-backup-server/scripts/fs_localhost_-var') do
  it { should be_file }
  it { should be_executable.by_user('rdiff-backup-server') }
end

# Make sure the exclude files exist
describe file('/home/rdiff-backup-server/exclude/fs_localhost_-etc-cron.d') do
  it { should be_file }
  it { should be_readable.by_user('rdiff-backup-server') }
end
describe file('/home/rdiff-backup-server/exclude/fs_localhost_-var') do
  it { should be_file }
  it { should be_readable.by_user('rdiff-backup-server') }
end

# Make sure the cron job exists
describe file('/etc/cron.d/rdiff-backup') do
  it { should be_file }
  it { should be_readable.by_user('rdiff-backup-server') }
end

# Test attribute precedence
# Various client and server attributes are specified within the bundled role and databag. This tests that the attributes at different precedence levels override each other properly according to the Attribute Precedence section of the README.

# The 'p1' job should be using the Nagios enable state of 'true' as specified by the cookbook default attribute.
# The 'p2' job should be using the Nagios max-change of '20' rather than '8192' as specified by the server role job default attribute.
# The 'p3' job should be using the Nagios max-late-start of '30' rather than '20' as specified by the server databag job default attribute.
# The 'p4' job should be using the Nagios max-late-finish-warning of '40' rather than '30' as specified by the client role job default attribute.
# The 'p5' job should be using the Nagios max-late-finish-critical of '50' rather than '40' as specified by the client databag job default attribute.

# The 'p5' job should be using a retention period of '5D' as specified by the client databag default attribute.
# The 'p6' job should override the '5D' retention period with '6D' as specified by the server role job-specific attribute.
# The 'p7' job should override the '6D' retention period with '7D' as specified by the server databag job-specific attribute.
# The 'p8' job should override the '7D' retention period with '8D' as specified by the clientrole job-specific attribute.
# The 'p9' job should override the '8D' retention period with '9D' as specified by the clientdatabag job-specific attribute.

describe file('/home/rdiff-backup-server/scripts/fs_localhost_-p5') do
  it { should be_file }
  its(:content) { should match '--remove-older-than 5D' }
end
describe file('/home/rdiff-backup-server/scripts/fs_localhost_-p6') do
  it { should be_file }
  its(:content) { should match '--remove-older-than 6D' }
end
describe file('/home/rdiff-backup-server/scripts/fs_localhost_-p7') do
  it { should be_file }
  its(:content) { should match '--remove-older-than 7D' }
end
describe file('/home/rdiff-backup-server/scripts/fs_localhost_-p8') do
  it { should be_file }
  its(:content) { should match '--remove-older-than 8D' }
end
describe file('/home/rdiff-backup-server/scripts/fs_localhost_-p9') do
  it { should be_file }
  its(:content) { should match '--remove-older-than 9D' }
end
