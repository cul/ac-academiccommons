class EmailsController < ApplicationController

  include StatisticsHelper

  before_filter :require_user
  before_filter :require_admin


  def get_csv_email_form


    logger.info("=================== get_simple_email_form =================== ")



    message = ''

    if(params[:f])
      params[:f].each do |key, value|

          # logger.info( "~~~~~~~~~ " + facet_names[key.to_s] + " = " + value.first.to_s )
#
          # message = message + facet_names[key.to_s] + " = " + value.first.to_s + LINE_BRAKER
      end
    end

    # params.each do |key, value|
        # logger.info("pram: " + key + " = " + value.to_s)
    # end


    hidden_params = Hash.new

    form_url = '/statistics/send_csv_report?' + (params[:search_query] || '')

    render :template => 'emails/_simple_email_form', layout: false,
           :locals => { :form_url => form_url,
                        :email_from => Rails.application.config.emails['mail_deliverer'],
                        :email_to => '',
                        :email_subject => 'statistics report',
                        :email_message => message,
                        :hidden_params => hidden_params }

  end

end
