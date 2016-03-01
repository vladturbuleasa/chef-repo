#
# Cookbook Name:: servlet
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "tomcat"

cookbook_file "/etc/yum.conf" do
	source "yum.conf"
	mode "0644"
end

execute "yum clean" do
	command "yum clean all"
end

execute "yum update" do
	command "yum -y update"
end

package 'ServletGradle' do
        action :install
end

