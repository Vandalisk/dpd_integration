class DPDMessageSender
  extend DPDConnectionOpener

  def self.send(message, routing_key = 'dpd.message')
    open_connection unless @exchange
    @exchange.publish(message.to_json, routing_key: routing_key)
    Rails.logger.info "published to DPD: #{message.inspect}"
  end
end
