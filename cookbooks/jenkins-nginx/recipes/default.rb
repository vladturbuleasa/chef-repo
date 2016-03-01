#
# Cookbook Name:: nginx
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

package 'epel-release' do
  	action:install
end

package 'nginx' do
	action:install
end

cookbook_file "/usr/share/nginx/html/index.html" do
  source "index.html"
  mode "0644"
end

cookbook_file "/etc/nginx/conf.d/default.conf" do
  source "default.conf"
  mode "0644"
end

remote_directory '/etc/nginx/ssl' do
  source 'ssl'
  mode "0644"
end

service 'nginx' do
	action [ :enable, :start]
end
