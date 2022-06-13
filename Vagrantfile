CONFIG_VM_MEMORY_GB = 6

Vagrant.configure('2') do |config|
  config.vm.provider :libvirt do |lv, config|
    lv.memory = CONFIG_VM_MEMORY_GB*1024
    lv.cpus = 4
    lv.cpu_mode = 'host-passthrough'
    lv.nested = false
    lv.keymap = 'pt'
    config.vm.synced_folder '.', '/vagrant', type: 'nfs', nfs_version: '4.2', nfs_udp: false
  end

  config.vm.define :awx do |config|
    config.vm.box = 'ubuntu-20.04-amd64'
    config.vm.hostname = 'awx'
    config.vm.provision :shell, path: 'provision-base.sh'
    config.vm.provision :shell, path: 'provision-helm.sh'
    config.vm.provision :shell, path: 'provision-k0s.sh'
    config.vm.provision :shell, path: 'provision-k0s-k8s.sh'
    config.vm.provision :shell, path: 'provision-buildkit.sh'
    config.vm.provision :shell, path: 'provision-nerdctl.sh'
    config.vm.provision :shell, path: 'provision-awx.sh'
  end
end
