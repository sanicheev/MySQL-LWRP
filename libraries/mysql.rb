#Main Classes
class MySQLUser

  def connection(mconf, connection=ConnectionInitializer)
    @connection ||= connection.open(mconf)
  end

  def close_connection
    @connection.close
  end

  def initialize(user, pass, host, db, table, grant_option, privilege, mconf)
    @user = user
    @pass = pass
    @host = host
    @db = db
    @table = table
    @grant_option = grant_option
    @privilege = privilege
    @mconf = mconf
    connection(mconf)
  end

  def create_root_user(user=UserHelper)
    if !File.exists?(@mconf)
      user.create(@user, @pass, @host, @db, @table, @grant_option, @privilege, @connection)
      user.clean(@host, @connection)
      Chef::Log.info("Creating connection configuration file at #{@mconf}")
      File.open(@mconf, "w"){ |f| f.write("\[client\]\nuser=root\nhost=#{@host}\npassword=#{@pass}")}
      File.chmod(0600, @mconf)
    elsif File.read(@mconf).include?(@pass)
      Chef::Log.info("Users #{@user} password is fresh.Nothing to do here")
    else
      user.update_password(@user, @pass, @host, @connection)
      Chef::Log.info("Updating connection configuration file at #{@mconf}")
      File.open(@mconf, "w"){ |f| f.write("\[client\]\nuser=root\nhost=#{@host}\npassword=#{@pass}")}
    end
    close_connection
  end

  def create_regular_user(user=UserHelper)
    if !user.u_exists(@user, @host, @connection)
      Chef::Log.info("User #{@user} at host #{@host} do not exists.Creating one.")
      user.create(@user, @pass, @host, @db, @table, @grant_option, @privilege, @connection)
    else
      user.update_password(@user, @pass, @host, @connection)
    end
    close_connection
  end

  def delete_user(user=UserHelper)
    if !user.u_exists(@user, @host, @connection)
      Chef::Log.info("User #{@user} do not exists.Nothing to do")
    else
      user.drop_user(@user, @host, @connection)
      close_connection
    end
  end

end

class MySQLDatabase  

  def connection(mconf, connection=ConnectionInitializer)
    @connection ||= connection.open(mconf)
  end

  def close_connection
    Chef::Log.info("Closing MySQL connection")
    @connection.close
  end

  def initialize(db, mconf)
    @db = db
    @mconf = mconf
    connection(@mconf)
  end

  def create_database(database=DBHelper)
    if database.db_exists(@db, @connection)
      Chef::Log.info("Database #{@db} exists.Nothing to do")
    else
      database.create(@db, @connection)
    end
    close_connection
  end

end

#Action Classes

class UserHelper

  def self.create(user, pass, host, db, table, grant_option, privilege, connection, execute_query=MySQLQuery) 
    Chef::Log.info("Processing creation of user #{user} at host #{host}")
    execute_query.myquery("create user '#{user}'@'#{host}' identified by '#{pass}'", connection)
    if grant_option
      execute_query.myquery("grant #{privilege.join(', ')} on #{db}.#{table} to '#{user}'@'#{host}' with grant option", connection)
    else
      execute_query.myquery("grant #{privilege.join(', ')} on #{db}.#{table} to '#{user}'@'#{host}'", connection)
    end
    execute_query.flush(connection)
  end

  def self.clean(host, connection, execute_query=MySQLQuery)
    Chef::Log.info("Performing initial MySQL cleanup")
    execute_query.myquery("delete from mysql.user where User=''", connection)
    execute_query.myquery("delete from mysql.user where User='root' AND Host!='#{host}'", connection)
    execute_query.myquery("delete from mysql.db where Db='test' OR Db='test\_%'", connection)
    if DBHelper.db_exists("test", connection)
      execute_query.myquery("drop database test", connection)
    end
    execute_query.flush(connection)
  end

  def self.update_password(user, pass, host, connection, execute_query=MySQLQuery)
    Chef::Log.info("Updating password for user #{user} at host #{host}")
    execute_query.myquery("set password for '#{user}'@'#{host}' = PASSWORD('#{pass}')", connection)
    execute_query.flush(connection)
  end

  def self.u_exists(user, host, connection, execute_query=MySQLQuery)
    Chef::Log.info("Checking if user #{user} at host #{host} exists")
    user_exists = execute_query.myquery("select exists(select 1 from mysql.user where User='#{user}' and Host='#{host}')", connection)
    user_exists.first.values.include?(1)
  end

  def self.drop_user(user, host, connection, execute_query=MySQLQuery)
    Chef::Log.info("Processing deletion of user #{user} at host #{host}")
    execute_query.myquery("revoke all privileges, grant option from '#{user}'@'#{host}'", connection)
    execute_query.myquery("drop user '#{user}'@'#{host}'", connection)
    execute_query.flush(connection)
  end

end

class DBHelper

  def self.create(database, connection, execute_query=MySQLQuery)
    Chef::Log.info("Creating database #{database}")
    execute_query.myquery("create database #{database}", connection)
  end

  def self.db_exists(database, connection, execute_query=MySQLQuery)
     Chef::Log.info("Checking if database #{database} exists")
     db_exists = execute_query.myquery("select exists(select 1 from information_schema.schemata where schema_name = '#{database}')", connection)
     db_exists.first.values.include?(1)
  end
end


class MySQLQuery

  def self.myquery(myquery, connection)
    connection.query(myquery)
  end
  def self.flush(myquery="flush privileges", connection)
    Chef::Log.info("Flushing privileges")
    connection.query(myquery)
  end

end

class ConnectionInitializer
  
  def self.fetch_connection_settings(mconf)
    if !File.exists?(mconf)
      Chef::Log.info("Using empty connection options")
      @connect_host = nil
      @connect_password = nil
    else
      Chef::Log.info("Using connection options from #{mconf}")
      @connect_password = File.open(mconf).grep(/password=(.*)/){$1}.first
      @connect_host = File.open(mconf).grep(/host=(.*)/){$1}.first
    end
  end

  def self.open(mconf)
    require 'mysql2'
    fetch_connection_settings(mconf)
    Chef::Log.info("Opening DB connection")
    if !defined?(connection)
      connection = Mysql2::Client.new(:host => @connect_host, :username => "root", :socket => "/var/lib/mysql/mysql.sock", :password => @connect_password)
    else
      connection
    end
  end

end
