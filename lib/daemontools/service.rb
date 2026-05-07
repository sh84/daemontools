module Daemontools
  class Service

    CACHED_SERVICES = {}

    def self.[](name)
      CACHED_SERVICES[name] ||= new(name)
    end

    def initialize(name)
      @name = name
      @path = "#{Daemontools.svc_root}/#{name}"
      @log_path = "#{@path}/log"
    end

    # Actions

    def add(command, options)
      apply_options(command: command, **options)

      Dir.exist?(@path) ? stop : Dir.mkdir(@path)
      Dir.mkdir(@log_path) unless Dir.exist?(@log_path)

      File.open("#{@path}/down", 'w') { |f| f.write('') }
      File.open("#{@log_path}/down", 'w') { |f| f.write('') }
      File.open("#{@log_path}/run", 'w', 0o755) { |f| f.write(run_template('log.erb')) }
      File.open("#{@path}/run", 'w', 0o755) { |f| f.write(run_template('run.erb')) }

      wait_start(options[:wait_timeout]) unless options[:not_wait]

      true
    end

    def delete(rm_cmd)
      return false unless check_service_exists(false)

      stop
      sleep 0.3
      cmd = rm_cmd.nil? ? "sudo rm -rf #{@path} 2>&1" : "#{rm_cmd} #{@path}"
      r = `#{cmd}`
      raise r if $?.exitstatus != 0

      CACHED_SERVICES.delete(@name)
      true
    end

    def stop
      run_svc('d')
    end

    def start
      run_svc('u')
    end

    def restart
      run_svc('t')
    end

    # Statuses

    def status
      check_service_exists
      r = `sudo svstat #{@path} 2>&1`
      raise r if $?.exitstatus != 0
      raise 'Unknown status' unless r.match(/.*?:\s*(\S+).*\s(\d+) seconds.*/)

      [::Regexp.last_match(1), ::Regexp.last_match(2).to_i]
    end

    def up?
      status[0] == 'up'
    end

    def down?
      status[0] == 'down'
    end

    def check_service_exists(raise_error = true)
      exists = Dir.exist?(@path)
      raise_error && !exists ? raise("Service #{@name} not exists") : exists
    end

    # Run States

    def run_status
      check_service_exists
      File.exist?("#{@path}/down") ? 'down' : 'up'
    end

    def run_status_up?
      run_status == 'up'
    end

    def run_status_down?
      run_status == 'down'
    end

    def run_status_up!
      File.delete("#{@path}/down")
      File.delete("#{@log_path}/down") if Dir.exist?(@log_path)
      true
    end

    def run_status_down!
      check_service_exists
      File.open("#{@path}/down", 'w') { |f| f.write('') }
      File.open("#{@log_path}/down", 'w') { |f| f.write('') } if Dir.exist?(@log_path)

      true
    end

    # Tmp Actions

    def add_empty
      Dir.mkdir(@path) unless Dir.exist?(@path)
      File.open("#{@path}/down", 'w') { |f| f.write('') }

      wait_start(10)

      File.delete("#{@path}/down")
      stop

      true
    end

    def add_empty_tmp
      path = "#{Daemontools.tmp_root}/daemontools_service_#{@name}"
      Dir.mkdir(path) unless Dir.exist?(path)

      true
    end

    def move_tmp
      tmp_path = "#{Daemontools.tmp_root}/daemontools_service_#{@name}"
      svc_path = @path

      r = `mv #{tmp_path} #{svc_path}`
      raise r if $?.exitstatus != 0
      raise r unless r.empty?

      wait_start(10)

      true
    end

    def tmp_exists?
      Dir.exist?("#{Daemontools.tmp_root}/daemontools_service_#{@name}")
    end

    private

    def run_svc(command)
      check_service_exists
      r = `sudo svc -#{command} #{@path} 2>&1`
      raise r if $?.exitstatus != 0
      raise r unless r.empty?

      return true unless Dir.exist?(@log_path)

      r = `sudo svc -#{command} #{@log_path} 2>&1`
      raise r if $?.exitstatus != 0
      raise r unless r.empty?

      true
    end

    def run_template(template_name)
      @user = Etc.getpwuid(Process.uid).name
      template_path = "#{__dir__}/../../templates/#{template_name}"
      ERB.new(File.read(template_path)).result(binding)
    end

    def apply_options(**options)
      @command = options[:command]
      @log_dir = options[:log_dir] || "#{Daemontools.log_root}/#{@name}"
      @pre_command = options[:pre_command]
      @sleep = options[:sleep] || 3
      @change_user_command = options[:change_user_command]
      @ulimit = options[:ulimit]
      @write_time = options[:write_time]
    end

    def wait_start(wait_timeout = nil)
      wait_timeout ||= 10
      now = Time.now.to_f

      while `sudo svstat #{@path} 2>&1`.match(/unable to open/i)
        raise 'Timeout wait for svc add service' if Time.now.to_f - now > wait_timeout

        sleep 0.1
      end
    end
  end
end
