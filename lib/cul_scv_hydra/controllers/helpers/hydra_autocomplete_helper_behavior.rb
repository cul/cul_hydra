module Cul::Scv::Hydra::Controllers::Helpers
module HydraAutocompleteHelperBehavior
  def autocomplete_fedora_text_field(resource, datastream_name, field_key, opts={})
    field_name = field_name_for(field_key)
    field_values = get_values_from_datastream(resource, datastream_name, field_key, opts)
    field_values = [""] if field_values.empty?
    field_values = [field_values.first] unless opts.fetch(:multiple, true)
    required = opts.fetch(:required, true) ? "required" : ""
    body = ""
    field_values.each_with_index do |current_value, z|
      base_id = generate_base_id(field_name, current_value, field_values, opts)
      name = "asset[#{datastream_name}][#{field_name}][#{z}]"
      body << "<input class=\"editable-edit edit autocomplete\" id=\"#{base_id}\" data-datastream-name=\"#{datastream_name}\" name=\"#{name}\" value=\"#{h(current_value.strip)}\" #{required} type=\"text\" />"
      body << "<a href=\"\" title=\"Delete '#{h(current_value)}'\" class=\"destructive field\">Delete</a>" if opts.fetch(:multiple, true) && !current_value.empty?
    end
    result = field_selectors_for(datastream_name, field_key)
    result << body
    return body
  end
  def field_name_for(field_key)
    if field_key.kind_of?(Array)
      return OM::XML::Terminology.pointers_to_flat_array(field_key, true).join("__")
    else
      return field_key.to_s
    end
  end
  def generate_base_id(field_name, current_value, values, opts)
    if opts.fetch(:multiple, true)
      return field_name+"__"+values.index(current_value).to_s
    else
      return field_name
    end
  end
end
end
