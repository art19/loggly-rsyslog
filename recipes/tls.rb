#
# Cookbook Name:: loggly
# Recipe:: tls
#
# Copyright (C) 2014 Matt Veitas
#
# All rights reserved - Do Not Redistribute
#

package 'rsyslog-gnutls' do
  version '8.26.0-1.el6'

  action :install
end

cert_path = node['loggly']['tls']['cert_path']
rsyslog_group = platform_family?('rhel') ? 'adm' : 'syslog'

directory cert_path do
  owner 'root'
  group rsyslog_group
  mode '0755'
  action :create
  recursive true
end

loggly_crt_path = "#{Chef::Config['file_cache_path']}/loggly.com.crt"
sf_bundle_path = "#{Chef::Config['file_cache_path']}/sf_bundle.crt"

remote_file 'download loggly.com cert' do
  owner 'root'
  group 'root'
  mode '0644'
  path loggly_crt_path
  source node['loggly']['tls']['cert_url']
  checksum node['loggly']['tls']['cert_checksum']
end

remote_file 'download intermediate cert' do
  owner 'root'
  group 'root'
  mode '0644'
  path sf_bundle_path
  source node['loggly']['tls']['intermediate_cert_url']
  checksum node['loggly']['tls']['intermediate_cert_checksum']
end

bash 'bundle certificate' do
  user 'root'
  cwd cert_path
  code <<-EOH
    cat {#{sf_bundle_path},#{loggly_crt_path}} > loggly_full.crt
  EOH
  not_if { ::File.exist?("#{node['loggly']['tls']['cert_path']}/loggly_full.crt") }
end
