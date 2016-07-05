class FromDPD::BaseHandler
  attr_reader :payload

  WRONG_STATUS = 'Item exists in BCD program, but with wrong status.'.freeze
  ERRORS_OCCURED = 'Some errors occured:'.freeze
  SUCCESSFULLY_CREATED = 'Item created!'.freeze
  SUCCESSFULLY_UPDATED = 'Item updated!'.freeze
  NOT_IN_DATABASE = "Item doesn't exist in database.".freeze
  ID_WRONG_FORMAT = 'Wrong format of id. Id can be only number.'.freeze
  IDS_WRONG_FORMAT = 'Wrong format of ids. Ids can be only numbers.'.freeze
  SUCCESS = 'SUCCESS'.freeze
  FAILURE = 'FAILURE'.freeze

  def initialize(payload)
    @payload = payload
    @response_text = FAILURE
  end

  def handle
    begin
      yield if block_given?
    rescue ActiveRecord::ActiveRecordError => e
      @response_text = FAILURE
    ensure
      DPDMessageSender.send(@response_text, payload['transaction_queue_name']) if payload['transaction_queue_name']
    end
  end

  def valid_id?
    /\A\d+\Z/ =~ @payload['id'].to_s
  end

  def data
    @data ||= shape_data
  end

  def shape_data
    @payload['id'] = @payload.delete('bcd_id') if @payload['bcd_id']
    @payload.select { |key, value| resource_class::FIELDS_FOR_RABBIT.include? (key) }
  end

  def resource_class
    raise "#resource_class needs to be implemented in ancestor's class"
  end

  def output_error(message = 'errors')
    DPDMessageSender.send(message, 'dpd.error')
    Rails.logger.info ERRORS_OCCURED
    Rails.logger.info message
  end
end
