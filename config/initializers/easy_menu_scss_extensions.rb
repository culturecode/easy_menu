require 'base64'

# tools.ietf.org/html/rfc2397
# developer.mozilla.org/en/data_URIs

if defined?(Sass)
  puts "Loading Easy Menu SCSS extensions"
  module Sass::Script::Functions
    def data_url(content_type, content)
      outuri = "data:#{unquote(content_type)};base64,#{Base64.encode64(unquote(content).to_s)}"

      # IE8 has a 32KiB limit on data uri
      # en.wikipedia.org/wiki/Data_URI_scheme
      if outuri.length > 32768
        raise ArgumentError.new("Data URI is greater than 32KiB in size, that is the max size of data urls in IE8.")
      end
      
      Sass::Script::String.new("url('#{outuri}')")
    end
  end
end