module AuthlogicWind
  module Session
    def self.included(klass)
      klass.class_eval do
        extend Config
        include Methods
      end
    end
    
    module Config
      # The host of your WIND server.
      #
      # * <tt>Default:</tt> nil
      # * <tt>Accepts:</tt> String
      def wind_host(value = nil)
        rw_config(:wind_host, value)
      end
      alias_method :wind_host=, :wind_host

      # The service name of your WIND server.
      #
      # * <tt>Default:</tt> nil
      # * <tt>Accepts:</tt> String
      def wind_service(value = nil)
        rw_config(:wind_service, value)
      end
      alias_method :wind_service=, :wind_service
      
   
      def find_by_wind_method(value = nil)
        rw_config(:find_by_wind_method, value, :find_by_wind_login)
      end
      alias_method :find_by_wind_method=, :find_by_wind_method
   
      
      # Add this in your Session object to Auto Register a new user using openid via sreg
      def auto_register(value=nil)
        rw_config(:auto_register,value,false)
      end
      
      alias_method :auto_register=,:auto_register
      
      # Add this in your Session object to Auto Register a new user using openid via sreg
      def login_only_with_wind(value=nil)
        rw_config(:login_only_with_wind,value,false)
      end
      
      alias_method :login_only_with_wind=,:login_only_with_wind



    end
    
    
    module Methods
      def self.included(klass)
        klass.class_eval do
          validate :validate_by_wind, :if => :authenticating_with_wind?
        end
      end

      def credentials=(value)
        super
        values = value.is_a?(Array) ? value : [value]
        hash = values.first.is_a?(Hash) ? values.first.with_indifferent_access : nil
        self.record = hash[:priority_record] if !hash.nil? && hash.key?(:priority_record)
      end
      
      def save(&block)
        block = nil if redirecting_to_wind_server?
        super(&block)
      end
      
      #TODO: why is this so hacky?
      def build_callback_url
        wind_controller.url_for(:controller => wind_controller.controller_name) + "/create"
      end
      
      
      private
        def authenticating_with_wind?
          # Initial request when user presses one of the button helpers
          (controller.params && !controller.params[:login_with_wind].blank?) ||
          # When the oauth provider responds and we made the initial request
          (wind_response && controller.session && controller.session[:wind_request_class] == self.class.name)
        end
        
        def using_wind?
          respond_to(:wind_login) && !wind_login.blank?
        end
      
        def authenticate_with_wind
          
          if @record
            self.attempted_record = record

            if !attempted_record
	      errors[:base] << "Could not find user in our database."
            end

          else
            uni = generate_verified_login
            if uni
              self.attempted_record = search_for_record(find_by_wind_method, uni) 
              if !attempted_record
                if auto_register?
                  self.attempted_record = klass.new(:login => uni, :wind_login => uni)
                  self.attempted_record.reset_persistence_token
                else
		  errors[:base] << "Could not find UNI #{uni} in our database."
                end
              end
            else
		errors[:base] << "WIND Ticket did not verify properly."
            end  
          end
          
        end
        
        def wind_host
          self.class.wind_host
        end
        
        def wind_service
          self.class.wind_service
        end

        def find_by_wind_method
          self.class.find_by_wind_method
        end

        def auto_register?
          self.class.auto_register == true
        end
        
        def login_only_with_wind?
          self.class.login_only_with_wind == true
        end
 
        
        def validate_by_wind
          validate_email_field = false
          if wind_response.blank?
            redirect_to_wind
          else
            authenticate_with_wind
          end
        end


        def redirecting_to_wind_server?
          authenticating_with_wind? && wind_response.blank?
        end


        def redirect_to_wind
          # Store the class which is redirecting, so we can ensure other classes
          # don't get confused and attempt to use the response
          wind_controller.session[:wind_request_class] = self.class.name

          # Tell our rack callback filter what method the current request is using
          wind_controller.session[:wind_callback_method]      = wind_controller.request.method
          
          wind_controller.redirect_to "https://#{wind_host}/login?destination=#{CGI.escapeHTML(build_callback_url)}&service=#{CGI.escapeHTML(wind_service)}"
        end


        def generate_verified_login

          if (ticketid = wind_controller.params[:ticketid])
                uri = URI.parse("https://#{wind_host}/validate?ticketid=#{ticketid}")
                http = Net::HTTP.new(uri.host, uri.port)
                http.use_ssl = true
		request = Net::HTTP::Get.new(uri.request_uri)
		req_obj = http.request(request)
                data = req_obj.body
                uni = data.split[1] unless data[0,2] == "no"
                return uni
          else
            nil
          end
        end


        def wind_response
          wind_controller.params && wind_controller.params[:ticketid]
        end


        def wind_controller
          is_auth_session? ? controller : session_class.controller
        end


        def wind
          is_auth_session? ? self.class.wind_consumer : session_class.wind_consumer
        end


        def is_auth_session?
          self.is_a?(Authlogic::Session::Base)
        end


    end
  
  end
  
end
