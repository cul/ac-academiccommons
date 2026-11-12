# frozen_string_literal: true

namespace :ac do
  namespace :tokens do
    desc 'Email all contacts about imminently expiring tokens'
    task notify_expired: :environment do
      expiring_tokens = Token.where(has_been_notified: false, created_at: ..1.year.ago)
      expiring_tokens.each do |token|
        authorizable = token.authorizable
        if authorizable.authorizable_type == Token::AUTHORIZABLE_TYPE_API_CLIENT
          email = authorizable.contact_email
          name = 'Academic Commons User'
        else
          email = authorizable.email
          name = Cul::LDAP.new.find_by_uni(authorizable.uid).name
        end

        scope = token.scope
        expiration_date = token.created_at + 1

        begin
          UserMailer.token_expiration_warning(name: name, email: email, scope: scope,
                                              expiration_date: expiration_date).deliver_later
          token.update!(has_been_notified: true)
        rescue StandardError => e
          Rails.logger.error "Error Sending Email: #{e.message}"
          Rails.logger.error e.backtrace.join("\n ")
        end
      end
      Rails.logger.info "#{expiring_tokens.length} Token expiration notification(s) have been sent."
    end
  end
end
