namespace :ac do
  namespace :bots do
    desc "Generates bots json at config/crawler-user-agents.json"
    task :generate_list => :environment do
      bots = []
      # Read in bots file from github.com/monperrus/crawler-user-agents add
      # github.com/atmire/COUNTER-Robots.
      [
        'https://raw.githubusercontent.com/monperrus/crawler-user-agents/master/crawler-user-agents.json',
        'https://raw.githubusercontent.com/atmire/COUNTER-Robots/master/COUNTER_Robots_list.json'
      ].each do |url|
        contents = Net::HTTP.get(URI(url))
        new_bots = JSON.parse(contents)

        puts Rainbow("#{new_bots.count} bots listed at #{url}").cyan

        new_bots.each do |new_bot|
          new_bot['pattern'] = new_bot['pattern'].downcase.strip
          new_bot['source'] = url
          duplicate = bots.find { |h| h['pattern'] == new_bot['pattern'] }
          bots.append(new_bot) if duplicate.nil?
        end
      end

      # Read bots from custom json source.
      custom_file = File.join('config', 'custom_bots.json')
      custom_bots = JSON.parse(File.read(File.join(Rails.root, custom_file)))

      puts Rainbow("#{custom_bots.count} bots listed at #{custom_file}").cyan

      custom_bots.each do |new_bot|
        new_bot['pattern'] = new_bot['pattern'].downcase.strip
        new_bot['source'] = custom_file
        duplicate = bots.find { |h| h['pattern'] == new_bot['pattern'] }
        if duplicate.nil?
          bots.append(new_bot)
        else
          puts Rainbow("duplicate found for #{new_bot['pattern']}").yellow
        end
      end

      bots.sort! { |a, b| a['pattern'] <=> b['pattern'] }

      puts Rainbow("\nListing #{bots.count} Bots\n").cyan

      puts bots.map { |h| h['pattern'] }.join("\n")

      write_to = File.join(Rails.root, 'config', 'crawler-user-agents.json')
      File.write(write_to, JSON.pretty_generate(bots))
    end

    desc 'Checks that we are filtering out bots listed in goaccess json file'
    task :check_filtering => :environment do
      if ENV['FILENAME'].nil?
        puts Rainbow('Usage: rake ac:bots:check_filtering FILENAME=path/to.file').red
        next
      end

      filename = File.expand_path(ENV['FILENAME'])
      raise "Could not find file #{filename}" unless File.exist?(filename)

      hosts = JSON.parse(File.read(filename))['hosts']['data']
      not_listed = hosts.map { |h| h['items'] }
                        .flatten
                        .uniq
                        .select { |ua| !VoightKampff.bot?(ua) }

      puts Rainbow(not_listed.uniq.join("\n")).red
    end
  end
end
