# frozen_string_literal: true

# Strips hidden/invisible unicode characters and all whitespace out of an :id
# param (no id handled here -- DOIs, Fedora pids, numeric ids, log
# timestamps -- legitimately contains whitespace) before it's used anywhere downstream (Solr queries,
# file/derivative lookups, logging, statistics, comparisons, etc).

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

  # HIDDEN_CHARACTERS plus every Unicode default-ignorable code point
  # (zero-width characters, left-to-right/right-to-left marks, soft hyphens,
  # variation selectors, ...). NBSP and the line/paragraph separators are not
  # default-ignorable, so they stay listed explicitly above.
  HIDDEN_CHARACTER_PATTERN = Regexp.union(
    *HIDDEN_CHARACTERS,
    /\p{Default_Ignorable_Code_Point}/
  ).freeze

  # Unicode White_Space: ASCII whitespace plus NBSP, ideographic space, etc.
  WHITESPACE_PATTERN = /[[:space:]]/

  def self.sanitize_id(id)
    return id if id.blank?

    remove_whitespace(remove_hidden_characters(id.to_s))
  end

  def self.remove_hidden_characters(string)
    string.gsub(HIDDEN_CHARACTER_PATTERN, '')
  end

  def self.remove_whitespace(string)
    string.gsub(WHITESPACE_PATTERN, '')
  end

  def sanitize_id_param
    return if params[:id].blank?

    params[:id] = IdSanitizable.sanitize_id(params[:id])
  end
end
