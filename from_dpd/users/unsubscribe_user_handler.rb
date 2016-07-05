class FromDPD::Users::UnsubscribeUserHandler < FromDPD::BaseHandler
  NOT_IN_DATABASE = "User doesn't exist in database.".freeze

  def handle
    super do
      return output_error(ID_WRONG_FORMAT) unless !!valid_id?
      return output_error(NOT_IN_DATABASE) unless user

      ActiveRecord::Base.transaction do
        if user.unsubscribe! && user.update_column(:version, user.version + 1)
          Rails.logger.info("Patient with id #{@payload['id']} successfully unsubscribed")
          @response_text = SUCCESS
        else
          output_error("Something went wrong, patient with id #{user.id} hasn't been unsubscribed")
        end

        raise ActiveRecord::Rollback if user.version != data['version'].to_i
      end
    end
  end

  def resource_class
    User
  end

  private

  def user
    @user ||= User.find_by(id: data['id'])
  end
end
