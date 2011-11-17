class MenuBar
  TOGGLE_MENU_CLASS = 'toggle_menu'
  
  MENU_BAR_CLASS = 'menu_bar'
  MENU_BAR_CONTENT_CLASS = 'menu_bar_content'
  MENU_BAR_ITEM_CLASS = 'menu_bar_item'
  MENU_CLASS = 'menu'
  MENU_ITEM_CLASS = 'menu_item'
  
  CLICK_BLOCKER_CLASS = 'click_blocker'
  
  SELECTED_CLASS = 'selected'
  DISABLED_CLASS = 'disabled'
  GROUPED_CLASS = 'grouped'
  FIRST_GROUP_ITEM_CLASS = 'first_group_item'
  
  def initialize(template, options = {})
    @template = template
    @options = options

    @menu_bar_content = []
    
    if block_given?
      yield self
    end
  end
  
  def group
    @grouped = true
    @first_group_item = true
    yield self
    return self
  ensure
    @grouped = false
  end

  def menu_bar_content(content, options = {})
    initialize_options(options)

    mbc = MenuBarContent.new(@template, content, options)
    @menu_bar_content << mbc

    return mbc
  end
  
  def menu_bar_item(content, options = {})
    initialize_options(options)
    
    mbi = MenuBarItem.new @template, content, options
    @menu_bar_content << MenuBarContent.new(@template, mbi, options)
    
    return mbi
  end

  def menu_bar_input(content, options = {})
    initialize_options(options)
    
    mbin = MenuBarInput.new @template, content, options
    mbi = MenuBarItem.new @template, mbin, options
    @menu_bar_content << MenuBarContent.new(@template, mbi, options)
    
    return mbi
  end

  def menu(button_text, options = {})
    initialize_options(options)
    
    mbi = MenuBarItem.new(@template, button_text, options)
    m = Menu.new(@template, options)

    yield m if block_given?
    
    @menu_bar_content << MenuBarContent.new(@template, [mbi, m], options)
    
    return m
  end

  def to_s
    @template.content_tag :ul, @menu_bar_content.collect(&:to_s).join.html_safe, html_options
  end

  private
  
  def initialize_options(options)
    options.merge!(:grouped => @grouped, :first_group_item => @first_group_item) # If we're in a grouped context, pass that information to the menu bar item
    @first_group_item = false # Any group items are no longer first after we have read this value    
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
      # Treat the content as an array so we can pass multiple objects as content, e.g. when rending a menu
      wrap_content(Array(@content).collect(&:to_s).join.html_safe)
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
      wrapper_opts[:class] = [MENU_BAR_CONTENT_CLASS, wrapper_opts[:class]]
      
      # Either you are the first group item, or you a group item
      # This let's us determine the start of the group and prevents
      # it from mashing into the previous group
      if @options[:first_group_item]
        wrapper_opts[:class] << FIRST_GROUP_ITEM_CLASS 
      elsif @options[:grouped]
        wrapper_opts[:class] << GROUPED_CLASS
      end
      
      wrapper_opts[:class] = wrapper_opts[:class].compact.join(' ')

      return wrapper_opts      
    end
  end

  
  class MenuBarItem < MenuBarContent
    
    def disabled(state = true)
      @options[:disabled] = state
    end
    
    private
    
    def wrap_content(content)
      output = @template.content_tag :div, content, html_options
      output << @template.content_tag(:div, '', :class => CLICK_BLOCKER_CLASS) if @options[:disabled]
      return output
    end
    
    def html_options
      html_opts = @options[:html_options] || {}

      # Set up the css class
      html_opts[:class] = [MENU_BAR_ITEM_CLASS, html_opts[:class]]
      html_opts[:class] << SELECTED_CLASS if @options[:selected]
      html_opts[:class] << DISABLED_CLASS if @options[:disabled]
      html_opts[:class] = html_opts[:class].compact.join(' ')      
      
      return html_opts
    end
  end
  
  class MenuBarInput < MenuBarItem
    private
    
    def wrap_content(content)
      @template.label_tag nil, content
    end    
  end
  
  class Menu
    def initialize(template, options = {})
      @template = template
      @options = options
      @menu_items = []
    end
    
    def menu_item(content, options = {})
      mi = MenuItem.new(@template, content, options)
      @menu_items << mi
      
      return mi
    end
    
    def to_s
      @template.content_tag :ul, @menu_items.collect(&:to_s).join.html_safe, html_options unless @menu_items.empty?
    end
    
    private
    
    def html_options
      html_opts = @options[:html_options] || {}

      # Set up the css class
      html_opts[:class] = [MENU_CLASS, html_opts[:class]]
      html_opts[:class] = html_opts[:class].compact.join(' ')      
      
      return html_opts
    end
  end
  
  class MenuItem
    def initialize(template, content, options = {})
      @template = template
      @content = content
      @options = options      
    end
    
    def to_s
      @template.content_tag :li, @content, html_options
    end
    
    private
    
    def html_options
      html_opts = @options[:html_options] || {}

      # Set up the css class
      html_opts[:class] = [MENU_ITEM_CLASS, html_opts[:class]]
      html_opts[:class] = html_opts[:class].compact.join(' ')
      
      return html_opts
    end
  end  
end