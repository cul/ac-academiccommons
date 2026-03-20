require "rails_helper"

RSpec.describe StatisticsSummary, type: :model do
  subject(:summary) do
    described_class.new(
      identifier: "user_123",
      event:      "View",
      year:       2025,
      month:      3,
      count:      10
    )
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(summary).to be_valid
    end

    %i[identifier event year month count].each do |attr|
      it "is invalid without #{attr}" do
        summary.public_send(:"#{attr}=", nil)
        expect(summary).not_to be_valid
        expect(summary.errors[attr]).to include("can't be blank")
      end
    end

    describe "month" do
      it "is invalid when less than 1" do
        summary.month = 0
        expect(summary).not_to be_valid
      end

      it "is invalid when greater than 12" do
        summary.month = 13
        expect(summary).not_to be_valid
      end

      (1..12).each do |m|
        it "is valid for month #{m}" do
          summary.month = m
          expect(summary).to be_valid
        end
      end
    end

    describe "year" do
      it "is invalid for a non-positive year" do
        summary.year = 0
        expect(summary).not_to be_valid
      end

      it "is valid for a positive year" do
        summary.year = 2024
        expect(summary).to be_valid
      end
    end

    describe "count" do
      it "is invalid when negative" do
        summary.count = -1
        expect(summary).not_to be_valid
      end

      it "is valid when zero" do
        summary.count = 0
        expect(summary).to be_valid
      end
    end

    describe "uniqueness" do
      it "is invalid when a duplicate identifier/event/year/month exists" do
        summary.save!
        duplicate = described_class.new(
          identifier: summary.identifier,
          event:      summary.event,
          year:       summary.year,
          month:      summary.month,
          count:      99
        )
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:identifier]).to include("has already been taken")
      end

      it "is valid with the same identifier/event/year but a different month" do
        summary.save!
        different_month = described_class.new(
          identifier: summary.identifier,
          event:      summary.event,
          year:       summary.year,
          month:      summary.month + 1,
          count:      5
        )
        expect(different_month).to be_valid
      end
    end
  end

  describe ".increment!" do
    subject(:increment!) do
      described_class.increment!(
        identifier: "user_123",
        event:      "View",
        year:       2024,
        month:      3
      )
    end

    let(:record) { StatisticsSummary.find_by(identifier: "user_123", event: "View", year: 2024, month: 3) }

    context "when no matching record exists" do
      it "creates a new record" do
        expect { increment! }.to change(StatisticsSummary, :count).by(1)
      end

      it "creates the record with count of 1" do
        increment!
        expect(record.count).to eq(1)
      end
    end

    context "when a matching record already exists" do
      before do
        StatisticsSummary.create!(
          identifier: "user_123",
          event:      "View",
          year:       2024,
          month:      3,
          count:      5
        )
      end

      it "does not create a new record" do
        expect { increment! }.not_to change(StatisticsSummary, :count)
      end

      it "increments the count by 1" do
        expect { increment! }
          .to change { record.reload.count }
          .from(5).to(6)
      end
    end

    context "when called multiple times" do
      xit "increments the count each time" do
        3.times { increment! }
        expect(StatisticsSummary.count).to eq(1)
        expect(StatisticsSummary.find_by(identifier: "user_123", event: "View", year: 2024, month: 3).count).to eq(3)
      end
    end

    context "when records exist for different attribute combinations" do
      before do
        StatisticsSummary.create!(identifier: "user_123", event: "View", year: 2024, month: 3, count: 10)
        StatisticsSummary.create!(identifier: "user_123", event: "View", year: 2024, month: 4, count: 10)
        StatisticsSummary.create!(identifier: "user_456", event: "View", year: 2024, month: 3, count: 10)
        StatisticsSummary.create!(identifier: "user_123", event: "Download",     year: 2024, month: 3, count: 10)
      end

      it "only increments the matching record" do
        increment!
        expect(record.reload.count).to eq(11)
      end

      it "does not affect records with a different month" do
        increment!
        expect(StatisticsSummary.find_by(identifier: "user_123", event: "View", year: 2024, month: 4).count).to eq(10)
      end

      it "does not affect records with a different event" do
        increment!
        expect(StatisticsSummary.find_by(identifier: "user_123", event: "Download", year: 2024, month: 3).count).to eq(10)
      end
    end
  end
end