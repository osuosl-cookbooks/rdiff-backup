node.override['rdiff-backup']['client']['ssh_keys'] = ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzDoq1UGRj412cNrL2Q3gNZkldvIHeb6HnuDcUbkFPQPdAzdA4azDKBLam6S/oe6nJr3BtQMpracmReBVlzl/Jjn/5GYoCsDZm5WlaxYMASPnXTdEuKQh41nsqIsFFotme09vm89S2ql0rRwcQa+IMjQhog1L1RyJptwd4nlpvRpc9JnDgoCXSdo5L0MRXfi4yJlvdTHgD7fY24+L2OUvolBu0OShwIxcWY7o7EUYyOKfFAvWYZmbjWB98iqcLBRhbl0wDdcNpMw8K1xvIcb8r919jfOE81f4kkE/vKcqHayO3QM9nyHXKvPLJ3c6uzrm9Q90Cr/rox9UJNAjmGL5qm38gp2qSSSC4D3VZ2ttqoJ5w8l5Dekh9v6WtV49Of2cBYPGnyVBPga8wj39nHZsuURZ7JjfPPjw0v6HYE3i2JQAV9TQLQhnGz8qorlJuuggeDb0IAzusSBbK00k3goEQ4SNNuzWAptxJ3V6owygdujKFnmYOmFdFf7cSy0/Gw4gkv7rUOjlEj0ZtwCRoNSdcOXvMrxbFPGz5vDLG1JwAEvhWJxekg6+88zUaI1Y5U13+SVnytBz4zOdB7r4Ys89u17eg7V4zRshoN8Gkeg+xYOA7zPSU2hkDH/70uBrnrOZJ3uSSGyv4yh9FzK+5XHraWOV+TNRDQH9kyovblIG8eQ==']

include_recipe 'rdiff-backup::client'

directory '/help/me/obiwan' do
  mode '0755'
  recursive true
end

file '/help/me/obiwan/r2d2' do
  content 'test'
  mode '0644'
end
