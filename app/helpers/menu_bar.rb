# TODO make menu bar group an actual group instead of a state toggle
class MenuBar
  TOGGLE_MENU_CLASS = 'toggle_menu'

  MENU_BAR_CLASS = 'menu_bar'
  MENU_BAR_CONTENT_CLASS = 'menu_bar_content'
  MENU_BAR_GROUP_CLASS = 'menu_bar_group'
  MENU_BAR_CONTENT_WITH_MENU_CLASS = 'with_menu no_js' # no_js class will be removed by browser if it has js, disabling the hover behaviour and enabling a click behaviour
  MENU_BAR_ITEM_CLASS = 'menu_bar_item'
  MENU_BAR_ITEM_ARROW_CLASS = 'arrow'
  MENU_BAR_SEPARATOR_CLASS = 'menu_bar_separator'
  MENU_CLASS = 'menu'
  MENU_CONTENT_CLASS = 'menu_content'
  MENU_GROUP_CLASS = 'menu_group'
  MENU_GROUP_TITLE_CLASS = 'menu_group_title'
  MENU_ITEM_CLASS = 'menu_item'
  MENU_SEPARATOR_CLASS = 'menu_separator'

  CLICK_BLOCKER_CLASS = 'click_blocker'

  SELECTED_CLASS = 'selected'
  DISABLED_CLASS = 'disabled'
  GROUPED_CLASS = 'grouped'
  FIRST_GROUP_ITEM_CLASS = 'first_group_item'
  LAST_GROUP_ITEM_CLASS = 'last_group_item'

  def initialize(template, options = {})
    @template = template
    @options = options

    @menu_bar_content = []

    yield self if block_given?
  end

  def group(options = {})
    mbg = MenuBarGroup.new(@template, options)
    mbc = MenuBarContent.new(@template, mbg, options)

    yield mbg if block_given?
    
    @menu_bar_content << mbc

    return mbg
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

    mbi = MenuBarItem.new(@template, button_text + @template.content_tag(:span, '', :class => MENU_BAR_ITEM_ARROW_CLASS), options)
    m = Menu.new(@template, options)

    yield m if block_given?

    # Init content with menu options
    options = options.merge(:wrapper_options => options[:wrapper_options].merge(:class => MENU_BAR_CONTENT_WITH_MENU_CLASS))

    # We give the menu bar content a special class so we can treat its contents differently than one without a menu inside
    @menu_bar_content << MenuBarContent.new(@template, [mbi, m], options)

    return m
  end

  def separator
    s = @template.content_tag :div, '', :class => MENU_BAR_SEPARATOR_CLASS
    @menu_bar_content << MenuBarContent.new(@template, s)

    return s
  end  

  def to_s
    @template.content_tag :ul, @menu_bar_content.collect(&:to_s).join.html_safe, html_options
  end

  private

  def initialize_options(options)
    options[:html_options] ||= {}
    options[:wrapper_options] ||= {}
    return options
  end

  def html_options
    html_opts = @options

    # Set up the css class
    css_class = [MENU_BAR_CLASS, @options[:class]]
    css_class.compact.join(' ')
    html_opts[:class] = css_class

    return html_opts
  end
  
  # MODULES
  
  module Content
    def self.included(base)
      base.class_attribute :css_class
    end

    def initialize(template, content, options = {})
      @template = template
      @content = content
      @options = options
    end

    def to_s
      # Treat the content as an array so we can pass multiple objects as content, e.g. when rending a menu
      wrap_content(Array(@content).collect(&:to_s).join.html_safe)
    end

    private

    def wrap_content(content)
      @template.content_tag :li, content, html_options
    end

    def html_options
      html_opts = @options[:wrapper_options] ? @options[:wrapper_options].dup : {}

      # Set up the css class
      html_opts[:class] = [css_class, html_opts[:class]]      
      html_opts[:class] = html_opts[:class].compact.join(' ')

      return html_opts      
    end
  end

  module Item
    def selected(condition = :unset)
      @options[:selected] = (condition == :unset ? true : condition)
    end

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
      html_opts = @options[:html_options] ? @options[:html_options].dup : {}

      # Set up the css class
      html_opts[:class] = [css_class, html_opts[:class]]      
      html_opts[:class] << SELECTED_CLASS if @options[:selected]
      html_opts[:class] << DISABLED_CLASS if @options[:disabled]
      html_opts[:class] = html_opts[:class].compact.join(' ')

      return html_opts     
    end                    
  end    
  
  # CLASSES
  
  class MenuBarGroup < MenuBar
    
    private
    
    def html_options
      html_opts = @options

      # Set up the css class
      css_class = [MENU_BAR_GROUP_CLASS, @options[:class]]
      css_class.compact.join(' ')
      html_opts[:class] = css_class

      return html_opts
    end
  end
  
  class MenuBarContent    
    include MenuBar::Content
    self.css_class = MENU_BAR_CONTENT_CLASS
  end

  class MenuBarItem
    include MenuBar::Content
    include MenuBar::Item
    self.css_class = MENU_BAR_ITEM_CLASS
  end

  class MenuBarInput
    include MenuBar::Content
    self.css_class = 'menu_bar_input'
    
    def wrap_content(content)
      @template.label_tag nil, content
    end    
  end

  class Menu
    def initialize(template, options = {})
      @template = template
      @options = options.dup
      @menu_content = []

      yield self if block_given?
    end

    def group(title, options = {})
      mgt = @template.content_tag(:div, title, :class => MENU_GROUP_TITLE_CLASS)
      mg = MenuGroup.new(@template, options)

      yield mg if block_given?
      
      @menu_content << MenuContent.new(@template, [mgt, mg], options)

      return mg
    end

    def menu_content(content, options = {})
      @menu_content << MenuContent.new(@template, content, options)
    end    

    def menu_item(content, options = {})
      mi = MenuItem.new(@template, content, options)
      @menu_content << MenuContent.new(@template, mi, options)

      return mi
    end

    def separator
      s = @template.content_tag :div, '', :class => MENU_SEPARATOR_CLASS
      @menu_content << MenuContent.new(@template, s)

      return s
    end    

    def to_s
      @template.content_tag :ul, @menu_content.collect(&:to_s).join.html_safe, html_options unless @menu_content.empty?
    end

    private

    def html_options
      html_opts = @options[:html_options] ? @options[:html_options].dup : {}

      # Set up the css class
      html_opts[:class] = [MENU_CLASS, html_opts[:class]]
      html_opts[:class] = html_opts[:class].compact.join(' ')      

      return html_opts
    end
  end

  class MenuGroup < Menu
    private

    def html_options
      html_opts = @options[:html_options] ? @options[:html_options].dup : {}

      # Set up the css class
      html_opts[:class] = [MENU_GROUP_CLASS, html_opts[:class]]
      html_opts[:class] = html_opts[:class].compact.join(' ')      

      return html_opts
    end
  end

  class MenuContent
    include MenuBar::Content
    self.css_class = MENU_CONTENT_CLASS
  end

  class MenuItem
    include MenuBar::Content
    include MenuBar::Item
    self.css_class = MENU_ITEM_CLASS
  end
end