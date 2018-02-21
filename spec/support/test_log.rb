# Moves test log to /log/ac-indexing/20170101-000000.log for testing. Removes it once
# test is completed.
shared_context 'log' do
  let(:id) { '20170101-000000' }
  let(:filepath) { fixture('test_file.txt') }
  let(:log_destination) { File.join(Rails.root, 'log', 'ac-indexing', "#{id}.log") }

  before do
    FileUtils.cp(filepath, log_destination) # Create fake log.
  end

  after do
    FileUtils.rm(log_destination) # Delete fake log.
  end
end
