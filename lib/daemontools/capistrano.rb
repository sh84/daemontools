require 'daemontools'

Capistrano::Configuration.instance(:must_exist).load do
  namespace :daemontools do
    desc "Update daemontools services using services.rb"
    task :update do
      builder = Daemontools::Builder.new("#{Dir.pwd}/config/services.rb")

      servers = find_servers.inject({}) do |map, server|
        map[server] = role_names_for_host(server) & builder.all_roles
        map
      end.select {|server, roles| roles.size > 0}

      if servers.any?
        if task_call_frames[0].task.fully_qualified_name == 'deploy:rollback'
          path = fetch(:previous_release)
          puts "rollback 1"
        else
          path = fetch(:release_path)

          servers.each do |server, roles|
            command = "cd #{path} && bundle exec daemontools-gen #{fetch :rails_env, "production"} #{roles.join(',')} #{current_path} #{release_path}"
            run command, :hosts => server
          end
        end

        on_rollback do
          puts "rollback 2"
        end
      end
    end
  end

  after "deploy:create_symlink", "daemontools:update"
  after "deploy:rollback", "daemontools:update"
end
