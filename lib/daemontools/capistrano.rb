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
            command = "cd #{path} && bundle exec daemontools-gen #{fetch :rails_env, "production"} #{roles.join(',')}"
            run command, :hosts => server
          end
        end

        on_rollback do
          puts "rollback 2"
        end
      end
    end

    desc 'Delete unused services during deploying'
    task :delete_services do
      old_services = IO.readlines("#{current_path}/config/services.rb")
      new_services = IO.readlines("#{release_path}/config/services.rb")
      difference = old_services - new_services
      if difference.present?
        service_names = difference.map do |line|
          line = line[/:.*\,/i]
          line.delete(':,') if line.present?
        end
        service_names.delete_if(&:nil?)
        service_scripts = difference.map do |line|
          line = line[/".*"/i]
          line.delete('"') if line.present?
        end
        service_scripts.delete_if(&:nil?)
        pids = {}
        service_scripts.each do |line|
          pids[line] = []
          ps = `ps ax | grep #{line}`.split(/\n/)
          ps.each do |ps_line|
            pids[line] << ps_line.split(' ').first if ps_line.index('grep').nil?
          end
        end
        pids.each do |script_name, script_pids|
          script_pids.each do |pid|
            res = Process.kill('SIGTERM', pid.to_i)
            puts "#{script_name} with #{pid} was successfully finished." if res
            sleep(0.25)
          end
        end
        service_names.each do |name|
          dir = '/var/log/webcaster/' + name
          if File.exist?(dir)
            FileUtils.rm_r(dir)
            puts "Directory #{dir} with logs of the #{name} service was deleted"
          else
            puts "Directory #{dir} with logs of the #{name} service does not exist."
          end
        end
        puts 'Old services was killed and their logs was deleted. Exit'
      else
        puts 'No changes in service.rb file: nothing to kill and delete. Exit'
      end
    end
  end

  after "deploy:create_symlink", "daemontools:update"
  after "deploy:rollback", "daemontools:update"
end
