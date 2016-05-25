class FromDPD::Users::UnsubscribeUserHandler < FromDPD::BaseHandler
  NOT_IN_DATABASE = "User doesn't exist in database.".freeze

  def handle
    return output_error(ID_WRONG_FORMAT) unless !!valid_id?
    return output_error(NOT_IN_DATABASE) unless user

    if user.unsubscribe!
      Rails.logger.info("Patient with id #{@payload['id']} successfully unsubscribed")
    else
      Rails.logger.info("Something went wrong, patient with id #{user.id} hasn't been unsubscribed")
    end
  end

  def resource_class
    User
  end

  private

  def user
    @user ||= User.find_by(id: @payload['id'])
  end
end
