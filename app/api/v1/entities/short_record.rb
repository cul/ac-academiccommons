module V1::Entities
  class ShortRecord < Grape::Entity
    format_with(:singular) { |v| v.first }

    with_options(format_with: :singular) do
      expose :id
      expose :legacy_id
      expose :title
    end

    expose :author

    with_options(format_with: :singular) do
      expose :abstract
      expose :date
    end

    expose :department
    expose :subject
    expose :type
    expose :language
    expose :persistent_url

    with_options(format_with: :singular) do
      expose :created_at
      expose :modified_at
    end
  end
end
