begin
  require "active_support/core_ext/array/extract_options"
rescue
  require "activesupport"
end
require 'net/http'
require 'net/http/post/multipart'

module Cul
  module Fedora
    class Server

      attr_reader :riurl, :riquery, :rilimit

      def initialize(*args)
        options = args.extract_options!
        @riurl = options[:riurl] || options["riurl"] || raise(ArgumentError, "Must provide riurl argument")
        @riquery = options[:riquery] || options["riquery"] || raise(ArgumentError, "Must provide riquery argument")
        @rilimit = options[:rilimit] || options["rilimit"] || ""
        @hc = options[:http_client] || options["http_client"]
        @logger = options[:logger] || options["logger"]
      end

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def item(uri)
        Item.new(:server => self, :uri => uri, :logger => logger)
      end

      def request(options= {})
        http_method = options.delete(:http_method)
        user = Rails.application.config.fedora["user"]
        password = Rails.application.config.fedora["password"]

        uri = request_path(options)
        params = uri[1] || {}
        uri = URI(uri[0])
        uri.query = URI.encode_www_form(params)
        req = Net::HTTP::Get.new(uri.request_uri)
        req.basic_auth user, password
        res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          http.request(req)
        end

        raise "Unsuccessful Request: #{res.message}" unless res.kind_of? Net::HTTPSuccess
        res.body
      end

      def post(options= {})
        user = Rails.application.config.fedora["user"]
        password = Rails.application.config.fedora["password"]
        content_type = options.delete(:content_type)
        body = options.delete(:body)
        http_client.set_auth(riurl, user, password)
        uri = request_path(options)[0]
        uri = URI(uri)
        req = Net::HTTP::Post.new(uri.request_uri)
        req.basic_auth user, password
        req.body = body
        req.content_type = content_type || 'text/xml'
        res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          http.request(req)
        end
      end

      def post_multipart(options= {})
        user = Rails.application.config.fedora["user"]
        password = Rails.application.config.fedora["password"]
        content_type = options[:mimeType] || options.delete(:content_type) || 'text/xml'
        body = options.delete(:body)
        http_client.set_auth(riurl, user, password)
        uri = request_path(options)
        params = uri[1]
        uri = URI(uri[0])
        params[:controlGroup] ||= 'M'
        # unfortunately FCR 3 seems to want the non-file params in the URI, and the body as multipart
        req = Net::HTTP::Post::Multipart.new(uri.request_uri + "?#{URI.encode_www_form(params)}", :file => UploadIO.new(body, content_type, options[:dsLabel]))
        req.basic_auth user, password
        res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          http.request(req)
        end
      end

      def request_path(options = {})
        sdef = options.delete(:sdef).to_s
        pid = options.delete(:pid).to_s
        request = (options.delete(:request) || "").to_s
        method = (options.delete(:method) || "/get").to_s

        sdef = "/" + sdef unless sdef.empty?
        pid = "/" + pid unless pid.empty?
        request = "/" + request.to_s


        uri = @riurl + method + pid + sdef + request
        query = options
        return [uri, query]
      end

      private

      def http_client
        @hc ||= HTTPClient.new()
        @hc
      end

    end
  end
end
