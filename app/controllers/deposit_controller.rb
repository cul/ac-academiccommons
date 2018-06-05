class DepositController < ApplicationController
  include Blacklight::SearchHelper

  SELF_DEPOSIT_DIR = 'data/self-deposit-uploads'.freeze

  def submit
    if params[:acceptedAgreement] == 'agree'
      Agreement.create!(
        uni: params[:uni],
        agreement_version: params['AC-agreement-version'],
        name: params[:name],
        email: params[:email]
      )

      deposit_dir = SELF_DEPOSIT_DIR
      deposit_dir = File.join(deposit_dir, params[:uni]) if params[:uni]

      filepath = UploadedFile.save(params[:file], deposit_dir, params[:file].original_filename)

      deposit = Deposit.create!(
        agreement_version: params['AC-agreement-version'],
        uni: params[:uni],
        name: params[:name],
        email: params[:email],
        file_path: filepath,
        title: params[:title],
        authors: params[:author],
        abstract: params[:abstr],
        url: params[:url],
        doi_pmcid: params[:doi_pmcid],
        notes: params[:software]
      )

      begin
        Notifier.new_deposit(root_url, deposit).deliver
      rescue Net::SMTPFatalError, Net::SMTPSyntaxError, IOError, Net::SMTPAuthenticationError,
        Net::SMTPServerBusy, Net::SMTPUnknownError, TimeoutError => e

        Rails.logger.warn "Error sending new deposit notification email for deposit #{deposit.id}. ERROR: #{e.message}"
        Notifier.new_deposit(root_url, deposit, attach_deposit = false).deliver
      end
    else
      flash[:notice] = 'You must accept the author rights agreement.'
      redirect_to action: :index
    end
  end
end
