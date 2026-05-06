require 'daemontools'

RSpec.describe Daemontools::Service do
  let(:svc_root) { '/tmp/svc_root' }
  let(:tmp_root) { '/tmp/tmp_root' }
  let(:log_root) { '/tmp/log_root' }

  before do
    stub_const('Daemontools::Service::CACHED_SERVICES', {})

    allow(Daemontools).to receive(:svc_root).and_return(svc_root)
    allow(Daemontools).to receive(:tmp_root).and_return(tmp_root)
    allow(Daemontools).to receive(:log_root).and_return(log_root)

    FileUtils.mkdir_p(svc_root)
    FileUtils.mkdir_p(tmp_root)
    FileUtils.mkdir_p(log_root)
  end

  after do
    FileUtils.rm_rf(svc_root)
    FileUtils.rm_rf(tmp_root)
    FileUtils.rm_rf(log_root)
  end

  describe '.[]' do
    it 'caches and returns the same instance for the same name' do
      s1 = described_class['test']
      s2 = described_class['test']
      expect(s1).to be_a(described_class)
      expect(s1).to equal(s2)
    end
  end

  describe '#check_service_exists' do
    let(:service) { described_class.new('svc1') }

    it 'returns false when the directory does not exist' do
      expect(service.check_service_exists(false)).to be false
    end

    it 'raises an error when directory is missing and raise_error=true' do
      expect { service.check_service_exists(true) }.to raise_error(/not exists/)
    end

    it 'returns true when the directory exists' do
      FileUtils.mkdir_p("#{svc_root}/svc1")
      expect(service.check_service_exists(false)).to be true
    end
  end

  describe '#delete' do
    let(:service) { described_class.new('svc1') }

    before do
      FileUtils.mkdir_p("#{svc_root}/svc1")
      allow(service).to receive(:stop).and_return(true)
      allow(service).to receive(:`).and_return('')
      allow($?).to receive(:exitstatus).and_return(0)
      Daemontools::Service::CACHED_SERVICES['svc1'] = service
    end

    it 'removes the service from cache and returns true' do
      expect(service.delete(nil)).to be true
      expect(Daemontools::Service::CACHED_SERVICES).not_to have_key('svc1')
    end

    it 'returns false when service does not exist' do
      FileUtils.rm_rf("#{svc_root}/svc1")
      expect(service.delete(nil)).to be false
    end

    it 'raises an error when command exit status is non‑zero' do
      allow($?).to receive(:exitstatus).and_return(1)
      expect { service.delete(nil) }.to raise_error(RuntimeError)
    end
  end

  describe '#status' do
    let(:service) { described_class.new('svc2') }
    let(:output)  { 'svc2: up (pid 1234) 5 seconds' }

    before do
      FileUtils.mkdir_p("#{svc_root}/svc2")
      allow(service).to receive(:`).and_return(output)
      allow($?).to receive(:exitstatus).and_return(0)
    end

    it 'returns [status, seconds] for valid svstat output' do
      expect(service.status).to eq(%w[up 5].tap { |a| a[1] = 5 })
    end

    it 'raises "Unknown status" for unexpected output' do
      allow(service).to receive(:`).and_return('something weird')
      expect { service.status }.to raise_error('Unknown status')
    end

    it 'raises an error when command fails' do
      allow($?).to receive(:exitstatus).and_return(1)
      expect { service.status }.to raise_error(/svc2/)
    end
  end

  describe '#run_status_*' do
    let(:service) { described_class.new('svc3') }

    before do
      FileUtils.mkdir_p("#{svc_root}/svc3")
    end

    it 'returns "up" when no down file exists' do
      expect(service.run_status).to eq('up')
    end

    it 'returns "down" when down file exists' do
      FileUtils.touch("#{svc_root}/svc3/down")
      expect(service.run_status).to eq('down')
    end

    it '#run_status_up! removes down files' do
      FileUtils.mkdir_p("#{svc_root}/svc3/log")
      FileUtils.touch("#{svc_root}/svc3/down")
      FileUtils.touch("#{svc_root}/svc3/log/down")
      service.run_status_up!
      expect(File).not_to exist("#{svc_root}/svc3/down")
      expect(File).not_to exist("#{svc_root}/svc3/log/down")
    end

    it '#run_status_down! creates down files' do
      FileUtils.mkdir_p("#{svc_root}/svc3/log")
      service.run_status_down!
      expect(File).to exist("#{svc_root}/svc3/down")
      expect(File).to exist("#{svc_root}/svc3/log/down")
    end
  end

  describe '#tmp_exists?' do
    let(:service) { described_class.new('svc_tmp') }

    it 'returns true when temporary directory exists' do
      FileUtils.mkdir_p("#{tmp_root}/daemontools_service_svc_tmp")
      expect(service.tmp_exists?).to be true
    end

    it 'returns false when temporary directory is missing' do
      FileUtils.rm_rf("#{tmp_root}/daemontools_service_svc_tmp")
      expect(service.tmp_exists?).to be false
    end
  end

  describe '.CACHED_SERVICES' do
    it 'holds created instances' do
      s1 = described_class['foo']
      expect(Daemontools::Service::CACHED_SERVICES['foo']).to eq(s1)
    end
  end
end
