class FromDPD::Treatments::DeleteTreatmentHandler < FromDPD::BaseHandler
  NOT_IN_DATABASE = "Treatment doesn't exist in database.".freeze

  def handle
    super do
      return output_error(ID_WRONG_FORMAT) unless !!valid_id?
      return output_error(NOT_IN_DATABASE) unless treatment

      ActiveRecord::Base.transaction do
        if treatment.decline! && treatment.update_column(:version, treatment.version + 1)
          @response_text = SUCCESS
          Rails.logger.info("Treatment with id #{treatment.id} successfully moved to history")
        else
          output_error("Treatment with id #{treatment.id} hasn't been deleted")
          raise ActiveRecord::Rollback
        end
        raise ActiveRecord::Rollback if treatment.version != data['version'].to_i
      end
    end
  end

  def resource_class
    Treatment
  end

  private

  def shape_data
    @payload['dpd_id'] = @payload.delete('id')
    super
  end

  def valid_id?
    super || /\A\d+\Z/ =~ @payload['bcd_id'].to_s
  end

  def treatment
    @treatment ||= Treatment.find_by("dpd_id = ? OR id = ?", data['dpd_id'].to_i, data['id'].to_i)
  end
end
