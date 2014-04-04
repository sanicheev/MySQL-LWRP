MySQL LWRP
=============
Creates DB test1. Settings are read from /root/.my.cnf file:
mysql_database "test1" do

Creates User test1 at host 10.10.10.10, with pass : test123 and grants all privileges with grant option:
mysql_user "test1" do
  host "10.10.10.10"
  pass "test123"
  grant_option true
  privilege [all]
end
  
  
  
