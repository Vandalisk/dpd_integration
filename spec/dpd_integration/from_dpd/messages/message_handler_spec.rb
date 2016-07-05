require "rails_helper"

RSpec.describe FromDPD::Messages::MessageHandler do
  subject { FromDPD::Messages::MessageHandler }

  describe "response via rabbitmq" do
    let(:patients) { create_list(:patient, 2) }
    let(:doctor) { create(:doctor) }
    let!(:messages) do
      create_list(:message, 5, sender: doctor, receiver: patients.first) +
      create_list(:message, 5, sender: patients.first, receiver: doctor) +
      create_list(:message, 5, sender: doctor, receiver: patients.second) +
      create_list(:message, 5, sender: patients.second, receiver: doctor)
    end

    context 'valid params' do
      let(:valid_params) do
        {
          "patient_ids" => patients.map(&:id),
          "doctor_id" => doctor.id,
          "date_from" => (Date.today - 1).strftime,
          "date_to" => Date.today.strftime
        }
      end

      it "should send messages to dpd" do
        response = double(:response)
        routing_key = double(:routing_key)
        allow_any_instance_of(subject).to receive(:response).and_return(response)
        allow_any_instance_of(subject).to receive(:generate_routing_key).and_return(routing_key)
        allow(DPDMessageSender).to receive(:send)

        expect(DPDMessageSender).to receive(:send).with(response, routing_key)
        subject.new(valid_params).handle
      end

      context 'data with transaction_queue_name' do
        let(:failure_response_text) { 'FAILURE' }
        let(:success_response_text) { 'SUCCESS' }
        let(:params) { valid_params.merge('transaction_queue_name'=>'transaction_queue_name') }
        let(:routing_key) { double(:routing_key) }

        before(:each) do
          allow_any_instance_of(subject).to receive(:generate_routing_key).and_return(routing_key)
        end

        it 'when error response_text should be FAILURE' do
          allow(Message).to receive(:prepare_for_rabbit).and_raise(ActiveRecord::ActiveRecordError)
          expect(DPDMessageSender).to receive(:send).with(failure_response_text, 'transaction_queue_name')
          subject.new(params).handle
        end

        it 'without error response_text should be SUCCESS' do
          response = double(:response)
          allow_any_instance_of(subject).to receive(:send_message)
          expect(DPDMessageSender).to receive(:send).with(success_response_text, 'transaction_queue_name')
          subject.new(params).handle
        end
      end
    end
  end
end
