module Daemontools
  class Builder
    attr_accessor :environment, :all_roles, :services, :curr_service_name, :change_user_command, :ulimit, :write_time

    def initialize(filename)
      @all_roles = []
      @services = {}
      @change_user_command = 'setuidgid'
      @ulimit = {}
      @write_time = true
      eval(File.read(filename), binding())
    end

    def run_command(command_name, param)
      self.class.send(:define_method, command_name) do |task, options = {}|
        p = param.gsub(':task', task)
        options.each { |key, val| p.gsub!(":#{key}", val.to_s) }
        command(p, options)
      end
    end

    def command(param, options = {})
      Daemontools.stop(@curr_service_name) if Daemontools.exists?(@curr_service_name)
      @command = param.gsub(':environment', @environment)
      template_path = File.expand_path(File.dirname(__FILE__))+'/../../templates/rvm.erb'
      cmd = ERB.new(File.read(template_path)).result(binding())
      Daemontools.add(@curr_service_name, cmd, { :change_user_command => @change_user_command, :ulimit => @ulimit, :write_time => @write_time })
      Daemontools.make_run_status_up(@curr_service_name)
      Daemontools.start(@curr_service_name)
    end

    def service(name, opts = {}, &block)
      if opts[:roles]
        opts[:roles].each do |role|
          role = role.to_sym
          @all_roles << role unless @all_roles.member?(role)
          @services[role] = [] unless @services[role]
          @services[role] << [name, block]
        end
      else
        raise "service without roles"
      end
    end

    def gen(roles, env)
      @environment = env
      roles.split(',').each do |role|
        (@services[role.to_sym] || []).each do |service|
          @curr_service_name = service[0].to_s
          service[1].call
        end
      end
    end

    def change_user_command(cmd)
      @change_user_command = cmd
    end

    def ulimit(opt, val)
      @ulimit[opt] = val
    end

    def write_time(val)
      @write_time = val
    end
  end
end
