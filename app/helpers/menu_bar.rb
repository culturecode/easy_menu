class MenuBar
  TOGGLE_MENU_CLASS = 'toggle_menu'
  
  MENU_BAR_CLASS = 'menu_bar'
  MENU_BAR_CONTENT_CLASS = 'menu_bar_content'
  MENU_BAR_ITEM_CLASS = 'menu_bar_item'
  
  SELECTED_CLASS = 'selected'
  GROUPED_CLASS = 'grouped'
  
  def initialize(template, options = {})
    @template = template
    @options = options

    @menu_bar_items = []
    
    if block_given?
      yield self
    end
  end
  
  def group
    @grouped = true
    yield self
    return self
  ensure
    @grouped = false
  end

  def menu_bar_content(content, options = {})
    create_menu_bar_item(MenuBarContent, content, options = {})
  end
  
  def menu_bar_item(content, options = {})
    create_menu_bar_item(MenuBarItem, content, options = {})
  end

  def menu_bar_input(content, options = {})
    create_menu_bar_item(MenuBarInput, content, options = {})
  end

  def to_s
    @template.content_tag :ul, @menu_bar_items.collect(&:to_s).join.html_safe, html_options
  end

  private
  
  def create_menu_bar_item(klass, content, options = {})
    options.merge!(:grouped => @grouped) # If we're in a grouped context, pass that information to the menu bar item
    mbi = klass.new(@template, content, options)
    @menu_bar_items << mbi

    return mbi
  end
  
  def html_options
    html_opts = @options.dup

    # Set up the css class
    css_class = [MENU_BAR_CLASS, @options[:class]]
    css_class << TOGGLE_MENU_CLASS if html_opts.delete(:toggle)
    css_class.compact.join(' ')
    html_opts[:class] = css_class
    
    return html_opts
  end

  class MenuBarContent
    def initialize(template, content, options = {})
      @template = template
      @content = content
      @options = options
    end
    
    def to_s
      wrap_content(@content)
    end
    
    def selected(condition = :unset)
      @options[:selected] = (condition == :unset ? true : condition)
    end
    
    private
    
    def wrap_content(content)
      @template.content_tag :li, content, wrapper_options
    end
    
    def wrapper_options
      wrapper_opts = @options[:wrapper_options] || {}

      # Set up the css class
      wrapper_opts[:class] = [MENU_BAR_CONTENT_CLASS]
      wrapper_opts[:class] << GROUPED_CLASS if @options[:grouped]
      wrapper_opts[:class] = wrapper_opts[:class].compact.join(' ')

      return wrapper_opts      
    end
    
    def html_options
      html_opts = @options[:html_options] || {}

      # Set up the css class
      html_opts[:class] = [MENU_BAR_ITEM_CLASS]
      html_opts[:class] << SELECTED_CLASS if @options[:selected]
      html_opts[:class] = html_opts[:class].compact.join(' ')      
      
      return html_opts
    end    
  end

  
  class MenuBarItem < MenuBarContent
    private
    
    def wrap_content(content)
      super(@template.content_tag :div, content, html_options)
    end
  end
  
  class MenuBarInput < MenuBarItem
    private
    
    def wrap_content(content)
      super @template.label_tag(nil, content)
    end    
  end
end