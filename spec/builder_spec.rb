require 'daemontools'

RSpec.describe Daemontools::Builder, '#initialize' do
  context 'Check commands' do
    builder = Daemontools::Builder.new("#{Dir.pwd}/fixtures/services.rb")
    it 'Second element must be contain right string for COMMAND2 method' do
      command = builder.services[:role1][1][1]
      expect(command).to eq 'cd /home/user/dir && command2 service2.sh'
    end
    it 'Second element must be contain right string for COMMAND1 method' do
      command = builder.services[:role1][0][1]
      expect(command).to eq 'cd /home/user/dir && command1 service1.sh'
    end
    it 'Second element must be contain right string for COMMAND3 method' do
      command = builder.services[:role1][2][1]
      expect(command).to eq 'cd /home/user/dir && command3 bin/service3'
    end
  end
end

RSpec.describe Daemontools::Builder, '#delete_command' do
  context 'Check delete_command method' do
    builder = Daemontools::Builder.new("#{Dir.pwd}/fixtures/services.rb")
    it 'Should return a nil after initialize' do
      expect(builder.instance_variable_get(:@delete_command)).to eq nil
    end
    it 'Should return a nil after assignment an empty string' do
      builder.delete_command ''
      expect(builder.instance_variable_get(:@delete_command)).to eq nil
    end
    it 'Should return a the same string after assignment delete_command' do
      delete_command = 'delete_command'
      builder.delete_command delete_command
      expect(builder.instance_variable_get(:@delete_command)).to eq delete_command
    end
  end
end
