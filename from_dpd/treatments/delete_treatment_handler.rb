class FromDPD::Treatments::DeleteTreatmentHandler < FromDPD::BaseHandler
  NOT_IN_DATABASE = "Treatment doesn't exist in database.".freeze

  def handle
    return output_error(ID_WRONG_FORMAT) unless !!valid_id?
    return output_error(NOT_IN_DATABASE) unless treatment

    if treatment.decline!
      Rails.logger.info("Treatment with id #{id} successfully moved to history")
    else
      output_error("Treatment with id #{treatment.id} hasn't been deleted")
    end
  end

  def resource_class
    Treatment
  end

  private

  def valid_id?
    super || /\A\d+\Z/ =~ id.to_s
  end

  def id
    @id ||= @payload['bcd_id']
  end

  def treatment
    @treatment ||= Treatment.find_by("dpd_id = ? OR id = ?", data['dpd_id'].to_i, id.to_i)
  end

  def shape_data
    @payload['dpd_id'] = @payload.delete('id')
    @payload
  end
end
