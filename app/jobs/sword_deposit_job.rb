class SwordDepositJob < ApplicationJob
  queue_as :default

  def perform(deposit)
    # Check that we are allowed to send data to sword in this environment.
    return unless Rails.application.config.sending_deposits_to_sword

    # Check that we have all the credentials necessary: url, user, password
    credentials =  Rails.application.config_for(:secrets)['sword']
    raise 'Missing SWORD credentials' unless ['url', 'user', 'password'].all? { |k| credentials[k].present? }

    # Send request to SWORD
    begin
      response = HTTP.timeout(:global, write: 60, connect: 60, read: 60)
                     .basic_auth(user: credentials['user'], pass: credentials['password'])
                     .headers(content_type: 'application/zip')
                     .post(credentials['url'], body: deposit.sword_zip)
    rescue StandardError => e
      message = "There was an error deliving a SWORD deposit for deposit record id: #{deposit.id}. Please check logs."
      ErrorMailer.sword_deposit_error('Error Delivering SWORD Deposit', message)
      raise e
    end

    if response.code == 201
      # Given the response, save the hyacinth identifier in the Deposit object
      Rails.logger.debug "Response body from SWORD: #{response.body}"
      identifier = JSON.parse(response.body.to_s)['item_pid']
      deposit.update!(hyacinth_identifier: identifier)

      # Start job to delete any files associated with the deposit object.
      deposit.files.destroy_all

      # Send notification to AC staff.
      AdministrativeMailer.new_deposit(deposit).deliver
    else
      message = "There was an error deliving a SWORD deposit for deposit record id: #{deposit.id}. SWORD deposit returned a status code of #{response.code}. Please check logs."
      ErrorMailer.sword_deposit_error('Error Delivering SWORD Deposit', message)
    end
  end
end
