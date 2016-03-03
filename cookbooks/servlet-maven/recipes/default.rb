#
# Cookbook Name:: servlet
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
include_recipe "tomcat"
include_recipe "yum-servlet"

execute "yum clean" do
	command "yum clean all"
end

package 'ServletMaven' do
        action :install
end

