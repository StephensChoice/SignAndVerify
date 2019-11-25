# SignAndVerify
Sign Chef cookbooks on workstation and verify cookbooks on node

## On Chef Workstation

```bash
brew install coreutils workstation
/opt/chef-workstation/embedded/bin/gem install gpgme
```

## On Chef Node

```bash
apt install build-essential
/opt/chef/embedded/bin/gem install gpgme 
```

### /etc/chef/client.rb
```ruby
log_level        :info
log_location     :syslog
chef_server_url  "https://chef.server/organizations/myorg"
validation_client_name "myorg-validator"
file_backup_path   "/var/lib/chef"
file_cache_path    "/var/cache/chef"
pid_file           "/var/run/chef/client.pid"

begin
    require_relative 'SignAndVerify'
    SignAndVerify::VerifyCookbook.new()
rescue LoadError
    Chef::Log.fatal 'Failed to load signature checker.'
    raise
end
