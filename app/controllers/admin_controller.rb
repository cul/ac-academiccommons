class AdminController < ApplicationController
  authorize_resource
  layout 'admin'
end
