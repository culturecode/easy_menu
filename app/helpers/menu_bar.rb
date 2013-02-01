# TODO make menu bar group an actual group instead of a state toggle
class MenuBar
  include EasyMenu::Helpers
  include EasyMenu::Configuration

  attr_reader :content

  def initialize(template, options = {})
    @template = template
    @options = options.reverse_merge(:theme => config[:default_theme_class])
    config.merge! options[:config] if options[:config] # Allow per menu overriding of configuration
    config[:template] = @template

    @content = []

    yield self if block_given?
  end

  def empty?
    @content.blank?
  end

  def group(options = {})
    initialize_options(options)
    
    mbg = MenuBarGroup.new(@template, @options.merge(options))
    mbc = MenuBarContent.new(config, mbg, options[:menu_bar_content])

    yield mbg if block_given?
    
    @content << mbc

    return mbg
  end

  def menu_bar_content(content = nil, options = {}, &block)
    initialize_options(options)

    if block_given?
      options = content || options 
      content = block.call
    end

    mbc = MenuBarContent.new(config, content, options)
    @content << mbc

    return mbc
  end

  def menu_bar_item(content, options = {})
    initialize_options(options)
    
    raise if config[:template].is_a?(Hash) || config[:template].nil?

    mbi = MenuBarItem.new config, content, options
    @content << MenuBarContent.new(config, mbi, options[:menu_bar_content])

    return mbi
  end

  def menu_bar_input(content, options = {})
    initialize_options(options)

    mbin = MenuBarInput.new config, content, options
    mbi = MenuBarItem.new config, mbin, options[:menu_bar_item]
    @content << MenuBarContent.new(config, mbi, options[:menu_bar_content])

    return mbi
  end

  def menu(button_text, options = {})
    initialize_options(options)
    arrow = @template.content_tag(:span, '', :class => config[:menu_bar_item_arrow_class])
    mbt = MenuBarTrigger.new(config, button_text + arrow, options[:menu_bar_item])
    m = Menu.new(config, options)

    yield m if block_given?

    # We give the menu bar content a special class so we can treat its contents differently than one without a menu inside
    @content << MenuBarContent.new(config, [mbt, m], merge_class(options[:menu_bar_content], config[:menu_bar_content_with_menu_class]))

    return m
  end

  def separator
    s = @template.content_tag :div, '', :class => config[:menu_bar_separator_class]
    @content << MenuBarContent.new(config, s)

    return s
  end  

  def to_s
    @template.content_tag :ul, @content.collect(&:to_s).join.html_safe, html_options
  end

  private

  def initialize_options(options)
    options[:menu_bar_item] ||= {}
    options[:menu_bar_content] ||= {}
    
    # Alignment always lies with the content wrapper
    options[:menu_bar_content][:align] = options.delete(:align)
    
    return options
  end

  def html_options
    html_opts = @options.slice(*html_option_keys) 

    # Set up the css class
    merge_class(html_opts, config[:menu_bar_class], @options[:theme])
    merge_class(html_opts, 'no_js') if @options[:js] == false

    return html_opts     
  end
    
  # ABSTRACT CLASSES
  
  class AbstractContent
    include EasyMenu::Helpers

    attr_reader :content, :config
    def initialize(config, content, options = {})
      raise if config[:template].is_a?(Hash) || config[:template].nil?
      @config = config
      @template = config[:template]
      @content = content
      @options = options
    end

    def empty?
      @content.blank?
    end    

    def to_s
      # Treat the content as an array so we can pass multiple objects as content, e.g. when rending a menu
      wrap_content(Array(@content).collect(&:to_s).join.html_safe)
    end

    private
    def config_name
      @config_name ||= self.class.name.underscore.gsub(/^.*\//, '')
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

    def html_options
      html_opts = @options.slice(*html_option_keys) 
      merge_class(html_opts, css_class, @options[:align])

      return html_opts     
    end    
  end

  class AbstractItem < AbstractContent
    def selected(condition = :unset)
      @options[:selected] = (condition == :unset ? true : condition)

      return self
    end

    def disabled(*args)
      @click_blocker_html_options = args.extract_options!
      @options[:disabled] = args.present? ? args.first : true

      return self
    end
    
    # Set the button up to disable when a particular DOM Event occurs
    def disable_when(observable_dom_element, dom_event, js_condition, click_blocker_html_options = {})
      @options[:disable_when] = {:element => observable_dom_element, :event => dom_event, :condition => js_condition}
      @click_blocker_html_options = click_blocker_html_options
      return self
    end
    
    private
    
    def wrap_content(content)
      output = super
      output << @template.content_tag(:div, '', click_blocker_html_options) if @options[:disabled] || @options[:disable_when]
      
      return output
    end
    
    def html_options
      html_opts = @options.slice(*html_option_keys) 

      if @options[:disable_when]
        html_opts[:'data-disable-event-element'] = @options[:disable_when][:element]
        html_opts[:'data-disable-event'] = @options[:disable_when][:event]
        html_opts[:'data-disable-condition'] = @options[:disable_when][:condition]
      end

      merge_class(html_opts, css_class)
      merge_class(html_opts, config[:selected_class]) if @options[:selected]
      merge_class(html_opts, config[:disabled_class]) if @options[:disabled]

      return html_opts     
    end
    
    def click_blocker_html_options
      html_opts = @click_blocker_html_options
      html_opts.reverse_merge! :title => @options[:title] # Default the title text to be the same as the unblocked title text

      merge_class(html_opts, config[:click_blocker_class])
      
      return html_opts
    end
  end  
  
  # CLASSES
  
  class MenuBarGroup < MenuBar
  end
  
  class MenuBarContent < AbstractContent
  end

  class MenuBarItem < AbstractItem
  end

  class MenuBarTrigger < MenuBarItem
  end

  class MenuBarInput < AbstractContent
  end

  class Menu < AbstractContent    
    def initialize(config, options = {})
      raise if config[:template].is_a?(Hash) || config[:template].nil?

      @config = config
      @template = config[:template]
      @options = options
      @content = []

      yield self if block_given?
    end

    def group(title, options = {})
      initialize_options(options)
      
      mgt = @template.content_tag(config[:menu_group_title_element], title, merge_class(options[:menu_group_title], config[:menu_group_title_class]))
      mg = MenuGroup.new(config, options)

      yield mg if block_given?
      
      @content << MenuContent.new(config, [mgt, mg], options[:menu_content])

      return mg
    end

    def menu_content(content = nil, options = {}, &block)
      initialize_options(options)

      if block_given?
        options = content || options  
        content = block.call
      end
      
      @content << MenuContent.new(config, content, options)
    end    

    def menu_item(content, options = {})
      initialize_options(options)
      
      mi = MenuItem.new(config, content, options)
      @content << MenuContent.new(config, mi, options[:menu_content])

      return mi
    end

    def separator
      s = @template.content_tag :div, '', :class => config[:menu_separator_class]
      @content << MenuContent.new(config, s)

      return s
    end    

    private
    
    def initialize_options(options)
      options[:menu_item] ||= {}
      options[:menu_content] ||= {}
      options[:menu_group_title] ||= {}

      return options
    end    
  end

  class MenuGroup < Menu
  end

  class MenuContent < AbstractContent
  end

  class MenuItem < AbstractItem
  end
end