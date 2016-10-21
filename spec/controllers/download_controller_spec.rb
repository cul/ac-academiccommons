require 'rails_helper'

RSpec.describe DownloadController, :type => :controller do
  describe 'GET download_log' do
    include_context 'log'

   include_examples 'authorization required' do
     let(:request) { get :download_log, :log_folder => 'ac-indexing', :id => id }
   end
  end
end
