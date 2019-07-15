describe package('rdiff-backup') do
  it { should be_installed }
end

describe user('rdiff-backup-client') do
  it { should exist }
  its('shell') { should eq '/bin/bash' }
end

describe directory '/home/rdiff-backup-client/.ssh' do
  its('mode') { should cmp '0700' }
  its('owner') { should cmp 'rdiff-backup-client' }
  its('group') { should cmp 'rdiff-backup-client' }
end

describe file '/home/rdiff-backup-client/.ssh/authorized_keys' do
  its('mode') { should cmp '0600' }
  its('owner') { should cmp 'rdiff-backup-client' }
  its('group') { should cmp 'rdiff-backup-client' }
  its('content') { should match %r{ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzDoq1UGRj412cNrL2Q3gNZkldvIHeb6HnuDcUbkFPQPdAzdA4azDKBLam6S/oe6nJr3BtQMpracmReBVlzl/Jjn/5GYoCsDZm5WlaxYMASPnXTdEuKQh41nsqIsFFotme09vm89S2ql0rRwcQa\+IMjQhog1L1RyJptwd4nlpvRpc9JnDgoCXSdo5L0MRXfi4yJlvdTHgD7fY24\+L2OUvolBu0OShwIxcWY7o7EUYyOKfFAvWYZmbjWB98iqcLBRhbl0wDdcNpMw8K1xvIcb8r919jfOE81f4kkE/vKcqHayO3QM9nyHXKvPLJ3c6uzrm9Q90Cr/rox9UJNAjmGL5qm38gp2qSSSC4D3VZ2ttqoJ5w8l5Dekh9v6WtV49Of2cBYPGnyVBPga8wj39nHZsuURZ7JjfPPjw0v6HYE3i2JQAV9TQLQhnGz8qorlJuuggeDb0IAzusSBbK00k3goEQ4SNNuzWAptxJ3V6owygdujKFnmYOmFdFf7cSy0/Gw4gkv7rUOjlEj0ZtwCRoNSdcOXvMrxbFPGz5vDLG1JwAEvhWJxekg6\+88zUaI1Y5U13\+SVnytBz4zOdB7r4Ys89u17eg7V4zRshoN8Gkeg\+xYOA7zPSU2hkDH/70uBrnrOZJ3uSSGyv4yh9FzK\+5XHraWOV\+TNRDQH9kyovblIG8eQ==} }
end
