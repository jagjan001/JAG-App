services = ['consul']

# tests run by packer

include_controls 'packer-common'

control 'group_and_user' do
  describe group('consul') do
    it { should exist }
  end
  describe user('consul') do
    it { should exist }
    its('group') { should eq 'consul' }
  end
end

control 'services_installed_enabled' do
  services.each do |service|
    describe systemd_service("#{service}") do
      it { should be_installed }
      it { should be_enabled }
    end
  end
end

control 'consul_unit_file' do
  describe file('/usr/lib/systemd/system/consul.service') do
      # its('owner') { should eq 'root' }
      its('mode') { should cmp '0644' }
  end
end

control 'consul_binary' do
  describe file('/usr/bin/consul') do
      # its('owner') { should eq 'root' }
      # its('group') { should eq 'consul' }
      its('mode') { should cmp '0755' }
  end
end

control 'consul_config' do
  describe directory('/opt/consul') do
    # its('owner') { should eq 'consul' }
    # its('group') { should eq 'consul' }
    its('mode') { should cmp '0755' }
  end
  describe file('/opt/consul/consul.hcl') do
    # its('owner') { should eq 'consul' }
    # its('group') { should eq 'consul' }
    its('mode') { should cmp '0640' }
  end
end

control 'no_consul_node_id' do
  describe file('/data/consul/node-id') do
      it { should_not exist }
  end
end