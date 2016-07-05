require 'rails_helper'

RSpec.describe FromDPD::Treatments::UpdateTreatmentHandler do
  subject { FromDPD::Treatments::UpdateTreatmentHandler }
  let(:dpd_answers) { JSON.parse(File.read("spec/fixtures/dpd.json")) }
  let(:insert_params) { JSON.parse dpd_answers["treatment.insert"] }
  let(:dpd_id) { insert_params['id'] }
  let(:valid_params) { JSON.parse dpd_answers["treatment.update"] }
  let(:treatment_params) do
    params = JSON.parse(dpd_answers["treatment.insert"])
    params['dpd_id'] = params.delete('id')
    params['dpd_dosage'] = params.delete('dosage')
    params['doctor'] = create(:doctor, first_name: params.delete('sender'))
    params.delete('bcd_id')
    params
  end
  let(:treatment) { create(:treatment, treatment_params) }

  before(:each) { allow(DPDMessageSender).to receive(:send) }

  context 'valid params' do
    context 'search by dpd_id' do
      describe 'status current(requested or new or active)' do

        describe 'status new' do
          let!(:treatment) { create(:treatment,
            name: insert_params['name'],
            status: 'new',
            dpd_id: dpd_id,
            version: valid_params['version'] - 1
            )
          }

          it 'updates' do
            subject.new(valid_params).handle
            expect(treatment.reload.status).to eq 'declined'
          end

          it 'updates with dpd_id nil' do
            subject.new(valid_params).handle
            expect(treatment.reload.dpd_id).to eq nil
          end

          describe 'should create new treatment with status from_dpd' do
            it 'count in database +1' do
              expect{ subject.new(valid_params).handle }.to change(Treatment, :count).by(1)
            end

            it 'status the same' do
              subject.new(valid_params).handle
              new_treatment = Treatment.find_by(dpd_id: dpd_id)
              expect(new_treatment.status).to eq 'from_dpd'
            end

            it 'dpd_id the same' do
              subject.new(valid_params).handle
              treatments = Treatment.where(name: treatment.name)
              expect(treatments.find{|new_treatment| new_treatment[:dpd_id] == dpd_id}).not_to be_nil
            end
          end
        end

        describe 'status requested' do
          let!(:treatment) { create(:treatment, name: insert_params['name'], status: 'requested', dpd_id: dpd_id, version: valid_params['version'] - 1) }

          it 'updates' do
            subject.new(valid_params).handle
            treatment.reload
            expect(treatment.status).to eq 'declined'
          end

          it 'updates with dpd_id nil' do
            subject.new(valid_params).handle
            treatment.reload
            expect(treatment.dpd_id).to eq nil
          end

          describe 'should create new treatment with status from_dpd' do
            it 'count in database +1' do
              expect{ subject.new(valid_params).handle }.to change(Treatment, :count).by(1)
            end

            it 'status the same' do
              subject.new(valid_params).handle
              new_treatment = Treatment.find_by(dpd_id: dpd_id)
              expect(new_treatment.status).to eq 'from_dpd'
            end

            it 'dpd_id the same' do
              subject.new(valid_params).handle
              treatments = Treatment.where(name: treatment.name)
              expect(treatments.find{|new_treatment| new_treatment[:dpd_id] == dpd_id}).not_to be_nil
            end
          end
        end

        describe 'status active' do
          let!(:treatment) { create(:treatment, name: insert_params['name'], status: 'active', dpd_id: dpd_id, version: valid_params['version'] - 1) }

          it 'updates' do
            subject.new(valid_params).handle
            treatment.reload
            expect(treatment.status).to eq 'declined'
          end

          it 'updates with dpd_id nil' do
            subject.new(valid_params).handle
            treatment.reload
            expect(treatment.dpd_id).to eq nil
          end

          describe 'should create new treatment with status from_dpd' do
            it 'count in database +1' do
              expect{ subject.new(valid_params).handle }.to change(Treatment, :count).by(1)
            end

            it 'status the same' do
              subject.new(valid_params).handle
              new_treatment = Treatment.find_by(dpd_id: dpd_id)
              expect(new_treatment.status).to eq 'from_dpd'
            end

            it 'dpd_id the same' do
              subject.new(valid_params).handle
              treatments = Treatment.where(name: treatment.name)
              expect(treatments.find{|new_treatment| new_treatment[:dpd_id] == dpd_id}).not_to be_nil
            end
          end
        end
      end

      describe 'status from dpd' do
        let!(:treatment) { create(:treatment, name: insert_params['name'], status: 'from_dpd', dpd_id: dpd_id, version: valid_params['version'] - 1) }

        it 'fields must be the same' do
          subject.new(valid_params).handle

          valid_params.each do |key, value|
            key = 'dpd_dosage' if key == 'dosage'
            expect(Treatment.last.send(key)).to eq value if ['sender', 'bcd_id', 'created_at'].exclude?(key)
          end

          expect(Treatment.last.status).to eq "from_dpd"
        end
      end
    end
  end

  context 'invalid params' do
    let(:invalid_params) { insert_params.merge({"name" => nil, 'transaction_queue_name'=>'transaction_queue_name'}) }
    let(:attributes) { treatment.attributes }

    describe "shouldn't update treatment" do
      let(:bad_id) {{'id'=>''}}
      let(:bad_dpd_id) {{'bcd_id'=>''}}

      describe 'invalid id' do
        it 'involve DPDErrorRaiser.raise' do
          expect(DPDMessageSender).to receive(:send).with('Wrong format of ids. Ids can be only numbers.', 'dpd.error')
          subject.new(bad_id).handle
        end
      end

      describe 'invalid dpd_id' do
        it 'involve DPDErrorRaiser.raise' do
          expect(DPDMessageSender).to receive(:send).with('Wrong format of ids. Ids can be only numbers.', 'dpd.error')
          subject.new(bad_dpd_id).handle
        end
      end

      describe 'not in database' do
        it 'involve DPDErrorRaiser.raise' do
          expect(DPDMessageSender).to receive(:send).with("Treatment doesn't exist in database.", 'dpd.error')
          subject.new(invalid_params).handle
        end
      end

      describe "with invalid params" do
        let!(:treatment) { create(:treatment, treatment_params) }
        let(:failure_response_text) { 'FAILURE' }

        it "shouldn't update" do
          allow(DPDMessageSender).to receive(:send)
          subject.new(invalid_params).handle
          expect(treatment.reload.attributes).to eq attributes
        end

        it 'should rollback if no version' do
          expect(DPDMessageSender).to receive(:send).with(failure_response_text, 'transaction_queue_name')
          subject.new(invalid_params).handle
        end

        it 'should output validation errors' do
          expect(DPDMessageSender).to receive(:send)
          subject.new(invalid_params).handle
        end
      end

      describe 'treatment exists, but with wrong status' do
        let!(:treatment) { create(:treatment, treatment_params.merge({'status' => 'declined', 'version' => '3'})) }

        it 'involve DPDErrorRaiser.raise' do
          expect(DPDMessageSender).to receive(:send).with('Treatment exists in BCD program, but with wrong status. (not current or from_dpd)', 'dpd.error')
          subject.new(valid_params).handle
        end
      end
    end
  end
end
