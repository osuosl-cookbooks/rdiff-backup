control 'all' do
  %w(11 12).each do |suff|
    describe host("192.168.60.#{suff}") do
      it { should be_reachable }
    end
  end

  describe host('192.168.60.14') do
    it { should_not be_reachable }
  end
end
