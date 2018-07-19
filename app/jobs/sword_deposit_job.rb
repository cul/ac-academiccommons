class SwordDepositJob < ApplicationJob
  queue_as :default

  def perform(deposit)
    # Check that we are allowed to send data to sword in this environment.
    # retrun unless Rails.application.config.send_deposits_to_sword == true

    # Check that we have all the credentials necessary, url, collection_slug, username, password
    # Rails.application.config_for(:secrets)['sword']

    # Send request to SWORD

    # For testing right now, we are just sending the file to cmg2228@columbia.edu
    NotificationMailer.deposit_sent_to_sword(deposit, 'cmg2228@columbia.edu').deliver
  end
end
