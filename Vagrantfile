require 'yaml'
require 'fileutils'

required_plugins = %w( vagrant-hostmanager vagrant-vbguest )
required_plugins.each do |plugin|
    exec "vagrant plugin install #{plugin}" unless Vagrant.has_plugin? plugin
end

domains = {
  main:    'ap-office.test',
  design:  'design.ap-office.test',
  hotels:  'happy-hotels.test',
  svet:    'svet.ap-office.test',
  test:    'test.ap-office.test',
  vera:    'vera-italia.test',
}

config = {
  local: './vagrant/config/vagrant-local.yml',
  example: './vagrant/config/vagrant-local.example.yml'
}

# copy config from example if local config not exists
FileUtils.cp config[:example], config[:local] unless File.exist?(config[:local])
# read config
options = YAML.load_file config[:local]

# check github token
if options['github_token'].nil? || options['github_token'].to_s.length != 40
  puts "You must place REAL GitHub token into configuration:\n/ap-office/vagrant/config/vagrant-local.yml"
  exit
end

# vagrant configurate
Vagrant.configure('2') do |config|
  # select the box
  config.vm.box = 'centos/7'

  # should we ask about box updates?
  config.vm.box_check_update = options['box_check_update']
  
  config.vm.provider 'virtualbox' do |vb|
	# machine cpus count
	vb.cpus = options['cpus']
    # machine memory size
    vb.memory = options['memory']
	# machine name (for VirtualBox UI)
    vb.name = options['machine_name']
  end
  
  # machine name (for vagrant console)
  config.vm.define options['machine_name']
  
  # machine name (for guest machine console)
  config.vm.hostname = options['machine_name']

  # network settings
  config.vm.network 'private_network', ip: options['ip']

  # sync: folder 'ap-office' (host machine) -> folder '/app' (guest machine)
  config.vm.synced_folder './', '/app', owner: 'vagrant', group: 'vagrant', mount_options: ['dmode=755','fmode=644'], type: 'nfs', linux__nfs_options: ['rw','no_subtree_check','all_squash','async']
  
  # disable folder '/vagrant' (guest machine)
  config.vm.synced_folder '.', '/vagrant', disabled: true
  
  # hosts settings (host machine)
  config.vm.provision :hostmanager
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true
  config.hostmanager.aliases = domains.values
  
  # provisioners
  config.vm.provision 'shell', path: './vagrant/provision/once-as-root.sh', args: [options['timezone']]
  config.vm.provision 'shell', path: './vagrant/provision/once-as-vagrant.sh', args: [options['github_token']], privileged: false
  config.vm.provision 'shell', path: './vagrant/provision/always-as-root.sh', run: 'always'

  # post-install message (vagrant console)
  config.vm.post_up_message = "Main URL: http://#{domains[:main]}\nDesign URL: http://#{domains[:design]}\nHotels URL: http://#{domains[:hotels]}\nSvet URL: http://#{domains[:svet]}\nTest URL: http://#{domains[:test]}\nVera-italia URL: http://#{domains[:vera]}"
end
