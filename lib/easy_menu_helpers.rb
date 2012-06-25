module EasyMenu
	module Helpers
	 HTML_OPTIONS = [:id, :class, :title, :style, :data]

	  def merge_class(hash, *classes)
	    hash[:class] = ([hash[:class]] + classes.flatten).select(&:present?).join(' ')
	    return hash
	  end

	  def html_option_keys
	    HTML_OPTIONS + @options.keys.select{|key| key.to_s.starts_with? 'data-'}
	  end
	end
end