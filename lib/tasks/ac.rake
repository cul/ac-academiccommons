namespace :ac do
  desc "Adds item and collection to the repository."
  task :populate_solr => :environment do
    Rake::Task["load:fixtures"].invoke

    item = ActiveFedora::Base.find('actest:1')
    tries = 0

    while(item.list_members(true).length < 3 && tries < 50) do
      puts "(actest:1).list_members was less than 3, waiting for buffer to flush"
      sleep(1)
      tries += 1
    end
    raise "Never found item members, check Solr" if (tries > 50)

    index = AcademicCommons::Indexer.new
    index.items('actest:1', only_in_solr: false)
    index.close
  end

  desc "Returns list of author emails. Removes authors that have opted out and uses preferred email if one is present."
  task author_emails: :environment do
    if (output = ENV['output'])
      if File.exist?(output)
        puts Rainbow('File exists. Please re-run with new filepath.').red
      else
        # Retrieve all authors.
        ids = AcademicCommons.all_author_unis
        puts Rainbow("Found #{ids.count} unique author UNIs.").cyan

        # Filter out any emails and used preferred email if present.
        emails = EmailPreference.preferred_emails(ids)

        # Format Output into CSV.
        puts Rainbow("Writing out CSV to #{output}").cyan
        CSV.open(output, "wb") do |csv|
          csv << ['UNI', 'Email']
          emails.each do |uni, email|
            csv << [uni, email]
          end
        end
      end
    else
      puts Rainbow('Incorrect arguments. Pass output=/path/to/file').red
    end
  end
end
