actions :configure
default_action :configure

# These would conflict if shared between instances and so don't make sense
# to inherit from attributes
attribute :name,
  kind_of: String,
  required: true,
  name_attribute: true
attribute :port,
  kind_of: Fixnum
attribute :proxy_port,
  kind_of: Fixnum
attribute :proxy_name,
  kind_of: String
attribute :secure,
  kind_of: [TrueClass, FalseClass]
attribute :client_auth,
  kind_of: [TrueClass, FalseClass]
attribute :scheme,
  kind_of: String
attribute :uriencoding,
  kind_of: String
attribute :ssl_port,
  kind_of: Fixnum
attribute :ssl_proxy_port,
  kind_of: Fixnum
attribute :ajp_port,
  kind_of: Fixnum
attribute :ajp_listen_ip,
  kind_of: String
attribute :shutdown_port,
  kind_of: Fixnum,
  required: true
attribute :ajp_redirect_port,
  kind_of: Fixnum

# The rest will inherit from node attributes
attribute :config_dir,
  kind_of: String
attribute :log_dir,
  kind_of: String
attribute :work_dir,
  kind_of: String
attribute :context_dir,
  kind_of: String
attribute :webapp_dir,
  kind_of: String

attribute :catalina_options,
  kind_of: String
attribute :java_options,
  kind_of: String
attribute :use_security_manager,
  kind_of: [TrueClass, FalseClass]
attribute :authbind,
  kind_of: String,
  equal_to: %w(yes no)
attribute :max_threads,
  kind_of: Fixnum
attribute :ssl_max_threads,
  kind_of: Fixnum
attribute :ssl_cert_file,
  kind_of: String
attribute :ssl_key_file,
  kind_of: String
attribute :ssl_chain_files,
  kind_of: Array
attribute :keystore_file,
  kind_of: String
attribute :keystore_type,
  kind_of: String,
  equal_to: %w(jks pkcs11 pkcs12)
attribute :truststore_file,
  kind_of: String
attribute :truststore_type,
  kind_of: String,
  equal_to: %w(jks pkcs11 pkcs12)
attribute :certificate_dn,
  kind_of: String
attribute :loglevel,
  kind_of: String
attribute :tomcat_auth,
  kind_of: String,
  equal_to: %w(true false)

attribute :user,
  kind_of: String
attribute :group,
  kind_of: String
attribute :home,
  kind_of: String
attribute :base,
  kind_of: String
attribute :tmp_dir,
  kind_of: String
attribute :lib_dir,
  kind_of: String
attribute :endorsed_dir,
  kind_of: String
