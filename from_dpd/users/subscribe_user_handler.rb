class FromDPD::Users::SubscribeUserHandler < FromDPD::BaseHandler
  USER_CREATED = 'User created!'.freeze

  def handle
    return output_error(ID_WRONG_FORMAT) unless !!valid_id?
    user.save ? user_created : output_error(user.errors.full_messages.join("\n"))
  end

  def resource_class
    User
  end

  private

  def valid_id?
    /\A\d+\Z/ =~ @payload['id'].to_s
  end

  def user
    @user ||= User.new(data.merge(role: 'patient'))
  end

  def user_created
    Rails.logger.info USER_CREATED
    send_invitation
  end

  def send_invitation
    token = user.generate_token!('invite')
    UserMailer.invitation(user: @user, token: token).deliver_later
  end
end
