require 'rails_helper'

RSpec.describe FromDPD::Users::SubscribeUserHandler do
  subject { FromDPD::Users::SubscribeUserHandler }
  let(:dpd_answers) { JSON.parse(File.read("spec/fixtures/dpd.json")) }
  let(:valid_params) { JSON.parse dpd_answers["user.subscribe"] }

  context 'valid params' do

    it 'create user' do
      expect{ subject.new(valid_params).handle }.to change(User, :count).by(1)
    end

    it 'fields must be the same' do
      subject.new(valid_params).handle

      valid_params.each do |key, value|
        value = Date.parse(value) if key == "birthday"
        expect(User.last.send(key)).to eq value
      end

      expect(User.last.role).to eq "patient"
    end
  end

  context 'invalid params' do
    let(:bad_id) { valid_params.merge({'id' => -1}) }
    let(:bad_email) { valid_params.merge({'email' => nil}) }

    describe "shouldn't save user" do
      context "invalid id" do
        it 'not exist' do
          allow(DPDMessageSender).to receive(:send)
          subject.new(bad_id).handle
          expect(Treatment.find_by(name: valid_params['name'])).to eq nil
        end

        it 'involve DPDErrorRaiser.raise' do
          expect(DPDMessageSender).to receive(:send).with('Wrong format of id. Id can be only number.', 'dpd.error')
          subject.new(bad_id).handle
        end
      end

      context 'invalid email' do
        it 'not exist' do
          allow(DPDMessageSender).to receive(:send)
          subject.new(bad_email).handle
          expect(Treatment.find_by(name: valid_params['name'])).to eq nil
        end

        it 'involve DPDErrorRaiser.raise' do
          expect(DPDMessageSender).to receive(:send)
          subject.new(bad_email).handle
        end
      end
    end
  end
end
