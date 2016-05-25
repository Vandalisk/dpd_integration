class FromDPD::Users::UpdateUserHandler < FromDPD::BaseHandler
  NOT_IN_DATABASE = "User doesn't exist in database.".freeze

  def handle
    return output_error(ID_WRONG_FORMAT) unless !!valid_id?
    return output_error(NOT_IN_DATABASE) unless user
    user.assign_attributes(data)
    user.valid? ? user.update_columns(data) : output_error(user.errors.full_messages.join("\n"))
  end

  def resource_class
    User
  end

  private

  def user
    @user ||= User.find_by(id: data['id'])
  end
end
