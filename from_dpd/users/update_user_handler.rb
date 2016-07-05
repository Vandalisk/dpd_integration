class FromDPD::Users::UpdateUserHandler < FromDPD::BaseHandler
  NOT_IN_DATABASE = "User doesn't exist in database.".freeze

  def handle
    super do
      return output_error(ID_WRONG_FORMAT) unless !!valid_id?
      return output_error(NOT_IN_DATABASE) unless user

      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback if user.version != data['version'].to_i - 1

        user.assign_attributes(data)

        if user.save
          @response_text = SUCCESS
        else
          output_error(user.errors.full_messages.join("\n"))
          raise ActiveRecord::Rollback
        end
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
