module DPDResponseCatcher
  def get_first_message(response_routing_key)
    @response_queue = channel.queue(response_routing_key)
    @response_queue.bind(exchange, routing_key: response_routing_key)
    Rails.logger.info "Created and binded response queue with routing_key: #{response_routing_key}"

    response = nil

    subscribe(block: true, timeout: 10) do |delivery_info, properties, payload|
      Rails.logger.info "got message #{payload}"
      response = JSON.parse(payload) rescue nil
      channel.consumers[delivery_info.consumer_tag].cancel
    end
    @response_queue.delete
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
end
