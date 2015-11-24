class Message < MailForm::Base

  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :first_name, :last_name, :email, :subject, :intl_prop, :ntl_intl_prop, :kind, :url, :infringe_url, :comments, :signature, :check_one, :check_two, :check_three, :evidence
  attributes :evidence, :attachment => true
  attributes :nickname,   :captcha => true



  validates :email, :first_name, :last_name, :intl_prop, :kind, :url, :infringe_url, :evidence, :signature, :check_one, :check_two, :check_three, :presence => true
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
      :to => "Megan.Oneill38@gmail.com",
      :from => %("#{last_name}, #{first_name}" <#{email}>)
    }
  end

  def content_check
    c_type = self.evidence.content_type
    if c_type == "application/pdf" || c_type == "image/png" || c_type == "image/jpg" || c_type == "image/jpeg"
      return true
    else
      return false
    end
  end



end