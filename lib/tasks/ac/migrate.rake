namespace :ac do
  namespace :migrate do
    desc 'Migrate to roles'
    task to_roles: :environment do
      # If role column has '1' should be converted to admin, otherwise it will
      # be set to null.
      User.find_each do |user|
        user.update(role: 'admin') if user.admin == true || user.admin == '1' || user.admin == 1
      end
    end

    desc 'Migrate identifiers in stats to DOIs'
    task stats_to_doi: :environment do
      # Query for all fedora3 pids in our solr core.
      results = AcademicCommons.search do |p|
        p.field_list('id,cul_doi_ssi,fedora3_pid_ssi')
      end

      results.docs.each do |doc|
        pid = doc[:fedora3_pid_ssi]
        doi = doc[:cul_doi_ssi]
        next if doi.blank? || pid.blank?

        stats = Statistic.where(identifier: pid)
        next if stats.count.zero?

        # rubocop:disable Rails/SkipsModelValidations
        puts "UPDATING identifier = #{pid} TO identifier = #{doi}"
        stats.update_all(identifier: doi)
        # rubocop:enable Rails/SkipsModelValidations
      end
    end

    desc 'Migrate deposit metadata to metadata text field'
    task deposit_data: :environment do
      Deposit.find_each do |deposit|
        deposit.metadata[:title] = deposit[:title]
        deposit.metadata[:abstract] = deposit[:abstract]
        deposit.metadata[:doi] = deposit[:doi_pmcid]
        deposit.metadata[:notes] = deposit[:notes]
        deposit.authenticated = false
        deposit.save!
      end
    end
  end
end
