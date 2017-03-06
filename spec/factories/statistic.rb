FactoryGirl.define do
  factory :statistic do
    identifier 'actest:1'
    at_time    Time.now

    factory :view_stat do
      event  Statistic::VIEW
    end

     factory :streaming_stat do
       event Statistic::STREAM
     end

    factory :download_stat do
      identifier 'actest:2'
      event Statistic::DOWNLOAD
    end
  end
end
