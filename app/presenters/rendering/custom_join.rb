# Copied Blacklight::Rendering::Join (v16.14.1) and added ability to return
# array if options contains `join: false`.

module Rendering
  class CustomJoin < Blacklight::Rendering::AbstractStep
    def render
      join = options.delete(:join) { true }

      if join
        options = config.separator_options || {}
        next_step(values.map { |x| html_escape(x) }.to_sentence(options).html_safe)
      else
        next_step(values.map { |x| html_escape(x) })
      end
    end

    private

    def html_escape(*args)
      ERB::Util.html_escape(*args)
    end
  end
end
