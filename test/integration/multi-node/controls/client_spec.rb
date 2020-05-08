control 'client' do
  describe file('/help/me/obiwan/r2d2') do
    its('content') { should match 'test' }
  end
end
