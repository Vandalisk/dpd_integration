require 'rails_helper'

RSpec.describe FromDPD::Users::UnsubscribeUserHandler do
  subject { FromDPD::Users::UnsubscribeUserHandler }
  let(:dpd_answers) { JSON.parse(File.read("spec/fixtures/dpd.json")) }
  let(:valid_params) { JSON.parse dpd_answers["user.delete"] }

  context 'valid params' do
    let(:user_params) { JSON.parse dpd_answers["user.subscribe"] }
    let!(:user) { create(:patient, user_params) }

    it 'deactivates user' do
      allow(DPDMessageSender).to receive(:send)
      expect{ subject.new(valid_params).handle; user.reload }.to change(user, :active).from(true).to(false)
    end
  end

  context 'invalid params' do
    let(:bad_id) {{ "id" => nil }}

    describe "shouldn't delete User" do
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
    end
  end
end
