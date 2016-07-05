class FromDPD::Synchronizations::CheckSynchronizationHandler
  attr_reader :payload

  def initialize(payload)
    @payload = payload
  end

  def handle
    dpd_objects = payload.deep_symbolize_keys![:objects]

    @not_synchronized_treatments = Treatment.where(synchronized: false).to_a

    dpd_objects.each do |dpd_object|
      if dpd_object[:model] == 'user'
        handle_user(dpd_object)
      elsif dpd_object[:model] == 'treatment'
        handle_treatment(dpd_object)
      end
    end

    send_not_synchronized_objects_to_dpd

    DPDMessageSender.send(dpd_objects, payload[:queue_name])
  end

  def handle_user(dpd_object)
    bcd_user = User.find(dpd_object[:id]) rescue nil
    if dpd_object[:version].to_i == bcd_user.version
      bcd_user.update_column(:synchronized, true)
      dpd_object[:status] = nil
      dpd_object[:success] = true
    elsif dpd_object[:version].to_i < bcd_user.version
      ToDPD::Notifier.new('dpd.user.update').notify(bcd_user)
      dpd_object[:status] = 'sent'
      dpd_object[:success] = false
    else
      dpd_object[:status] = 'request'
      dpd_object[:success] = false
    end
  end

  def handle_treatment(dpd_object)
    bcd_treatment = Treatment.find_by('dpd_id = ? OR id = ?', dpd_object[:dpd_id], dpd_object[:id]) rescue nil
    if bcd_treatment
      @not_synchronized_treatments.delete(bcd_treatment)
      if dpd_object[:version].to_i == bcd_treatment.version
        bcd_treatment.update_column(:synchronized, true)
        dpd_object[:status] = nil
        dpd_object[:success] = true
      elsif dpd_object[:version].to_i < bcd_treatment.version
        if bcd_treatment.status == 'declined'
          ToDPD::Notifier.new('dpd.treatment.delete').notify(bcd_treatment)
        else
          ToDPD::Notifier.new('dpd.treatment.update').notify(bcd_treatment)
        end
        dpd_object[:status] = 'sent'
        dpd_object[:success] = false
      else
        dpd_object[:status] = 'request'
        dpd_object[:success] = false
      end
    else
      dpd_object[:status] = 'request'
      dpd_object[:success] = false
    end
  end

  def send_not_synchronized_objects_to_dpd
    @not_synchronized_treatments.each do |treatment|
      ToDPD::Notifier.new('dpd.treatment.prescribe').notify(treatment)
    end
  end
end
