require 'rails_helper'

RSpec.describe FromDPD::AbstractHandler do
  describe "should use appropriate handler by route name" do
    let(:data){ JSON.parse(File.read("spec/fixtures/dpd.json")) }

    it 'bcd.user.subscribe' do
      handler = double('subscribe_user_handler')

      allow(FromDPD::Users::SubscribeUserHandler).to receive(:new).with(data){ handler }
      allow(handler).to receive(:handle) { 'yes' }
      expect(subject.class.handle(data, 'bcd.user.subscribe')).to eq 'yes'
    end

    it 'bcd.user.unsubscribe' do
      handler = double('unsubscribe_user_handler')

      allow(FromDPD::Users::UnsubscribeUserHandler).to receive(:new).with(data){ handler }
      allow(handler).to receive(:handle) { 'yes' }
      expect(subject.class.handle(data, 'bcd.user.unsubscribe')).to eq 'yes'
    end

    it 'bcd.user.update' do
      handler = double('update_user_handler')

      allow(FromDPD::Users::UpdateUserHandler).to receive(:new).with(data){ handler }
      allow(handler).to receive(:handle) { 'yes' }
      expect(subject.class.handle(data, 'bcd.user.update')).to eq 'yes'
    end

    it 'bcd.treatment.insert' do
      handler = double('insert_treatment_handler')

      allow(FromDPD::Treatments::InsertTreatmentHandler).to receive(:new).with(data){ handler }
      allow(handler).to receive(:handle) { 'yes' }
      expect(subject.class.handle(data, 'bcd.treatment.insert')).to eq 'yes'
    end

    it 'bcd.treatment.delete' do
      handler = double('delete_treatment_handler')

      allow(FromDPD::Treatments::DeleteTreatmentHandler).to receive(:new).with(data){ handler }
      allow(handler).to receive(:handle) { 'yes' }
      expect(subject.class.handle(data, 'bcd.treatment.delete')).to eq 'yes'
    end

    it 'bcd.treatment.update' do
      handler = double('update_treatment_handler')

      allow(FromDPD::Treatments::UpdateTreatmentHandler).to receive(:new).with(data){ handler }
      allow(handler).to receive(:handle) { 'yes' }
      expect(subject.class.handle(data, 'bcd.treatment.update')).to eq 'yes'
    end

    it 'bcd.message' do
      handler = double('message_handler')

      allow(FromDPD::Messages::MessageHandler).to receive(:new).with(data){ handler }
      allow(handler).to receive(:handle) { 'yes' }
      expect(subject.class.handle(data, 'bcd.message')).to eq 'yes'
    end

    it 'bcd.synchronization.check' do
      handler = double('check_synchronization_handler')
      allow(FromDPD::Synchronizations::CheckSynchronizationHandler).to receive(:new).with(data){ handler }
      allow(handler).to receive(:handle) { 'yes' }
      expect(subject.class.handle(data, 'bcd.synchronization.check')).to eq 'yes'
    end
  end
end

