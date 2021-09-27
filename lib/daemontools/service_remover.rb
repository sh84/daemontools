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

      puts "Services for delete: #{@deleted_services.join(', ')}"
      @previous_builder.delete_services(@deleted_services)
    end

    private

    def find_services_changes(old_services, new_services)
      old_services_for_server = services_for_roles(old_services, @roles)
      new_services_for_server = services_for_roles(new_services, @roles)
      @deleted_services = old_services_for_server - new_services_for_server
    end

    # Extracting service names for roles from config
    def services_for_roles(services, roles)
      services.values_at(*roles).flatten(1).compact.map(&:first).compact.uniq
    end
  end
end
