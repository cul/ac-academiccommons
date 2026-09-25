# frozen_string_literal: true

module Admin
  class DataFeedsController < AdminController
    load_and_authorize_resource # We want only admin to be able to edit datafeed values
  end
end
