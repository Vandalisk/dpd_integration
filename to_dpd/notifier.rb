class ToDPD::Notifier
  attr_reader :exchange, :channel, :routing_key
  attr_accessor :response_routing_key

  include DPDResponseCatcher
  include DPDConnectionOpener
  include ActiveRecordChangers::TransactionSkipper

  MESSAGE_PUBLISHED = 'Published message to DPD'.freeze

  def initialize(routing_key)
    @routing_key = routing_key
    open_connection
  end

  def notify(object = nil)
    @object = object
    action = routing_key.split('.')[-1].capitalize
    klass = routing_key.split('.')[-2].capitalize
    Rails.logger.info '=' * 50
    Rails.logger.info "#{action} #{klass}"

    @response_routing_key = nil

    if block_given?
      remove_active_record_transaction_wrapper
      start_prepared_transaction { yield }
      response_routing_key = "transaction.#{uuid}"
    end

    send_message_to_dpd(@object, response_routing_key)

    if block_given?
      complete_prepared
      return_active_record_transaction_wrapper
    end
    Rails.logger.info MESSAGE_PUBLISHED
    Rails.logger.info '=' * 50
  end

  def start_prepared_transaction
    ActiveRecord::Base.connection.execute('BEGIN;')
    @object = yield
    @object.update_column(:version, @object.version + 1)
    ActiveRecord::Base.connection.execute("PREPARE TRANSACTION '#{uuid}'")
  end

  def complete_prepared
    response = get_first_message(response_routing_key)
    sql_command = (response && response['message'] == 'SUCCESS' ? "COMMIT PREPARED '#{uuid}'" : "ROLLBACK PREPARED '#{uuid}'")
    ActiveRecord::Base.connection.execute(sql_command)
  end

  private

  def send_message_to_dpd(object, response_routing_key)
    data = object.prepare_for_DPD
    data[:transaction_queue_name] = response_routing_key if response_routing_key
    Rails.logger.info "Data: #{data}"
    exchange.publish(data.to_json, routing_key: routing_key)
    Rails.logger.info "Routing key: #{routing_key}"
  end

  def uuid
    @uuid ||= SecureRandom.uuid
  end
end
