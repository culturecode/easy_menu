module EasyMenu
	module Helpers
  	HTML_OPTIONS = [:id, :class, :title, :style, :data]

    # Determines the config name from the class name.
    # e.g. MenuBar => 'menu_bar'
    def config_name
      self.class.name.demodulize.underscore
    end

    def css_class
      config[:"#{config_name}_class"]
    end

    def wrapper_element
      config[:"#{config_name}_element"]
    end

    def wrap_content(content)
      if (wrapper_element)
        @template.content_tag wrapper_element, content, html_options
      else
        content
      end
    end

	  def merge_class(hash, *classes)
	    hash[:class] = ([hash[:class]] + classes.flatten).select(&:present?).join(' ')
	    return hash
	  end

	  def html_option_keys
	    HTML_OPTIONS + @options.keys.select{|key| key.to_s.starts_with? 'data-'}
	  end
	end
end