class FromDPD::Users::SubscribeUserHandler < FromDPD::BaseHandler
  USER_CREATED = 'User created!'.freeze

  def handle
    super do
      return output_error(ID_WRONG_FORMAT) unless !!valid_id?

      ActiveRecord::Base.transaction do
        if user.save
          user_created
          @response_text = SUCCESS
        else
          output_error(user.errors.full_messages.join("\n"))
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
    @user ||= find_or_create
  end

  def find_or_create
    temp_user = User.find_by(PHN: data['PHN'])
    if temp_user
      temp_user.version += 1
      temp_user.active = true
      temp_user
    else
      User.new(data.merge(role: 'patient'))
    end
  end

  def user_created
    Rails.logger.info USER_CREATED
    send_invitation
  end

  def send_invitation
    token = user.generate_token!('invite')
    UserMailer.invitation(user: user, token: token).deliver_later
  end
end
