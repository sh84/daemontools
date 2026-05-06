require 'daemontools/version'
require 'daemontools/service'
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

  # Actions

  def self.add(name, command, options = {})
    Service[name].add(command, options)
  end

  def self.delete(name, rm_cmd = nil)
    Service[name].delete(rm_cmd)
  end

  def self.start(name)
    Service[name].start
  end

  def self.stop(name)
    Service[name].stop
  end

  def self.restart(name)
    Service[name].restart
  end

  # Statuses

  def self.status(name)
    Service[name].status
  end

  def self.up?(name)
    Service[name].up?
  end

  def self.down?(name)
    Service[name].down?
  end

  def self.exists?(name)
    Service[name].check_service_exists(false)
  end

  def self.check_service_exists(name, raise_error = true)
    Service[name].check_service_exists(raise_error)
  end

  # Run States

  def self.run_status(name)
    Service[name].run_status
  end

  def self.run_status_up?(name)
    Service[name].run_status_up?
  end

  def self.run_status_down?(name)
    Service[name].run_status_down?
  end

  def self.make_run_status_up(name)
    Service[name].run_status_up!
  end

  def self.make_run_status_down(name)
    Service[name].run_status_down!
  end

  # Tmp Actions

  def self.add_empty(name)
    Service[name].add_empty
  end

  def self.add_empty_tmp(name)
    Service[name].add_empty_tmp
  end

  def self.move_tmp(name)
    Service[name].move_tmp
  end

  def self.tmp_exists?(name)
    Service[name].tmp_exists?
  end
end
