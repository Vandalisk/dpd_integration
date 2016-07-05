class FromDPD::Treatments::InsertTreatmentHandler < FromDPD::BaseHandler
  WRONG_STATUS = 'Treatment exists in BCD program, but with wrong status. (not requested or suggested)'.freeze
  SUCCESSFULLY_CREATED = 'Treatment created!'.freeze

  def handle
    super do
      return output_error(ID_WRONG_FORMAT) unless !!valid_id?
      ActiveRecord::Base.transaction do
        if treatment
          if treatment.requested? || treatment.new?
            move_current_create_new
          else
            return output_error(WRONG_STATUS)
          end
        else
          create_new_treatment_with_dpd_status
        end

        if new_treatment.save
          @response_text = SUCCESS
          Rails.logger.info(SUCCESSFULLY_CREATED)
        else
          output_error(new_treatment.errors.full_messages.join("\n"))
          raise ActiveRecord::Rollback
        end
      end
    end
  end

  def resource_class
    Treatment
  end

  private

  def treatment
    @treatment ||= Treatment.find_by(name: data['name'])
  end

  def shape_data
    @payload['dpd_id'] = @payload.delete('id')
    # TODO: What name is comming?
    sender = User.find_by(first_name: @payload['sender'])
    @payload['sender_id'] = sender.id if sender
    @payload['dpd_dosage'] = @payload.delete('dosage')

    super.merge(
      'status' => 'from_dpd',
      'treatment_type' => 'medication',
      'treatment_template' => TreatmentTemplate.find_by_name(@payload['name']),
      'dpd_id' => @payload['dpd_id']
    )
  end

  def move_current_create_new
    move_current_to_history!
    create_new_treatment_with_dpd_status
  end

  def move_current_to_history!
    if treatment.decline! && treatment.update_column(:version, treatment.version + 1)
      Rails.logger.info "Treatment with id #{treatment.id} successfully moved to history"
    else
      output_error "Something went wrong, treatment with id #{treatment.id} hasn't been declined"
      raise ActiveRecord::Rollback
    end
  end

  def create_new_treatment_with_dpd_status
    new_treatment
  end

  def new_treatment
    @new_treatment ||= Treatment.new(data)
  end
end
