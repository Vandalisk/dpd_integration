class DPDMessageSender
  START_CONNECTION = 'Started RabbitMQ connection'.freeze
  CREATE_CHANNEL = 'Created channel RabbitMQ'.freeze
  CREATE_EXCHANGE = "Created exchange 'bcd-dpd'".freeze

  def self.send(message, routing_key = 'dpd.message')
    $bunny_connection.with do |connection|
      connection.start
      Rails.logger.info START_CONNECTION

      channel = connection.create_channel
      Rails.logger.info CREATE_CHANNEL

      exchange = channel.topic("bcd-dpd", durable: true)
      Rails.logger.info CREATE_EXCHANGE

      exchange.publish(message.to_json, routing_key: routing_key)
      Rails.logger.info "published to DPD: #{message.inspect}"
    end
  end
end
