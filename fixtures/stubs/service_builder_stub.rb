require 'daemontools'

module Daemontools
  class BuilderStub < Builder
    def start_service(_param1 = nil, _param2 = nil, _param3 = nil)
      true
    end

    def delete_services(service_names, role)
      find_services_by_name(service_names, role).map(&:first)
    end
  end
end
