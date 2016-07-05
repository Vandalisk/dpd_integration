require 'rails_helper'

RSpec.describe FromDPD::Treatments::DeleteTreatmentHandler do
  subject { FromDPD::Treatments::DeleteTreatmentHandler }
  let(:dpd_answers) { JSON.parse(File.read("spec/fixtures/dpd.json")) }
  let(:valid_params) { JSON.parse dpd_answers["treatment.delete"] }

  context 'valid params' do
    let(:treatment_params) do
      params = JSON.parse dpd_answers['treatment.insert']
      params['dpd_id'] = params.delete('id')
      params['dpd_dosage'] = params.delete('dosage')
      params.delete('sender')
      params.delete('bcd_id')
      params.merge(
        {
          'status' => 'from_dpd',
          'treatment_type' => 'medication',
          'version' => '2'
        }
      )
    end
    let(:treatment) { create(:treatment, treatment_params.merge('version' => valid_params['version'] - 1 ))}

    it 'move treatment to history' do
      expect{
        subject.new(valid_params).handle
        treatment.reload
      }
      .to change{ treatment.status }.from('from_dpd').to('declined')
    end
  end

  context 'invalid params' do
    let(:bad_id) {{ 'id' => nil }}
    let(:bad_dpd_id) {{ 'dpd_id' => nil }}

    describe "shouldn't delete Treatment" do
      describe 'invalid id' do
        it 'involve DPDErrorRaiser.raise' do
          expect(DPDMessageSender).to receive(:send).with('Wrong format of id. Id can be only number.', 'dpd.error')
          subject.new(bad_id).handle
        end
      end

      describe 'invalid dpd_id' do
        it 'involve DPDErrorRaiser.raise' do
          expect(DPDMessageSender).to receive(:send).with('Wrong format of id. Id can be only number.', 'dpd.error')
          subject.new(bad_dpd_id).handle
        end
      end

      describe 'not in database' do
        it 'involve DPDErrorRaiser.raise' do
          expect(DPDMessageSender).to receive(:send).with("Treatment doesn't exist in database.", 'dpd.error')
          subject.new(valid_params).handle
        end
      end
    end
  end
end
