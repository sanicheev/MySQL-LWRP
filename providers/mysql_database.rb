def whyrun_supported?
	true
end

use_inline_resources

mconf = "/root/.my.cnf"

action :create_database do
  Chef::Log.info("Processing database #{new_resource.db}")
  create_database = MySQLDatabase.new(new_resource.db, mconf)
  create_database.create_database

  new_resource.updated_by_last_action(true)
end

