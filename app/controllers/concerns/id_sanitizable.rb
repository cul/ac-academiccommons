# frozen_string_literal: true

# Strips hidden/invisible unicode characters out of an :id param before it's
# used anywhere downstream (Solr queries, file/derivative lookups, logging,
# comparisons, etc).

module IdSanitizable
  extend ActiveSupport::Concern

  HIDDEN_CHARACTERS = [
    "\u200B", # ZWSP  - Zero Width Space
    "\u200C", # ZWNJ  - Zero Width Non-Joiner
    "\u200D", # ZWJ   - Zero Width Joiner
    "\u00A0", # NBSP  - Non-Breaking Space
    "\uFEFF", # BOM   - Byte Order Mark / Zero Width No-Break Space
    "\u2060", # Word Joiner
    "\u00AD", # SHY   - Soft Hyphen
    "\u2028", # Line Separator
    "\u2029"  # Paragraph Separator
  ].freeze

  HIDDEN_CHARACTER_PATTERN = Regexp.union(HIDDEN_CHARACTERS).freeze

  def self.sanitize_id(id)
    return id if id.blank?

    id.to_s.gsub(HIDDEN_CHARACTER_PATTERN, '')
  end

  def sanitize_id_param
    return if params[:id].blank?

    params[:id] = IdSanitizable.sanitize_id(params[:id])
  end
end
