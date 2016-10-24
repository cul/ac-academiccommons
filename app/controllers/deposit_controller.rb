class DepositController < ApplicationController
  include Blacklight::SolrHelper

  SELF_DEPOSIT_DIR = "data/self-deposit-uploads"

  def submit
    if params[:acceptedAgreement] == "agree"
      Agreement.create!(
        :uni => params[:uni],
        :agreement_version => params["AC-agreement-version"],
        :name => params[:name],
        :email => params[:email]
      )

      deposit_dir = SELF_DEPOSIT_DIR
      deposit_dir = File.join(deposit_dir, params[:uni]) if params[:uni]

      filepath = UploadedFile.save(params[:file], deposit_dir, params[:file].original_filename)

      deposit = Deposit.create!(
        :agreement_version => params["AC-agreement-version"],
        :uni => params[:uni],
        :name => params[:name],
        :email => params[:email],
        :file_path => filepath,
        :title => params[:title],
        :authors => params[:author],
        :abstract => params[:abstr],
        :url => params[:url],
        :doi_pmcid => params[:doi_pmcid],
        :notes => params[:software]
      )

      begin
        Notifier.new_deposit(root_url, deposit).deliver
      rescue Net::SMTPFatalError, Net::SMTPSyntaxError, IOError, Net::SMTPAuthenticationError,
        Net::SMTPServerBusy, Net::SMTPUnknownError, TimeoutError => e

        Rails.logger.warn "Error sending new deposit notification email for deposit #{deposit.id}. ERROR: #{e.message}"
        Notifier.new_deposit(root_url, deposit, attach_deposit = false).deliver
      end
    else
      flash[:notice] = "You must accept the author rights agreement."
      redirect_to :action => "index"
    end
  end

  def submit_author_agreement
    if(params[:acceptedAgreement] == "agree")
      unival =  params[:uni]
      if(unival.blank?)
        unival= params[:nouni]
      end

      Agreement.create(
        :uni => unival,
        :agreement_version => params["AC-agreement-version"],
        :name => params[:name],
        :email => params[:email]
      )
      Notifier.new_author_agreement(params).deliver

      @message_1 = 'Author Agreement Accepted'
      @message_2 = 'Thank you for accepting our author agreement.'
    else
      flash[:notice] = "You must accept the author rights agreement."
      redirect_to :action => "agreement_only"
    end
  end


  # currently does not work and is not used.
  def submit_student_agreement

    if(params[:acceptedAgreement].empty?)
      flash[:notice] = "You must accept the author rights agreement."
      redirect_to :action => "student_theses_agreement_only"
    end

    StudentAgreement.create(
      :years_embargo => params[:years_embargo],
      :name => params[:name],
      :email => params[:email],
      :uni => params[:uni],
      :thesis_advisor => params[:thesis_advisor],
      :department => params[:department]
    )

    #attachments = Hash.new

    attachment_path = Rails.root.to_s + "/public/self-deposit/ETDagreementtext.pdf"


    #attachments.store('agreement.pdf', File.read(path))

    logger.info("=================  path: " +  attachment_path )


    Notifier.student_agreement(params[:uni], params[:name], params[:email], params[:thesis_advisor], params[:department],  params[:years_embargo], attachment_path).deliver

    @message_1 = 'Student Agreement Accepted'
    @message_2 = 'Thank you for accepting our student agreement.'
    render 'submit_author_agreement'
  end
end
