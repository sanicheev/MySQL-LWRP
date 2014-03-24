def whyrun_supported?
	true
end

use_inline_resources

mconf = "/root/.my.cnf"

action :create_user do
  create_user = MySQLUser.new(new_resource.user, new_resource.pass, new_resource.host, new_resource.db, new_resource.table, new_resource.grant_option, new_resource.privilege, mconf)
  case new_resource.user
  when "root"
    Chef::Log.info("Processing #{new_resource.user} user at host #{new_resource.host}")
    create_user.create_root_user
  else
    Chef::Log.info("Processing #{new_resource.user} user at host #{new_resource.host}")
    create_user.create_regular_user
  end

  new_resource.updated_by_last_action(true)
end

action :delete_user do
  Chef::Log.info("Deleting user #{new_resource.user} at host #{new_resource.host}")
  delete_user = MySQLUser.new(new_resource.user, new_resource.pass, new_resource.host, new_resource.db, new_resource.table, new_resource.grant_option, new_resource.privilege, mconf)
  delete_user.delete_user

  new_resource.updated_by_last_action(true)
end
