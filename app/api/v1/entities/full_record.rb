module V1::Entities
  class FullRecord < ShortRecord
    expose :columbia_series
    expose :thesis_advisor

    with_options(format_with: :singular) do
      expose :degree_name
      expose :degree_level
      expose :degree_grantor
      expose :degree_discipline

      expose :embargo_end

      expose :notes
    end

  end
end
