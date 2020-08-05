control 'server' do
  describe command('su - rdiff-backup-server -c "/home/rdiff-backup-server/scripts/192.168.60.11/_help_me_obiwan"') do
    its('exit_status') { should eq 0 }
  end

  describe file('/you/are/my/only/hope/r2d2') do
    it { should exist }
    its('content') { should match 'test' }
  end
end
