include_recipe 'rdiff-backup::client'

directory '/help/me/obiwan' do
  mode 0755
  recursive true
end

file '/help/me/obiwan/r2d2' do
  content 'test'
  mode 0644
end
