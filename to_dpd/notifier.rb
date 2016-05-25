class ToDPD::Notifier
  attr_reader :routing_key, :object, :exchange
  START_CONNECTION = 'Started RabbitMQ connection'.freeze
  CREATE_CHANNEL = 'Created channel RabbitMQ'.freeze
  CREATE_EXCHANGE = "Created exchange 'bcd-dpd'".freeze
  CREATE_QUEUE = 'Created queue bcd-queue'.freeze
  MESSAGE_PUBLISHED = 'Published message to DPD'.freeze

  def initialize(routing_key, object)
    @routing_key = routing_key
    @object = object

    $bunny_connection.with do |connection|
      connection.start
      Rails.logger.info START_CONNECTION

      channel = connection.create_channel
      Rails.logger.info CREATE_CHANNEL

      @exchange = channel.topic('bcd-dpd', durable: true)
      Rails.logger.info CREATE_EXCHANGE

      channel.queue('bcd-queue', durable: true)
      Rails.logger.info CREATE_QUEUE
    end
  end

  def notify
    action = routing_key.split('.')[-1].capitalize
    klass = routing_key.split('.')[-2].capitalize

    Rails.logger.info "="*50
    Rails.logger.info "#{action} #{klass}"

    data = object.prepare_for_DPD
    Rails.logger.info "Data: #{data}"

    exchange.publish(data.to_json, routing_key: routing_key)
    Rails.logger.info "Routing key: #{routing_key}"

    Rails.logger.info MESSAGE_PUBLISHED
    Rails.logger.info "="*50
  end
end
