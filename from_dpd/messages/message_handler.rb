class FromDPD::Messages::MessageHandler < FromDPD::BaseHandler
  def handle
    DPDMessageSender.send(response, generate_routing_key)
  end

  def resource_class
    Message
  end

  private

  def response
    Message.prepare_for_rabbit(data)
  end

  def generate_routing_key
    "dpd.messages.response.#{SecureRandom.uuid}"
  end
end
