class FromDPD::AbstractHandler
  def self.handle(payload, routing_key)
    keys = routing_key.split('.')[1..-1]
    "FromDPD::#{keys.first.pluralize.capitalize}::#{keys.reverse.map(&:capitalize).join}Handler".constantize.new(payload).handle
  end
end
