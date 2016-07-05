require 'rails_helper'

RSpec.describe FromDPD::Synchronizations::CheckSynchronizationHandler do
  subject { FromDPD::Synchronizations::CheckSynchronizationHandler }
  let(:data){
    JSON.parse(File.read("spec/fixtures/dpd.json"))['check.synchronization'].deep_symbolize_keys!
  }

  describe 'should synchronize list objects from dpd to bcd' do
    before(:each) do
      allow(DPDMessageSender).to receive(:send)
    end

    describe 'users' do
      context 'any action on dpd and bcd same versions' do
        let(:user) { create(:patient, data[:objects][0].except(:model)) }
        let(:user_data) { { objects: [data[:objects][0]], queue_name: 'queue_name' } }

        it 'dpd_version == bcd_version' do
          allow_any_instance_of(subject).to receive(:send_not_synchronized_objects_to_dpd)
          expect{
            subject.new(user_data).handle
            user.reload
          }.to change(user, :synchronized).from(false).to(true)
        end
      end
      context 'subscribed, unsubscribed or update on dpd but not in bcd' do
        let(:dpd_user_params) { data[:objects][0].merge(version: (data[:objects][0][:version].to_i + 1)) }
        let(:bcd_user_params) { data[:objects][0].except(:model) }
        let(:user_data) { { objects: [dpd_user_params], queue_name: 'queue_name' } }
        let!(:user) { create(:patient, bcd_user_params) }

        it 'in database' do
          handler = subject.new(user_data)
          handler.handle
          expect(handler.payload[:objects][0][:status]).to eq('request')
        end
      end
      context 'updated on bcd but not in dpd' do
        let(:dpd_user_params) { data[:objects][1] }
        let(:bcd_user_params) { dpd_user_params.except(:model).merge(version: (dpd_user_params[:version].to_i + 1)) }
        let(:user_data) { { objects: [dpd_user_params], queue_name: 'queue_name' } }
        let!(:user) { create(:patient, bcd_user_params) }
        let(:without_user) { { objects: [data[:objects][2]], queue_name: 'queue_name' } }
        let(:routing_key) { 'dpd.user.update' }

        it 'in params list' do
          response = double(:response)
          allow_any_instance_of(subject).to receive(:send_not_synchronized_objects_to_dpd)
          allow(response).to receive(:notify).with(user)
          expect(ToDPD::Notifier).to receive(:new).with(routing_key).and_return(response)
          subject.new(user_data).handle
        end
      end
    end

    describe 'treatments' do
      context 'any action on dpd and bcd same versions' do
        let(:treatment) { create(:treatment, data[:objects][3].except(:model)) }
        let(:treatment_data) { { objects: [data[:objects][3]], queue_name: 'queue_name' } }

        it 'dpd_version == bcd_version' do
          allow_any_instance_of(subject).to receive(:send_not_synchronized_objects_to_dpd)
          expect{
            subject.new(treatment_data).handle
            treatment.reload
          }.to change(treatment, :synchronized).from(false).to(true)
        end
      end
      context 'inserted, updated, deleted on dpd but not in bcd' do
        let(:dpd_treatment_params) { data[:objects][3].merge(version: (data[:objects][3][:version].to_i + 1)) }
        let(:bcd_treatment_params) { data[:objects][3].except(:model) }
        let(:treatment_data) { { objects: [dpd_treatment_params], queue_name: 'queue_name' } }
        let(:treatment) { create(:treatment, bcd_treatment_params) }
        it 'in database' do
          allow_any_instance_of(subject).to receive(:send_not_synchronized_objects_to_dpd)
          treatment
          handler = subject.new(treatment_data)
          handler.handle
          expect(handler.payload[:objects][0][:status]).to eq('request')
        end

        it 'not in database' do
          handler = subject.new(treatment_data)
          handler.handle
          expect(handler.payload[:objects][0][:status]).to eq('request')
        end
      end
      context 'prescribed on bcd but not in dpd' do
        let(:dpd_treatment_params) { data[:objects][3] }
        let(:bcd_treatment_params) { dpd_treatment_params.except(:model) }
        let!(:treatment) { create(:treatment, bcd_treatment_params) }
        let(:without_treatment) { { objects: [data[:objects][5]], queue_name: 'queue_name' } }
        let(:routing_key) { 'dpd.treatment.prescribe' }

        it 'not in params' do
          User.update_all(synchronized: true)
          response = double(:response)
          allow(response).to receive(:notify).with(treatment)
          expect(ToDPD::Notifier).to receive(:new).with(routing_key).and_return(response)
          subject.new(without_treatment).handle
        end
      end
      context 'updated on bcd but not in dpd' do
        let(:dpd_treatment_params) { data[:objects][5] }
        let(:bcd_treatment_params) { dpd_treatment_params.except(:model).merge(version: (dpd_treatment_params[:version].to_i + 1)) }
        let!(:treatment) { create(:treatment, bcd_treatment_params) }
        let(:treatment_data) { { objects: [dpd_treatment_params], queue_name: 'queue_name' } }
        let(:without_treatment) { { objects: [data[:objects][4]], queue_name: 'queue_name' } }
        let(:routing_key) { 'dpd.treatment.update' }

        it 'in params list' do
          response = double(:response)
          allow_any_instance_of(subject).to receive(:send_not_synchronized_objects_to_dpd)
          allow(response).to receive(:notify).with(treatment)
          expect(ToDPD::Notifier).to receive(:new).with(routing_key).and_return(response)
          subject.new(treatment_data).handle
        end
      end
      context 'deleted on bcd but not in dpd' do
        let(:dpd_treatment_params) { data[:objects][5] }
        let(:bcd_treatment_params) {
          dpd_treatment_params.except(:model).merge(
            version: (dpd_treatment_params[:version].to_i + 1),
            status: 'declined'
          )
        }
        let!(:treatment) { create(:treatment, bcd_treatment_params) }
        let(:treatment_data) { { objects: [dpd_treatment_params], queue_name: 'queue_name' } }
        let(:without_treatment) { { objects: [data[:objects][4]], queue_name: 'queue_name' } }
        let(:routing_key) { 'dpd.treatment.delete' }

        it 'in params list' do
          response = double(:response)
          allow_any_instance_of(subject).to receive(:send_not_synchronized_objects_to_dpd)
          allow(response).to receive(:notify).with(treatment)
          expect(ToDPD::Notifier).to receive(:new).with(routing_key).and_return(response)
          subject.new(treatment_data).handle
        end
      end
    end
  end
end
