actions :create_user, :delete_user

default_action :create_user

attribute :user, :kind_of => String, :name_attribute => true, :required => true
attribute :host, :kind_of => [Integer, String], :default => "localhost"
attribute :pass, :kind_of => String, :required => true, :default => nil
attribute :grant_option, :kind_of => [TrueClass, FalseClass], :default => false
attribute :privilege, :kind_of => Array, :required => true, :default => nil
attribute :table, :kind_of => String, :default => "*"
attribute :db, :kind_of => String, :default => "*"
