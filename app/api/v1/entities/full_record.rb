module V1::Entities
  class FullRecord < ShortRecord
    with_options(format_with: :singular) do
      expose :degree_name
      expose :degree_level
      expose :degree_grantor
      expose :embargo_end

      expose :notes
    end

    expose :thesis_advisor
  end
end
