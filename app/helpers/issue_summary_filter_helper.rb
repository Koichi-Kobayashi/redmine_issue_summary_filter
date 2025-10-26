# frozen_string_literal: true

module IssueSummaryFilterHelper
  def filter_options_for_select(field_name, options)
    options_for_select(options)
  end
  
  def filter_field_tag(field_name, options = {})
    select_tag "filter[#{field_name}]", options_for_select(options), options
  end
end
