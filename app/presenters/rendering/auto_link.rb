module Rendering
  class AutoLink < Blacklight::Rendering::AbstractStep
    def render
      return next_step(values) unless config.auto_link
      next_step(auto_link(values))
    end

    private

    def auto_link(values)
      values.map { |x| Rinku.auto_link(x, :all, 'target="_blank"').html_safe }
    end
  end
end
