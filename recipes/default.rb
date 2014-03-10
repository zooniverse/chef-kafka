#
# Cookbook Name:: kafka
# Recipe:: default
#
# Copyright (C) 2014 YOUR_NAME
# 
# All rights reserved - Do Not Redistribute

include_recipe 'java'

if node['kafka']['zookeeper_hosts'] == ['localhost:2181']
  include_recipe "kafka::zookeeper"
end

kafka_name = "kafka-#{node['kafka']['version']}"

group node['kafka']['group'] do
  action :create
end

user node['kafka']['user'] do
  gid node['kafka']['group']
end

remote_file ::File.join(Chef::Config[:file_cache_path], "#{kafka_name}-src.tgz") do
  action :create
  owner 'root'
  mode '0644'
  source node['kafka']['src_url']
end

directory node['kafka']['install_directory'] do
  owner node['kafka']['user']
  mode '0755'
end

unless ::File.exist?("#{node['kafka']['install_directory']}/#{kafka_name}")
  execute 'install and build kafka' do
    cwd Chef::Config[:file_cache_path]
    command """
      tar -zxf #{kafka_name}-src.tgz && \
      mv #{kafka_name}-src/ #{node['kafka']['install_directory']}/#{kafka_name} && \
      cd #{node['kafka']['install_directory']}/#{kafka_name} && \
      ./sbt update && \
      ./sbt package && \
      ./sbt assembly-package-dependency && \
      chown -R #{node['kafka']['user']}:#{node['kafka']['group']} .
    """
  end
end

node['kafka']['number_of_brokers'].times do |n|
  vars = {
    n: n,
    user: node['kafka']['user'],
    group: node['kafka']['group'],
    install_directory: node['kafka']['install_directory'],
    version: node['kafka']['version'],
    local_zoo: node['kafka']['zookeeper_hosts'].first == 'localhost:2181',
    zookeepers: node['kafka']['zookeeper_hosts'].join(','),
    hostname: node['kafka']['hostname']
  }

  template "#{node['kafka']['install_directory']}/#{kafka_name}/config/server-#{n}.properties" do
    source "server.properties.erb"
    owner node['kafka']['user']
    group node['kafka']['group']
    mode "0755"
    variables vars
    action :create
  end

  template "/etc/init/kafka-#{n}.conf" do
    source "kafka.upstart.conf.erb"
    owner "root"
    group "root"
    variables vars
    mode "0644"
  end

  directory "/tmp/kafka-#{n}/" do
    owner node['kafka']['user']
    group node['kafka']['group']
    mode '0755'
  end

  if node['kafka']['devices']
    dev = node['kafka']['devices'][n]

    execute "mkfs" do
      command "mkfs -t ext4 #{dev}"
      not_if "grep -qs /tmp/kafka-#{n} /proc/mounts"
    end

    mount "/tmp/kafka-#{n}" do
      device dev
      fstype "ext4"
      action [:mount, :enable]
    end
  end

  service "kafka-#{n}" do
    provider Chef::Provider::Service::Upstart
    supports start: true, restart: true
    if node['kafka']['zookeeper_hosts'] == ['localhost:2181']
      action [:enable, :start]
    else
      action :enable
    end
  end
end
