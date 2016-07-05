require "rails_helper"

RSpec.describe LabResultsFetcher do
  describe 'BunnyMock' do
    let(:dpd_answers) { JSON.parse(File.read("spec/fixtures/dpd.json")) }
    let(:lab_results_request_params) { eval dpd_answers["lab_results_request"] }
    let(:bunny) { BunnyMock.new }

    it "#start" do
      # expect(bunny.start.status).to eq(:connected)
    end

    it 'lab_results request' do
      # allow(Bunny).to receive(:new) { bunny }


      # exchange = bunny.exchange("Test")
      # exchange.publish('123')
      # allow(connection).to receive(start) { bunny.start }

      # allow().to receive(new).and_return(BunnyMock.new)


      # expect(LabResultsFetcher.new('lab_results', lab_results_request_params).fetch).to eq()
    end

  end
end
