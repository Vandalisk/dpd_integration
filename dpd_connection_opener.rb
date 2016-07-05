module DPDConnectionOpener
  START_CONNECTION = 'Started RabbitMQ connection'.freeze
  CREATE_CHANNEL = 'Created channel RabbitMQ'.freeze
  CREATE_EXCHANGE = "Created exchange 'bcd-dpd'".freeze
  CREATE_QUEUE = 'Created queue bcd-queue'.freeze

  def open_connection
    $bunny_connection.with do |connection|
      connection.start
      Rails.logger.info START_CONNECTION

      @channel = connection.create_channel
      Rails.logger.info CREATE_CHANNEL

      @channel.queue('bcd-queue', durable: true)
      Rails.logger.info CREATE_QUEUE

      @exchange = @channel.topic('bcd-dpd', durable: true)
      Rails.logger.info CREATE_EXCHANGE
    end
  end
end
