require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do

  describe '#is_bot?' do
    context 'return true' do
      it 'when user agent is a bot' do
        allow(VoightKampff).to receive(:bot?).and_return(true)
        expect(controller.is_bot?('yahoo')).to be true
        expect(controller.is_bot?('-')).to be true
      end

      it 'when user agent name is empty' do
        allow(VoightKampff).to receive(:bot?).and_return(true)
        expect(controller.is_bot? '').to be true
      end
    end

    context 'returns false' do
      it 'when user agent is not a bot' do
        allow(VoightKampff).to receive(:bot?).and_return(false)
        expect(controller.is_bot?('columbia')).to be false
      end
    end
  end
end
