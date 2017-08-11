require 'rails_helper'

RSpec.describe AcademicCommons::Embargoes do
  let(:class_rig) { Class.new { include AcademicCommons::Embargoes } }
  let(:dummy_class) { class_rig.new }

  describe '#free_to_read?' do
    let(:document) do
      SolrDocument.new(
        { id: 'test:obj', free_to_read_start_date: date, object_state_ssi: 'A'}, {}
      )
    end

    subject { dummy_class.free_to_read?(document) }

    context 'when free_to_read_state_date is today' do
      let(:date) { Date.current.strftime('%Y-%m-%d') }
      it { is_expected.to eql true}
    end

    context 'when free_to_read_state_date is after today' do
      let(:date) { (Date.current + 1.day).strftime('%Y-%m-%d') }
      it { is_expected.to eql false }
    end

    context 'when free_to_read_state_date is before today' do
      let(:date) { (Date.current - 1.day).strftime('%Y-%m-%d') }
      it { is_expected.to eql true }
    end
  end

  describe '#available_today?' do
    it 'when embargo date is today true is returned' do
      expect(dummy_class.available_today?(Date.current)).to eq true
    end

    it 'when embargo date is after today, false is returned' do
      expect(dummy_class.available_today?(Date.current + 1.day)).to eq false
    end

    it 'when embargo date is before today, true is returned' do
      expect(dummy_class.available_today?(Date.current - 1.day)).to eq true
    end
  end
end
