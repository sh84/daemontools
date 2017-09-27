require 'daemontools'

module Daemontools
  class RemoverStub < Remover
    def remove_unused_services
      return if @deleted_services.empty?

      @deleted_services.map do |role, services|
        @previous_builder.delete_services(services, role)
      end
    end
  end
end
