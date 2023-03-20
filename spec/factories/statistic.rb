FactoryBot.define do
  factory :statistic do
    identifier { '10.7916/ALICE' }
    at_time    { Time.current }

    factory :view_stat do
      event { Statistic::VIEW }
    end

    factory :streaming_stat do
      event { Statistic::STREAM }
    end

    factory :download_stat do
      identifier { '10.7916/TESTDOC2' }
      event { Statistic::DOWNLOAD }
    end
  end
end
