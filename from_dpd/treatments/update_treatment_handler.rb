class FromDPD::Treatments::UpdateTreatmentHandler < FromDPD::BaseHandler
  WRONG_STATUS = 'Treatment exists in BCD program, but with wrong status. (not current or from_dpd)'.freeze
  SUCCESSFULLY_UPDATED = 'Treatment updated!'.freeze
  SUCCESSFULLY_CREATED = 'Treatment created!'.freeze
  COULDNT_UPDATE = "Couldn't update treatment".freeze
  NOT_IN_DATABASE = "Treatment doesn't exist in database.".freeze
  ALL_STATUSES = ['new', 'requested', 'active', 'from_dpd'].freeze

  def handle
    ActiveRecord::Base.transaction do
      return output_error(IDS_WRONG_FORMAT) unless !!valid_id?
      return output_error(NOT_IN_DATABASE) unless treatment
      treatment.assign_attributes(data)
      return output_error(treatment.errors.full_messages.join("\n")) unless treatment.valid?
      ALL_STATUSES.include?(treatment.status_was) ? check_and_update : output_error(WRONG_STATUS)
    end
  end

  def resource_class
    Treatment
  end

  private

  def check_and_update
    if treatment.status_was == 'from_dpd'
      unless treatment.update_columns(data)
        output_error COULDNT_UPDATE
        raise ActiveRecord::Rollback
      end
    else
      move_current_create_new
    end
    Rails.logger.info SUCCESSFULLY_UPDATED
  end

  def id
    @id ||= @payload['bcd_id']
  end

  def move_current_create_new
    move_current_to_history!
    create_new_treatment_with_dpd_status
  end

  def move_current_to_history!
    if treatment.decline!
      Rails.logger.info "Treatment with id #{treatment.id} successfully moved to history"
    else
      output_error "Something went wrong, treatment with id #{treatment.id} hasn't been declined"
      raise ActiveRecord::Rollback
    end
  end

  def create_new_treatment_with_dpd_status
    data['name'] = treatment.name unless data.key?('name')
    new_treatment = Treatment.new(data.merge(status: 'from_dpd', dpd_id: data['dpd_id']))
    if new_treatment.save
      Rails.logger.info(SUCCESSFULLY_CREATED)
    else
      output_error(treatment.errors.full_messages.join("\n"))
      raise ActiveRecord::Rollback
    end
  end

  def valid_id?
    super || /\A\d+\Z/ =~ @payload['bcd_id'].to_s
  end

  def treatment
    @treatment ||= Treatment.find_by("dpd_id = ? OR id = ?", data['dpd_id'].to_i, id.to_i)
  end

  def shape_data
    sender = User.find_by(first_name: @payload['sender'])

    @payload['sender_id'] = sender.id if sender
    @payload['dpd_id'] = @payload.delete('id')
    @payload['dpd_dosage'] = @payload['dosage']
    @payload['date_end'] = check_time @payload['date_end']
    @payload['date_start'] = check_time @payload['date_start']

    super
  end

  def check_time(time_value)
    Date.parse time_value rescue nil
  end
end
