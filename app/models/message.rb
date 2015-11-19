class Message < MailForm::Base

  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :first_name, :last_name, :email, :subject, :intl_prop, :ntl_intl_prop, :kind, :url, :infringe_url, :comments, :signature, :check_one, :check_two, :check_three, :evidence
  attributes :evidence, :attachment => true
  attributes :nickname,   :captcha => true



  validates :email, :first_name, :last_name, :intl_prop, :kind, :url, :infringe_url, :evidence, :signature, :presence => true
  validates :email, :format => { :with => %r{.+@.+\..+} }, :allow_blank => false

  
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end

   def headers
    {
      :subject => "DMCA Takedown Form",
      :to => "megan.oneill38@gmail.com",
      :from => %("#{last_name}, #{first_name}" <#{email}>)
    }
  end



end