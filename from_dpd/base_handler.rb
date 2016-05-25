class FromDPD::BaseHandler
  WRONG_STATUS = 'Item exists in BCD program, but with wrong status.'.freeze
  ERRORS_OCCURED = 'Some errors occured:'.freeze
  SUCCESSFULLY_CREATED = 'Item created!'.freeze
  SUCCESSFULLY_UPDATED = 'Item updated!'.freeze
  NOT_IN_DATABASE = "Item doesn't exist in database.".freeze
  ID_WRONG_FORMAT = 'Wrong format of id. Id can be only number.'.freeze
  IDS_WRONG_FORMAT = 'Wrong format of ids. Ids can be only numbers.'.freeze

  def initialize(payload)
    @payload = payload
  end

  def valid_id?
    /\A\d+\Z/ =~ @payload['id'].to_s
  end

  def data
    @data ||= shape_data
  end

  def shape_data
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
