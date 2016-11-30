FactoryGirl.define do
  factory :statistic do
    identifier 'actest:1'
    at_time    Time.now

    factory :view_stat do
      event      'View'
    end

     factory :streaming_stat do
       event 'Streaming'
     end

    factory :download_stat do
      identifier 'actest:2'
      event 'Download'
    end
  end
end
