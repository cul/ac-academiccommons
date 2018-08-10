FactoryBot.define do
  factory :deposit do
    title 'Test Depost'
    creators [
      { first_name: 'Jane', last_name: 'Doe', uni: 'abc123' },
      { first_name: 'John', last_name: 'Doe', uni: '' }
    ]
    abstract 'foobar'
    year '2018'
    doi  'https://www.example.com'
    notes 'This deposit is just for testing purposes.'
    rights_statement 'http://rightsstatements.org/vocab/InC/1.0/'

    after(:build) do |deposit|
      deposit.files.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'test_file.txt')),
        filename: 'test_file.txt'
      )
    end
  end
end
