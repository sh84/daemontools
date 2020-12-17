require 'daemontools/version'
require 'daemontools/service_builder'
require 'daemontools/service_remover'
require 'etc'
require 'erb'

module Daemontools
  class << self
    attr_accessor :svc_root, :log_root, :tmp_root
  end
  @svc_root = '/etc/service'
  @log_root = '/var/log/svc'
  @tmp_root = '/tmp'

  def self.exists?(name)
    check_service_exists(name, false)
  end

  def self.tmp_exists?(name)
    Dir.exists?("#{@tmp_root}/daemontools_service_#{name}")
  end

  def self.status(name)
    check_service_exists(name)
    r = `sudo svstat #{@path} 2>&1`
    raise r if $?.exitstatus != 0
    raise "Unknown status" unless r.match(/.*?:\s*(\S+).*\s(\d+) seconds.*/)
    [$1, $2.to_i]
  end

  def self.up?(name)
    status(name)[0] == "up"
  end

  def self.down?(name)
    status(name)[0] == "down"
  end

  def self.stop(name)
    run_svc(name, 'd')
  end

  def self.start(name)
    run_svc(name, 'u')
  end

  def self.restart(name)
    run_svc(name, 't')
  end

  def self.add_empty(name)
    path = "#{@svc_root}/#{name}"
    Dir.mkdir(path) unless Dir.exists?(path)
    File.open("#{path}/down", 'w') {|f| f.write('')}
    now = Time.now.to_f
    while `sudo svstat #{path} 2>&1`.match(/unable to open/i)
      raise "Timeout wait for svc add service" if Time.now.to_f - now > 10
      sleep 0.1
    end
    File.delete("#{path}/down")
    stop(name)
    true
  end

  def self.add_empty_tmp(name)
    path = "#{@tmp_root}/daemontools_service_#{name}"
    Dir.mkdir(path) unless Dir.exists?(path)
    true
  end

  def self.move_tmp(name)
    tmp_path = "#{@tmp_root}/daemontools_service_#{name}"
    svc_path = "#{@svc_root}/#{name}"

    r = `mv #{tmp_path} #{svc_path}`
    raise r if $?.exitstatus != 0
    raise r if ! r.empty?

    now = Time.now.to_f
    while `sudo svstat #{svc_path} 2>&1`.match(/unable to open/i)
      raise "Timeout wait for svc add service" if Time.now.to_f - now > 10
      sleep 0.1
    end

    true
  end

  def self.add(name, command, options = {})
    @name = name
    @command = command
    @log_dir = options[:log_dir] || "#{@log_root}/#{@name}"
    @pre_command = options[:pre_command]
    @sleep = options[:sleep] || 3
    @path = "#{@svc_root}/#{name}"
    @change_user_command = options[:change_user_command]
    @ulimit = options[:ulimit]
    @write_time = options[:write_time]

    if Dir.exists?(@path)
      stop(name)
    else
      Dir.mkdir(@path)
    end
    File.open("#{@path}/down", 'w') {|f| f.write('')}
    Dir.mkdir("#{@path}/log") unless Dir.exists?("#{@path}/log")
    File.open("#{@path}/log/run", 'w', 0755) {|f| f.write(run_template('log.erb'))}
    File.open("#{@path}/run", 'w', 0755) {|f| f.write(run_template('run.erb'))}

    unless options[:not_wait]
      wait_timeout = options[:wait_timeout] || 10
      now = Time.now.to_f
      while `sudo svstat #{@path} 2>&1`.match(/unable to open/i)
        raise "Timeout wait for svc add service" if Time.now.to_f - now > wait_timeout
        sleep 0.1
      end
    end

    true
  end

  def self.delete(name, rm_cmd = nil)
    check_service_exists(name)
    stop(name)
    cmd = rm_cmd.nil? ? "sudo rm -rf #{@path} 2>&1" : "#{rm_cmd} #{@path}"
    r = `#{cmd}`
    raise r if $?.exitstatus != 0
    true
  end

  def self.run_status(name)
    check_service_exists(name)
    File.exists?("#{@path}/down") ? "down" : "up"
  end

  def self.run_status_up?(name)
    run_status(name) == "up"
  end

  def self.run_status_down?(name)
    run_status(name) == "down"
  end

  def self.make_run_status_up(name)
    File.delete("#{@path}/down")
    true
  end

  def self.make_run_status_down(name)
    check_service_exists(name)
    File.open("#{@path}/down", 'w') {|f| f.write('')}
    true
  end

  private

  def self.check_service_exists(name, raise_error = true)
    @path = "#{@svc_root}/#{name}"
    if raise_error
      raise "Service #{name} not exists" unless Dir.exists?(@path)
    else
      Dir.exists?(@path)
    end
  end

  def self.run_svc(name, command)
    check_service_exists(name)
    r = `sudo svc -#{command} #{@path} 2>&1`
    raise r if $?.exitstatus != 0
    raise r if ! r.empty?
    true
  end

  def self.run_template(template_name)
    @user = Etc.getpwuid(Process.uid).name
    template_path = File.expand_path(File.dirname(__FILE__))+'/../templates/'+template_name
    ERB.new(File.read(template_path)).result(binding())
  end
end
