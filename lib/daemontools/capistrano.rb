Capistrano::Configuration.instance(:must_exist).load do
  _cset(:daemontools_roles)      { :app }
  _cset(:daemontools_options)    { {:roles => fetch(:daemontools_roles)} }
  #_cset(:whenever_command)      { "whenever" }
  #_cset(:whenever_identifier)   { fetch :application }
  #_cset(:whenever_environment)  { fetch :rails_env, "production" }
  #_cset(:whenever_variables)    { "environment=#{fetch :whenever_environment}" }
  #_cset(:whenever_update_flags) { "--update-crontab #{fetch :whenever_identifier} --set #{fetch :whenever_variables}" }
  #_cset(:whenever_clear_flags)  { "--clear-crontab #{fetch :whenever_identifier}" }

  namespace :daemontools do
    desc "Update daemontools services using services.rb"
    task :update do
      args = {
        :command => fetch(:whenever_command),
        :flags => fetch(:whenever_update_flags),
        :path => fetch(:latest_release)
      }
      
      servers = find_servers(fetch(:daemontools_options))
      
      if servers.any?
        if task_call_frames[0].task.fully_qualified_name == 'deploy:rollback'
          path = fetch(:previous_release)
          puts "rollback 1"
        else
          path = fetch(:release_path)
          daemontools_roles = Array(fetch(:daemontools_options)[:roles])
          servers = servers.inject({}) {|map, server| map[server] = role_names_for_host(server) & daemontools_roles; map }
          
          servers.each do |server, roles|
            roles_arg = roles.empty? ? "" : " --roles #{roles.join(',')}"
            command = "cd #{path} && #{args[:command]} #{args[:flags]}#{roles_arg}"
            run command, fetch(:whenever_options).merge(:hosts => server)
          end
        end
        
        on_rollback do
          puts "rollback 1"
        end
      end
    end
  end
  
  before "deploy:finalize_update", "daemontools:update"
  after "deploy:rollback", "daemontools:update"
end
