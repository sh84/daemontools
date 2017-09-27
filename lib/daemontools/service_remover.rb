module Daemontools
  class Remover
    attr_accessor :previous_builder, :current_builder, :deleted_services

    def initialize(roles, previous_builder, current_builder)
      raise ArgumentError, "previous_builder couldn't be nil" if previous_builder.nil?
      raise ArgumentError, "current_builder couldn't be nil" if current_builder.nil?

      @roles = roles.split(',').map(&:to_sym)
      @previous_builder = previous_builder
      @current_builder = current_builder
      find_services_changes(@previous_builder.services, @current_builder.services)
    end

    def remove_unused_services
      return if @deleted_services.empty?

      @deleted_services.each do |role, services|
        puts "Delete services #{services} for role #{role}"
        @previous_builder.delete_services(services, role)
      end
    end

    private

    def find_services_changes(old_services, new_services)
      @deleted_services = {}
      @roles.each do |role|
        old_role_services = (old_services[role] || []).map(&:first)
        new_role_services = (new_services[role] || []).map(&:first)
        services_for_del = old_role_services - new_role_services
        @deleted_services[role] = services_for_del unless services_for_del.empty?
      end
    end
  end
end
