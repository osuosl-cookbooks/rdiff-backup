require 'serverspec'

set :backend, :exec

describe package('rdiff-backup') do
  it { should be_installed }
end

describe user('rdiff-backup-client') do
  it { should exist }
  it { should have_home_directory '/home/rdiff-backup-client' }
  it { should have_authorized_key 'no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty,command=\"~/sshwrapper.sh\" ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEA4N4X50nyZ5r1KjW4zAE3AzpgA0N95p26+HZkuxXablRmow60x7kDsCiNb51l28l3KW4fVx+xv80jC03TATlIC5JuUJrCdFrlKis6AzKP3ljmoCEzTyJeaZ80e4u5Ktid6LdBTgA+XSTxBQmam+DKQ8njdZJ7b8ldgz6zkd1bEQdFIDJP1lNUxmoe7ZAI4Mw4u8/UbZTe0Ar4EsbmQzHrHrcOfCaBnvmu9t5NHXjQpllntT7D4NCSeIUm+JbKH0uiaYfmTLboS5KpiLZCSrXOjOULfaXJN2FX1UlA4CK4NilrMmcK2ZGEWjf8dphdhKzy/jytlotqrp67OTEraw32mtoXjgMh+69ZC9Ga//oP1Yjqf5BgjVFMa+Za+w221an7bLosCXktmkNhRHVzpNAH6o8pwjAUx19W0I2T2X6cSbcJKqS1Digbm4bL+sRXD1MO0UR2p47kdAwf/R1wXbwk08/LOOISG6j/CGZjRdb74jnqzb3wqF+RBdhCBWHVJWRzZRpAPexqBQpkXzL/Mm0yE/VOozgGtsts37OxCNiu4DEN16sdu3LdHKfER2MNsQ1YfWRxiV6IAuXi3KLB6inTw76DPoCTo6xO9jd0erlb7MHR/MgpZ7Ck8IEGFFESTCdtwJ2wLV6EpEaEid6icsjMdz4I+qoEFlbynFV4j7iNxwk= rdiff-backup-server@backup3.osuosl.org' }
end

describe file('/home/rdiff-backup-client/sshwrapper.sh') do
  it { should be_file }
  it { should be_executable.by_user('rdiff-backup-client') }
end

describe file('/etc/sudoers') do
  it { should be_file }
  its(:content) { should match '#includedir /etc/sudoers.d' }
end

describe file('/etc/sudoers.d/rdiff-backup-client') do
  it { should be_file }
  its(:content) { should match %r{rdiff-backup-client ALL=\(root\) NOPASSWD:/usr/bin/rdiff-backup --server --restrict-read-only /} }
  its(:content) { should match 'Defaults:rdiff-backup-client !requiretty' }
end
