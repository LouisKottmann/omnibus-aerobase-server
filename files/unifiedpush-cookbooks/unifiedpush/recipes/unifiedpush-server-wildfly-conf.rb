#
# Copyright:: Copyright (c) 2015
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Default location of install-dir is /opt/unifiedpush/. This path is set during build time.
# DO NOT change this value unless you are building your own Unifiedpush packages

install_dir = node['package']['install-dir']
server_dir = node['unifiedpush']['unifiedpush-server']['dir']
modules_dir = "#{server_dir}/modules/org/postgresql/main"

# These directories do not need to be writable for unifiedpush-server
[
  modules_dir 
].each do |dir_name|
  directory dir_name do
    owner "root"
    group "root"
    mode 0775
    recursive true
  end
end

unifiedpush_vars = node['unifiedpush']['unifiedpush-server'].to_hash
 
# Update configuration 
template "#{server_dir}/bin/standalone.conf" do
  owner "root"
  group "root"
  mode 0755
  source "wildfly-standalone.conf.erb"
  variables(unifiedpush_vars)
end

# Add postgres module
template "#{modules_dir}/module.xml" do
  owner "root"
  group "root"
  mode 0755
  source "wildfly-postgres-module.xml.erb"
end

# Copy postgres JDBC driver
remote_file "Copy postgres driver file" do
  path "#{modules_dir}/postgresql-9.4-1201-jdbc41.jar"
  source "file://#{install_dir}/embedded/apps/unifiedpush/initdb/lib/postgresql-9.4-1201-jdbc41.jar"
  owner "root"
  group node['unifiedpush']['user']['group']
  mode 0755
end

# Include additional config properties for unifiedpush-server in standalone-full.xml
if unifiedpush_vars['server_https']
  unifiedpush_vars = unifiedpush_vars.merge(
    {
      :http_listener_ssl => 'proxy-address-forwarding="true" redirect-socket="proxy-https"',
      :socket_binding_ssl => '<socket-binding name="proxy-https" port="443"/>'
    }
  )
end

# Replace standalone-full.xml with relevant datasource config
template "#{server_dir}/standalone/configuration/standalone-full.xml" do
  owner "root"
  group "root"
  mode 0755
  source "wildfly-standalone-full.xml.erb"
  variables(unifiedpush_vars)
end


# Link apps
link "#{server_dir}/standalone/deployments/unifiedpush-server.war" do
  to "#{install_dir}/embedded/apps/unifiedpush/unifiedpush-server.war"
end

link "#{server_dir}/standalone/deployments/auth-server.war" do
  to "#{install_dir}/embedded/apps/unifiedpush/auth-server.war"
end
