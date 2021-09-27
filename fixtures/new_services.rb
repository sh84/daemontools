# coding: utf-8
run_command :command1, "cd /home/user/dir && command1 :task"
run_command :command2, "cd /home/user/dir && command2 :task"
run_command :command3, "cd /home/user/dir && command3 :task"
change_user_command 'setsid sudo -u'

service :service1, :roles => [:role_without_changes] do
  command1 "service1.sh"
end

service :service_non_modified, :roles => [:role_with_modifies] do
  command2 "service_non_modified.sh"
end

service :service2, :roles => [:role_with_deleted] do
  command3 "bin/service3"
end

service :service3, :roles => [:role_without_changes] do
  command3 "service3 -flag"
end

service :service_modified, :roles => [:role_with_modifies] do
  command2 "task/SERVICE_MODIFIED.sh arg1"
end

service :service_new_1, :roles => [:role_with_modifies] do
  command1 "service_new_1 arg1"
end

service :service_new_2, :roles => [:new_role] do
  command1 "service_new_2 arg1"
end

service :service4, :roles => [:role_renamed] do
  command3 "script/service4 argument1"
end
