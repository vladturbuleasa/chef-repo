action :configure do # ~FC059
  base_instance = node['tomcat']['base_instance']

  # Set defaults for resource attributes from node attributes. We can't do
  # this in the resource declaration because node isn't populated yet when
  # that runs
  [:catalina_options, :java_options, :use_security_manager, :authbind,
   :max_threads, :uriencoding, :ssl_max_threads, :ssl_cert_file, :ssl_key_file,
   :ssl_chain_files, :keystore_file, :keystore_type, :truststore_file,
   :truststore_type, :certificate_dn, :loglevel, :tomcat_auth, :client_auth,
   :user, :group, :tmp_dir, :lib_dir, :endorsed_dir].each do |attr|
    unless new_resource.instance_variable_get("@#{attr}")
      new_resource.instance_variable_set("@#{attr}", node['tomcat'][attr])
    end
  end

  if new_resource.name == 'base'
    instance = base_instance

    # If they weren't set explicitly, set these paths to the default
    [:base, :home, :config_dir, :log_dir, :work_dir, :context_dir,
     :webapp_dir].each do |attr|
      unless new_resource.instance_variable_get("@#{attr}")
        new_resource.instance_variable_set("@#{attr}", node['tomcat'][attr])
      end
    end
  else
    # Use a unique name for this instance
    instance = "#{base_instance}-#{new_resource.name}"

    # If they weren't set explicitly, set these paths to the default with
    # the base instance name replaced with our own
    [:base, :home, :config_dir, :log_dir, :work_dir, :context_dir,
     :webapp_dir].each do |attr|
      if !new_resource.instance_variable_get("@#{attr}") && node['tomcat'][attr]
        new = node['tomcat'][attr].sub(base_instance, instance)
        new_resource.instance_variable_set("@#{attr}", new)
      end
    end

    # Create the directories, since the OS package wouldn't have
    [:base, :config_dir, :context_dir].each do |attr|
      directory new_resource.instance_variable_get("@#{attr}") do
        mode '0755'
        recursive true
      end
    end
    [:log_dir, :work_dir, :webapp_dir].each do |attr|
      directory new_resource.instance_variable_get("@#{attr}") do
        mode '0755'
        recursive true
        user new_resource.user
        group new_resource.group
      end
    end

    # Don't make a separate home, just link to base
    link new_resource.home do # ~FC021
      to new_resource.base
      only_if { new_resource.home != new_resource.base }
    end

    # config_dir needs symlinks to the files we're not going to create
    %w(catalina.policy catalina.properties context.xml
       tomcat-users.xml web.xml).each do |file|
      link "#{new_resource.config_dir}/#{file}" do
        to "#{node['tomcat']['config_dir']}/#{file}"
      end
    end

    # The base also needs a bunch of to symlinks inside it
    %w(bin lib).each do |dir|
      link "#{new_resource.base}/#{dir}" do
        to "#{node['tomcat']['base']}/#{dir}"
      end
    end
    { 'conf' => 'config_dir', 'logs' => 'log_dir', 'temp' => 'tmp_dir',
      'work' => 'work_dir', 'webapps' => 'webapp_dir' }.each do |name, attr|
      link "#{new_resource.base}/#{name}" do
        to new_resource.instance_variable_get("@#{attr}")
      end
    end

    # Make a copy of the init script for this instance
    if node['init_package'] == 'systemd' && !platform_family?('debian')
      template "/usr/lib/systemd/system/#{instance}.service" do
        source 'tomcat.service.erb'
        variables(
          instance: instance,
          user: new_resource.user,
          group: new_resource.group
        )
        owner 'root'
        group 'root'
        mode '0644'
      end
    else
      execute "/etc/init.d/#{instance}" do
        command <<-EOH
          cp /etc/init.d/#{base_instance} /etc/init.d/#{instance}
          perl -i -pe 's/#{base_instance}/#{instance}/g' /etc/init.d/#{instance}
        EOH
      end
    end
  end

  # Even for the base instance, the OS package may not make this directory
  directory new_resource.endorsed_dir do
    mode '0755'
    recursive true
  end

  unless new_resource.truststore_file.nil?
    java_options = new_resource.java_options.to_s
    java_options << " -Djavax.net.ssl.trustStore=#{new_resource.config_dir}/#{new_resource.truststore_file}"
    java_options << " -Djavax.net.ssl.trustStorePassword=#{new_resource.truststore_password}"
    new_resource.java_options = java_options
  end

  case node['platform_family']
  when 'rhel', 'fedora'
    template "/etc/sysconfig/#{instance}" do
      source 'sysconfig_tomcat6.erb'
      variables(
        user: new_resource.user,
        home: new_resource.home,
        base: new_resource.base,
        java_options: new_resource.java_options,
        use_security_manager: new_resource.use_security_manager,
        tmp_dir: new_resource.tmp_dir,
        catalina_options: new_resource.catalina_options,
        endorsed_dir: new_resource.endorsed_dir
      )
      owner 'root'
      group 'root'
      mode '0644'
      notifies :restart, "service[#{instance}]"
    end
  when 'suse'
    template '/etc/tomcat/tomcat.conf' do
      source 'sysconfig_tomcat7.erb'
      variables(
        user: new_resource.user,
        home: new_resource.home,
        base: new_resource.base,
        java_options: new_resource.java_options,
        use_security_manager: new_resource.use_security_manager,
        tmp_dir: new_resource.tmp_dir,
        catalina_options: new_resource.catalina_options,
        endorsed_dir: new_resource.endorsed_dir
      )
      owner 'root'
      group 'root'
      mode '0644'
      notifies :restart, "service[#{instance}]"
    end
  when 'smartos'
    # SmartOS doesn't support multiple instances
    template "#{new_resource.base}/bin/setenv.sh" do
      source 'setenv.sh.erb'
      owner 'root'
      group 'root'
      mode '0644'
      notifies :restart, "service[#{instance}]"
    end
  else
    template "/etc/default/#{instance}" do
      source 'default_tomcat.erb'
      variables(
        user: new_resource.user,
        group: new_resource.group,
        home: new_resource.home,
        base: new_resource.base,
        java_options: new_resource.java_options,
        use_security_manager: new_resource.use_security_manager,
        tmp_dir: new_resource.tmp_dir,
        authbind: new_resource.authbind,
        catalina_options: new_resource.catalina_options,
        endorsed_dir: new_resource.endorsed_dir
      )
      owner 'root'
      group 'root'
      mode '0644'
      notifies :restart, "service[#{instance}]"
    end
  end

  template "#{new_resource.config_dir}/server.xml" do
    source 'server.xml.erb'
    variables(
      port: new_resource.port,
      proxy_port: new_resource.proxy_port,
      proxy_name: new_resource.proxy_name,
      secure: new_resource.secure,
      scheme: new_resource.scheme,
      uriencoding: new_resource.uriencoding,
      ssl_port: new_resource.ssl_port,
      ssl_proxy_port: new_resource.ssl_proxy_port,
      ajp_port: new_resource.ajp_port,
      ajp_redirect_port: new_resource.ajp_redirect_port,
      ajp_listen_ip: new_resource.ajp_listen_ip,
      shutdown_port: new_resource.shutdown_port,
      max_threads: new_resource.max_threads,
      ssl_max_threads: new_resource.ssl_max_threads,
      keystore_file: new_resource.keystore_file,
      keystore_type: new_resource.keystore_type,
      tomcat_auth: new_resource.tomcat_auth,
      client_auth: new_resource.client_auth,
      config_dir: new_resource.config_dir
    )
    owner 'root'
    group 'root'
    mode '0644'
    notifies :restart, "service[#{instance}]"
  end

  template "#{new_resource.config_dir}/logging.properties" do
    source 'logging.properties.erb'
    owner 'root'
    group 'root'
    mode '0644'
    notifies :restart, "service[#{instance}]"
  end

  if new_resource.ssl_cert_file.nil?
    execute 'Create Tomcat SSL certificate' do
      group new_resource.group
      command <<-EOH
        #{node['tomcat']['keytool']} \
         -genkey \
         -keystore "#{new_resource.config_dir}/#{new_resource.keystore_file}" \
         -storepass "#{node['tomcat']['keystore_password']}" \
         -keypass "#{node['tomcat']['keystore_password']}" \
         -dname "#{node['tomcat']['certificate_dn']}" \
         -keyalg "RSA"
      EOH
      umask 0007
      creates "#{new_resource.config_dir}/#{new_resource.keystore_file}"
      action :run
      notifies :restart, "service[#{instance}]"
    end
  else
    script "create_keystore-#{instance}" do
      interpreter 'bash'
      action :nothing
      cwd new_resource.config_dir
      code <<-EOH
        cat #{new_resource.ssl_chain_files.join(' ')} > cacerts.pem
        openssl pkcs12 -export \
         -inkey #{new_resource.ssl_key_file} \
         -in #{new_resource.ssl_cert_file} \
         -chain \
         -CAfile cacerts.pem \
         -password pass:#{node['tomcat']['keystore_password']} \
         -out #{new_resource.keystore_file}
      EOH
      notifies :restart, "service[#{instance}]"
    end

    cookbook_file "#{new_resource.config_dir}/#{new_resource.ssl_cert_file}" do
      mode '0644'
      notifies :run, "script[create_keystore-#{instance}]"
    end

    cookbook_file "#{new_resource.config_dir}/#{new_resource.ssl_key_file}" do
      mode '0644'
      notifies :run, "script[create_keystore-#{instance}]"
    end

    new_resource.ssl_chain_files.each do |cert|
      cookbook_file "#{new_resource.config_dir}/#{cert}" do
        mode '0644'
        notifies :run, "script[create_keystore-#{instance}]"
      end
    end
  end

  cookbook_file "#{new_resource.config_dir}/#{new_resource.truststore_file}" do
    mode '0644'
    not_if { new_resource.truststore_file.nil? }
  end

  new_resource.updated_by_last_action(true)
end
