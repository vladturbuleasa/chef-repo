#
# Cookbook Name:: haproxy
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

package 'haproxy' do
	action :install
end

service 'haproxy' do
	action [ :enable, :start ]
end
