require 'serverspec'

set :backend, :exec

describe package('rdiff-backup') do
  it { should be_installed }
end

describe user('rdiff-backup-client') do
  it { should exist }
  it { should have_login_shell('/bin/bash') }
end
