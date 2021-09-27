require 'daemontools'

module Daemontools
  class RemoverStub < Remover
    def remove_unused_services
      return if @deleted_services.empty?

      @previous_builder.delete_services(@deleted_services)
    end
  end
end
