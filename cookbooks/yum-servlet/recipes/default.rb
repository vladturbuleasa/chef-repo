#
# Cookbook Name:: servlet
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

cookbook_file "/etc/yum.conf" do
	source "yum.conf"
	mode "0644"
end
