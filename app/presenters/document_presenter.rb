class DocumentPresenter < Blacklight::DocumentPresenter
  # Overriding method in Blacklight::DocumentPresentor v15.9.2
  # Displays each value in a multi-valued field on a new line.
  def field_value_separator
    '<br/>'.html_safe
  end
end
