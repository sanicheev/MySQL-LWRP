MySQL LWRP
=============
Creates DB test1. Settings are read from /root/.my.cnf file:
```text
mysql_database "test1"
```

Creates User test1 at host 10.10.10.10, with pass : test123 and grants all privileges with grant option:
```text
mysql_user "test1" do
  host "10.10.10.10"
  pass "test123"
  grant_option true
  privilege [all]
end
```

Also this LWRP does some general security setups.
Like: removing test databases, removing users with no passwords, and remove anonymous user.
  
  
