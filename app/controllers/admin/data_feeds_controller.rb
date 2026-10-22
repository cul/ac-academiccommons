# frozen_string_literal: true

module Admin
  class DataFeedsController < AdminController
    load_and_authorize_resource

    def update
      if @data_feed.update(data_feed_params)
        flash[:success] = 'updated'
        redirect_to action: :edit
      else
        flash[:error] = @data_feed.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    def create
      if @data_feed.save
        flash[:success] = 'Created!'
        redirect_to action: :edit, id: @data_feed
      else
        flash[:error] = @data_feed.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      key = @data_feed[:key]
      @data_feed.destroy!
      flash[:success] = "Data feed for '#{key}' has been deleted."
      redirect_to admin_data_feeds_path
    end

    private

    def data_feed_params
      params.require(:data_feed).permit(:key, search_fields_attributes: [:key, :value])
    end
  end
end
