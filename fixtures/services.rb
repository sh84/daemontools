# coding: utf-8
run_command :command1, "cd /home/user/dir && command1 :task"
run_command :command2, "cd /home/user/dir && command2 :task"
run_command :command3, "cd /home/user/dir && command3 :task"
change_user_command 'setsid sudo -u'
delete_command ''

service :service1, :roles => [:role1] do
  command1 "service1.sh"
end

service :service2, :roles => [:role1] do
  command2 "service2.sh"
end

service :service3, :roles => [:role1] do
  command3 "bin/service3"
end

service :service4, :roles => [:role2] do
  command1 "script/service4 argument1 argument2"
end

service :service5, :roles => [:role2] do
  command3 "service5 -flag"
end

service :service6, :roles => [:role2] do
  command2 "task/service6.sh arg1 arg2"
end