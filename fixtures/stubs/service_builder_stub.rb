require 'daemontools'

module Daemontools
  class BuilderStub < Builder
    def start_service(_param1 = nil, _param2 = nil, _param3 = nil)
      true
    end

    def delete_services(service_names)
      service_names
    end
  end
end
