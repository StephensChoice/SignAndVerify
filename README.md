# SignAndVerify
Sign Chef cookbooks on workstation and verify cookbooks on node

## On Chef Workstation
brew install coreutils workstation

/opt/chef-workstation/embedded/bin/gem install gpgme

## On Chef Node
apt install build-essential

/opt/chef/embedded/bin/gem install gpgme 
