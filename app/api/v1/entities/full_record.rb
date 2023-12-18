module V1
  module Entities
    class FullRecord < ShortRecord
      expose(:columbia_series)  { |r| r.columbia_series }
      expose(:thesis_advisor) { |r| r.thesis_advisor }

      expose(:degree_name)       { |r| r.degree_name.first }
      expose(:degree_level)      { |r| r.degree_level.first }
      expose(:degree_grantor)    { |r| r.degree_grantor.first }
      expose(:degree_discipline) { |r| r.degree_discipline.first }

      expose(:embargo_end) { |r| r.embargo_end }
      expose(:notes)       { |r| r.notes.first }
    end
  end
end
