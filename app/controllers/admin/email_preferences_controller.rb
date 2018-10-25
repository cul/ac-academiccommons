module Admin
  class EmailPreferencesController < AdminController
    load_and_authorize_resource

    def index
      @email_preferences = EmailPreference.order(created_at: :desc)
    end

    def show
      @email_preference ||= EmailPreference.find(params[:id])
    end

    def new
      @email_preference ||= EmailPreference.new
    end

    def create
      @email_preference = EmailPreference.new(email_preference_params)
      if @email_preference.save
        flash[:success] = 'Successfully created email preference.'
        render :show
      else
        flash[:error] = @email_preference.errors.full_messages.to_sentence
        render :new
      end
    end

    def edit
      @email_preference ||= EmailPreference.find(params[:id])
    end

    def update
      @email_preference = EmailPreference.find(params[:id])

      respond_to do |f|
        if @email_preference.update_attributes(email_preference_params)
          f.html do
            flash[:success] = 'Successfully updated email preference.'
            render :show
          end
          f.json { render json: { message: 'Successfully updated email preference.' }.to_json, status: 200 }
        else
          f.html do
            flash[:error] = @email_preference.errors.full_messages.to_sentence
            render :edit
          end
          f.json { render json: { message: @email_preference.errors.full_messages.to_sentence }.to_json, status: 500 }
        end
      end
    end

    def destroy
      @email_preference = EmailPreference.find(params[:id])
      @email_preference.destroy
      flash[:success] = 'Successfully destroyed email preference.'
      redirect_to admin_email_preferences_url
    end

    private

    def email_preference_params
      params.require(:email_preference).permit(:uni, :unsubscribe, :email)
    end
  end
end
