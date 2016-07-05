class LabResultsFetcher
  attr_reader :channel, :exchange
  include DPDConnectionOpener
  include DPDResponseCatcher

  def initialize
    open_connection
  end

  def fetch(params)
    request_routing_key = generate_request_routing_key
    response_routing_key = "bcd.lab_results.response.#{request_routing_key.split('.')[-1]}"

    exchange.publish(params.to_json, routing_key: request_routing_key)
    Rails.logger.info "Published request to DPD with routing_key: #{request_routing_key}"
    Rails.logger.info "Params: #{params.to_json}"

    get_first_message(response_routing_key)
  end

  private

  def generate_request_routing_key
    "dpd.lab_results.request.#{SecureRandom.uuid}"
  end
end
