class LabResultsFetcher
  attr_reader :connection, :channel, :exchange
  def initialize
    $bunny_connection.with do |connection|
      @connection = connection

      connection.start
      Rails.logger.info "Started RabbitMQ connection"

      @channel = connection.create_channel
      Rails.logger.info "Created channel RabbitMQ"

      @exchange = @channel.topic("bcd-dpd", durable: true)
      Rails.logger.info "Created exchange 'bcd-dpd'"
    end
  end

  def fetch(params)
    request_routing_key = generate_request_routing_key
    response_routing_key = "bcd.lab_results.response.#{request_routing_key.split('.')[-1]}"

    @response_queue = channel.queue(response_routing_key)
    @response_queue.bind(exchange, routing_key: response_routing_key)
    Rails.logger.info "Created and binded response queue with routing_key: #{response_routing_key}"

    exchange.publish(params.to_json, routing_key: request_routing_key)
    Rails.logger.info "Published request to DPD with routing_key: #{request_routing_key}"
    Rails.logger.info "Params: #{params.to_json}"

    response = nil

    subscribe(block: true, timeout: 10) do |delivery_info, properties, payload|
      Rails.logger.info "got message #{payload}"
      response = JSON.parse payload
      channel.consumers[delivery_info.consumer_tag].cancel
    end

    response
  end

  private

  def subscribe(opts = {block: false}, &block)
    ctag = opts.fetch(:consumer_tag, channel.generate_consumer_tag)
    consumer = Bunny::Consumer.new(channel,@response_queue,ctag)

    consumer.on_delivery(&block)
    channel.basic_consume_with(consumer)

    if opts[:block]
      channel.work_pool.join(opts[:timeout])
    end
  end

  def generate_request_routing_key
    "dpd.lab_results.request.#{SecureRandom.uuid}"
  end
end
