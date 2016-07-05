require 'rails_helper'

RSpec.describe FromDPD::Treatments::InsertTreatmentHandler do
  subject { FromDPD::Treatments::InsertTreatmentHandler }
  let(:dpd_answers) { JSON.parse(File.read("spec/fixtures/dpd.json")) }

  context 'valid params' do
    let(:valid_params) { JSON.parse dpd_answers["treatment.insert"] }
    let!(:dpd_id) { valid_params['id'] }

    context 'no treatment in database' do
      it 'treatment count +1' do
        expect{ subject.new(valid_params).handle }.to change(Treatment, :count).by(1)
      end

      context 'fields must be the same' do
        before(:each){ subject.new(valid_params).handle }

        it 'status medication' do
          expect(Treatment.last.status).to eq 'from_dpd'
        end

        it 'dpd_id' do
          expect(Treatment.last.dpd_id).to eq dpd_id
        end

        it 'treatment_type' do
          expect(Treatment.last.treatment_type).to eq 'medication'
        end

        it 'name' do
          expect(Treatment.last.name).to eq valid_params['name']
        end
      end
    end

    context 'treatment status requested' do
      let!(:treatment) { create(:treatment, name: valid_params['name'], status: 'requested', dpd_id: dpd_id) }

      it 'updates current with status declined' do
        subject.new(valid_params).handle
        expect(treatment.reload.status).to eq 'declined'
      end

      it 'updates current with dpd_id nil' do
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

    context 'treatment status new' do
      let!(:treatment) { create(:treatment, name: valid_params['name'], status: 'new', dpd_id: dpd_id) }

      it 'updates current with status declined' do
        subject.new(valid_params).handle
        expect(treatment.reload.status).to eq 'declined'
      end

      it 'updates current with dpd_id nil' do
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

    context 'treatment with other status' do
      let!(:treatment) { create(:treatment, name: valid_params['name'], status: 'completed', dpd_id: dpd_id) }

      it 'involve DPDErrorRaiser.raise' do
        expect(DPDMessageSender).to receive(:send)
        subject.new(valid_params).handle
      end
    end
  end

  context 'invalid params' do
    let(:valid_params) { JSON.parse dpd_answers["treatment.insert"] }

     describe "shouldn't create treatment" do
      context "invalid id" do
        let(:invalid_params) { valid_params.merge([{"id"=> -1}, {"id"=> nil}].sample) }

        it "shouldn't create treatment" do
          allow(DPDMessageSender).to receive(:send)
          expect{ subject.new(invalid_params).handle }.not_to change(Treatment, :count)
        end

        it 'not exist' do
          allow(DPDMessageSender).to receive(:send)
          subject.new(invalid_params).handle
          expect(Treatment.find_by(name: valid_params['name'])).to eq nil
        end

        it 'involve DPDErrorRaiser.raise' do
          expect(DPDMessageSender).to receive(:send).with('Wrong format of id. Id can be only number.', 'dpd.error')
          subject.new(invalid_params).handle
        end
      end
    end
  end
end
