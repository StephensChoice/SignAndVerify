# SignAndVerify
Sign Chef cookbooks on workstation and verify cookbooks on node

## On Chef Workstation

```
brew install coreutils workstation
/opt/chef-workstation/embedded/bin/gem install gpgme
```

## On Chef Node

```bash
apt install build-essential
/opt/chef/embedded/bin/gem install gpgme 
```

```ruby
log_level        :info
log_location     :syslog
chef_server_url  "https://chef.internet.fo/organizations/ft"
validation_client_name "ft-validator"
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
