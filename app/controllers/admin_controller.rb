class AdminController < ApplicationController
  authorize_resource  if: :root_admin_controller?
  check_authorization unless: :root_admin_controller?

  layout 'admin'

  private

  def root_admin_controller?
    request.controller_class == AdminController
  end
end
