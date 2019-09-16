# Converts new lines  to html <br> tags so they are preserved when displaying on html pages.
module Rendering
  class PreserveNewLines < Blacklight::Rendering::AbstractStep
    def render
      next_step(values.map { |x| preserve_new_lines(x) })
    end

    private

      def preserve_new_lines(value)
        return value unless value.is_a? String
        value.gsub(/\r\n?/, "\n").gsub(/(?:\n)/, '<br/>').html_safe
      end
  end
end
