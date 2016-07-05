require 'rails_helper'

RSpec.describe FromDPD::Users::UpdateUserHandler do
  subject { FromDPD::Users::UpdateUserHandler }
  let(:dpd_answers) { JSON.parse(File.read("spec/fixtures/dpd.json")) }
  let(:user_params) { JSON.parse(dpd_answers["user.subscribe"]) }
  let(:user) { create(:patient, user_params) }
  let(:valid_params){ JSON.parse dpd_answers["user.update"] }

  context 'valid params' do
    before(:each) { allow(DPDMessageSender).to receive(:send) }

    it 'should update user' do
      user
      expect {
        subject.new(valid_params).handle
        user.reload
      }.to change{ user.email }.and change{ user.phone }
    end

    it 'fields must be the same' do
      user
      subject.new(valid_params).handle
      user.reload

      valid_params.each do |key, value|
        value = Date.parse(value) if key == "birthday"
        expect(user.send(key)).to eq value
      end
    end
  end

  context 'invalid params' do
    let(:invalid_params) { valid_params.merge({"email" => nil}) }

    describe "shouldn't update user" do
      let(:bad_id) {{'id'=>''}}

      describe 'invalid id' do
        it 'involve DPDErrorRaiser.raise' do
          expect(DPDMessageSender).to receive(:send).with('Wrong format of id. Id can be only number.', 'dpd.error')
          subject.new(bad_id).handle
        end
      end

      describe 'not in database' do
        it 'involve DPDErrorRaiser.raise' do
          expect(DPDMessageSender).to receive(:send).with("User doesn't exist in database.", 'dpd.error')
          subject.new(valid_params).handle
        end
      end

      describe "with invalid params" do
        let!(:user) { create(:patient, user_params) }
        let(:attributes) { user.attributes }

        it "shouldn't update" do
          allow(DPDMessageSender).to receive(:send)
          subject.new(invalid_params).handle
          expect(user.reload.attributes).to eq attributes
        end

        it 'should output validation errors' do
          expect(DPDMessageSender).to receive(:send)
          subject.new(invalid_params).handle
        end
      end
    end
  end
end
