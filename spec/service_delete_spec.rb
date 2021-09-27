require 'daemontools'
require "#{Dir.pwd}/fixtures/stubs/service_builder_stub.rb"
require "#{Dir.pwd}/fixtures/stubs/service_remover_stub.rb"

RSpec.describe Daemontools::Remover, '#initialize' do
  context 'Check initialization process' do
    old_builder = Daemontools::BuilderStub.new("#{Dir.pwd}/fixtures/old_services.rb")
    new_builder = Daemontools::BuilderStub.new("#{Dir.pwd}/fixtures/new_services.rb")

    roles = old_builder.all_roles + new_builder.all_roles
    roles += ['role_without_any_service']
    roles.uniq!
    roles = roles.join(',')

    remover = Daemontools::RemoverStub.new(roles, old_builder, new_builder)
    deleted = remover.deleted_services
    deleted_services = %i[deleted_service_1 deleted_service_2 deleted_service_3]

    context 'Check roles where services were deleted' do
      it 'Number of roles for deleted services must be equal to length of deleted roles' do
        expect(deleted.size).to eq deleted_services.length
      end

      deleted.each do |service_name|
        it "Should contain #{service_name}" do
          expect(deleted_services.include?(service_name)).to eq true
        end
      end

      it 'Include service from renamed role' do
        expect(deleted_services.include?('service4')).to eq false
      end
    end

    context 'Removing unused services' do
      deleted_services_names = %i[deleted_service_1 deleted_service_2 deleted_service_3]
      it 'Should remove services which was deleted' do
        expect(remover.remove_unused_services.flatten.sort).to eq deleted_services_names.sort
      end
    end
  end
end
