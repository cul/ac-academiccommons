class Deposit < ApplicationRecord
  RIGHTS_OPTIONS = {
    'In Copyright' => 'http://rightsstatements.org/vocab/InC/1.0/',
    'No Copyright' => 'http://rightsstatements.org/vocab/NoC-US/1.0/'
  }.freeze

  # License can be empty or one of the following values.
  LICENSE_OPTIONS = [
    'https://creativecommons.org/licenses/by/4.0/',
    'https://creativecommons.org/licenses/by-sa/4.0/',
    'https://creativecommons.org/licenses/by-nd/4.0/',
    'https://creativecommons.org/licenses/by-nc/4.0/',
    'https://creativecommons.org/licenses/by-nc-sa/4.0/',
    'https://creativecommons.org/licenses/by-nc-nd/4.0/',
    'https://creativecommons.org/publicdomain/zero/1.0/'
  ].freeze

  ARTICLE_VERSION = {
    'Author\'s manuscript/preprint' => 'preprint',
    'Accepted manuscript/postprint' => 'postprint',
    'Final published version' => 'final'
  }.freeze

  THESIS_EMBARGO = {
    '1 year' => '1',
    '2 years' => '2',
    'No embargo' => '0'
  }.freeze

  before_validation :clean_up_creators
  before_save :finalize_notes_contents

  # validates_presence_of :agreement_version
  # validates_presence_of :name
  # validates_presence_of :email
  # validates_presence_of :file_path
  # validates_presence_of :title
  # validates_presence_of :authors
  # validates_presence_of :abstract

  validate :one_creator_must_be_present, on: :create
  validate :cco_must_be_selected, if: proc { |a| a.rights == RIGHTS_OPTIONS['No Copyright'] }
  validates :title, :abstract, :year, :rights, :files, presence: true, on: :create
  validates :previously_published, :current_student, inclusion: { in: [true, false] }, on: :create
  validates :rights,  inclusion: { in: RIGHTS_OPTIONS.values }, on: :create
  validates :license, inclusion: { in: LICENSE_OPTIONS },       on: :create, if: proc { |a| a.license.present? }
  validates :degree_program, :academic_advisor, :thesis_or_dissertation,
            presence: true, on: :create, if: proc { |a| a.current_student == true }
  has_many_attached :files

  belongs_to :user, optional: true

  store :metadata, accessors: %i[title creators abstract year doi license rights notes], coder: JSON

  # Returns METS representation of deposit, including descriptive, file and
  # structural metadata.
  def mets
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.mets(
        'xmlns': 'http://www.loc.gov/METS/',
        'xmlns:mods':         'http://www.loc.gov/mods/v3',
        'xmlns:xsi':          'http://www.w3.org/2001/XMLSchema-instance',
        'xmlns:xlink':        'http://www.w3.org/1999/xlink',
        'xsi:schemaLocation': 'http://www.loc.gov/METS/ http://www.loc.gov/standards/mets/mets.xsd http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-2.xsd'
      ) do
        xml.metsHdr('CREATEDATE': Time.current.utc.xmlschema) do
          xml.agent('ROLE': 'CUSTODIAN', 'TYPE': 'ORGANIZATION') do
            xml.name 'Academic Commons, Columbia University'
          end
        end
        xml.dmdSec('ID': 'sword-mets-dmd-1') do
          xml.mdWrap('MDTYPE': 'MODS') do
            xml.xmlData do
              xml['mods'].mods do
                xml['mods'].titleInfo do
                  xml['mods'].title(title)
                end
                xml['mods'].abstract(abstract)
                xml['mods'].originInfo do
                  xml['mods'].dateIssued(year, 'encoding': 'w3cdtf')
                end

                if doi.present?
                  xml['mods'].relatedItem('type': 'host') do
                    if (m = %r{^(http:\/\/dx\.doi\.org\/|https:\/\/doi\.org\/)?(?<doi>10\..+)$}.match(doi))
                      xml['mods'].identifier(m[:doi], 'type': 'doi')
                    else
                      xml['mods'].identifier(doi, 'type': 'uri')
                    end
                  end
                end

                creators.each do |c|
                  xml['mods'].name('type': 'personal') do
                    xml.parent.set_attribute('ID', c[:uni]) if c[:uni].present?
                    xml['mods'].namePart("#{c[:last_name]}, #{c[:first_name]}")
                    xml['mods'].role do
                      xml['mods'].roleTerm('Author', 'type': 'text', 'valueURI': 'http://id.loc.gov/vocabulary/relators/aut', 'authority': 'marcrelator')
                    end
                  end
                end

                if license.present?
                  xml['mods'].accessCondition(
                    'type': 'use and reproduction', 'displayLabel': 'License', 'xlink:href': license
                  )
                elsif rights.present?
                  xml['mods'].accessCondition(
                    'type': 'use and reproduction', 'displayLabel': 'Rights Status', 'xlink:href': rights
                  )
                end

                xml['mods'].note(notes, 'type': 'internal') if notes.present?
                xml['mods'].recordInfo do
                  xml['mods'].recordInfoNote('AC SWORD MODS v1.0')
                end
              end
            end
          end
        end
        xml.fileSec do
          xml.fileGrp('ID': 'sword-mets-fgrp-1', 'USE': 'CONTENT') do
            files.each_with_index do |file, i|
              xml.file('GROUPID': "sword-mets-fgid-#{i}", 'ID': "sword-mets-file-#{i + 1}", 'MIMETYPE': file.content_type) do
                xml.FLocat('LOCTYPE': 'URL', 'xlink:href': file.filename)
              end
            end
          end
        end
        xml.structMap('ID': 'sword-mets-struct-1', 'LABEL': 'structure', 'TYPE': 'LOGICAL') do
          xml.div('ID': 'sword-mets-div-1', 'DMDID': 'sword-mets-dmd-1', 'TYPE': 'SWORD Object') do
            xml.div('ID': 'sword-mets-div-2', 'TYPE': 'File')
            files.count.times do |i|
              xml.fptr('FILEID': "sword-mets-file-#{i + 1}")
            end
          end
        end
      end
    end
    builder.to_xml
  end

  def sword_zip
    stringio = Zip::OutputStream.write_buffer do |z|
      z.put_next_entry('mets.xml')
      z.write mets
      files.each do |file|
        z.put_next_entry(file.filename)
        z.write file.download
      end
    end
    stringio.string
  end

  private

  def cco_must_be_selected
    errors.add(:license, 'CCO must be selected') unless license == 'https://creativecommons.org/publicdomain/zero/1.0/'
  end

  def one_creator_must_be_present
    one_creator_present = creators.any? do |c|
      c[:first_name].present? && c[:last_name].present? && c[:uni].present?
    end
    errors.add(:creators, 'must have one creator with first name, last name and uni.') unless one_creator_present
  end

  # Remove any creators with empty first name, last name and uni.
  def clean_up_creators
    (creators || []).delete_if do |creator|
      %i[first_name last_name uni].all? { |k| creator[k].blank? }
    end
  end
end

def finalize_notes_contents
  return unless self.current_student

  self.notes = <<-TEXT
  #{self.notes}

  Degree Program: #{self.degree_program}
  Advisor Name: #{self.academic_advisor}
  Thesis or Dissertation: #{self.thesis_or_dissertation}
  Degree Earned: #{self.degree_earned}
  Embargo Date: #{self.embargo_date}
  Previously Published: #{self.previously_published}
  Article Version: #{self.article_version}
  Keywords: #{self.keywords}
  TEXT
end
