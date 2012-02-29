# TODO make menu bar group an actual group instead of a state toggle
class MenuBar
  DEFAULT_THEME_CLASS = 'default_theme'
  MENU_BAR_CLASS = 'menu_bar'
  MENU_BAR_CONTENT_CLASS = 'menu_bar_content'
  MENU_BAR_GROUP_CLASS = 'menu_bar_group'
  MENU_BAR_CONTENT_WITH_MENU_CLASS = 'with_menu no_js' # no_js class will be removed by browser if it has js, disabling the hover behaviour and enabling a click behaviour
  MENU_BAR_ITEM_CLASS = 'menu_bar_item'
  MENU_BAR_ITEM_ARROW_CLASS = 'arrow'
  MENU_BAR_INPUT_CLASS = 'menu_bar_input'
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
  
  HTML_OPTIONS = [:id, :class, :title, :style]

  class_attribute :css_class
  self.css_class = MENU_BAR_CLASS

  def initialize(template, options = {})
    @template = template
    @options = options.reverse_merge(:theme => DEFAULT_THEME_CLASS)

    @content = []

    yield self if block_given?
  end

  def group(options = {})
    initialize_options(options)
    
    mbg = MenuBarGroup.new(@template, options)
    mbc = MenuBarContent.new(@template, mbg, options[:menu_bar_content])

    yield mbg if block_given?
    
    @content << mbc

    return mbg
  end

  def menu_bar_content(content, options = {})
    initialize_options(options)

    mbc = MenuBarContent.new(@template, content, options)
    @content << mbc

    return mbc
  end

  def menu_bar_item(content, options = {})
    initialize_options(options)

    mbi = MenuBarItem.new @template, content, options
    @content << MenuBarContent.new(@template, mbi, options[:menu_bar_content])

    return mbi
  end

  def menu_bar_input(content, options = {})
    initialize_options(options)

    mbin = MenuBarInput.new @template, content, options
    mbi = MenuBarItem.new @template, mbin, options[:menu_bar_item]
    @content << MenuBarContent.new(@template, mbi, options[:menu_bar_content])

    return mbi
  end

  def menu(button_text, options = {})
    initialize_options(options)

    mbi = MenuBarItem.new(@template, button_text + @template.content_tag(:span, '', :class => MENU_BAR_ITEM_ARROW_CLASS), options[:menu_bar_item])
    m = Menu.new(@template, options)

    yield m if block_given?

    # We give the menu bar content a special class so we can treat its contents differently than one without a menu inside
    @content << MenuBarContent.new(@template, [mbi, m], options[:menu_bar_content].merge(:class => MENU_BAR_CONTENT_WITH_MENU_CLASS))

    return m
  end

  def separator
    s = @template.content_tag :div, '', :class => MENU_BAR_SEPARATOR_CLASS
    @content << MenuBarContent.new(@template, s)

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
    html_opts = @options.slice(*HTML_OPTIONS)

    # Set up the css class
    html_opts[:class] = [css_class, html_opts[:class]]
    html_opts[:class] << @options[:theme] if @options[:theme].present?
    html_opts[:class] << 'no_js' if @options[:js] == false
    html_opts[:class] = html_opts[:class].compact.join(' ')

    return html_opts     
  end
  
  # ABSTRACT CLASSES
  
  class AbstractContent
    class_attribute :css_class
    attr_reader :content
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
      html_opts = @options.slice(*HTML_OPTIONS)

      # Set up the css class
      html_opts[:class] = [css_class, html_opts[:class], @options[:align]]
      html_opts[:class] = html_opts[:class].compact.join(' ')      
      return html_opts
    end
  end

  class AbstractItem < AbstractContent
    def selected(condition = :unset)
      @options[:selected] = (condition == :unset ? true : condition)

      return self
    end

    def disabled(state = true)
      @options[:disabled] = state

      return self
    end
    
    # Set the button up to disable when a particular DOM Event occurs
    def disable_when(observable_dom_element, dom_event, js_condition, html_opts = {})
      @options[:disable_when] = {:element => observable_dom_element, :event => dom_event, :condition => js_condition, :html_options => html_opts}

      return self
    end
    
    private
    
    def wrap_content(content)
      output = @template.content_tag :div, content, html_options
      output << @template.content_tag(:div, '', click_blocker_html_options) if @options[:disabled] || @options[:disable_when]
      
      return output
    end
    
    def html_options
      html_opts = @options.slice(*HTML_OPTIONS)

      # Set up the css class
      html_opts[:class] = [css_class, html_opts[:class]]      
      html_opts[:class] << SELECTED_CLASS if @options[:selected]
      html_opts[:class] << DISABLED_CLASS if @options[:disabled]

      if @options[:disable_when]
        html_opts[:'data-disable-event-element'] = @options[:disable_when][:element]
        html_opts[:'data-disable-event'] = @options[:disable_when][:event]
        html_opts[:'data-disable-condition'] = @options[:disable_when][:condition]
      end
      
      html_opts[:class] = html_opts[:class].compact.join(' ')

      return html_opts     
    end
    
    def click_blocker_html_options
      html_opts = @options[:disable_when] ? @options[:disable_when][:html_options] : {}
      html_opts.reverse_merge! :title => @options[:title]

      html_opts[:class] = [CLICK_BLOCKER_CLASS, html_opts[:class]].compact.join(' ')
      
      return html_opts
    end
  end  
  
  # CLASSES
  
  class MenuBarGroup < MenuBar
    self.css_class = MENU_BAR_GROUP_CLASS
  end
  
  class MenuBarContent < AbstractContent
    self.css_class = MENU_BAR_CONTENT_CLASS
  end

  class MenuBarItem < AbstractItem
    self.css_class = MENU_BAR_ITEM_CLASS
  end

  class MenuBarInput < AbstractContent
    self.css_class = MENU_BAR_INPUT_CLASS
    
    private
    
    def wrap_content(content)
      @template.label_tag nil, content, html_options
    end    
  end

  class Menu < AbstractContent
    self.css_class = MENU_CLASS
    
    def initialize(template, options = {})
      @template = template
      @options = options
      @content = []

      yield self if block_given?
    end

    def group(title, options = {})
      initialize_options(options)
      
      mgt = @template.content_tag(:div, title, :class => MENU_GROUP_TITLE_CLASS)
      mg = MenuGroup.new(@template, options)

      yield mg if block_given?
      
      @content << MenuContent.new(@template, [mgt, mg], options[:menu_content])

      return mg
    end

    def menu_content(content, options = {})
      initialize_options(options)
      
      @content << MenuContent.new(@template, content, options)
    end    

    def menu_item(content, options = {})
      initialize_options(options)
      
      mi = MenuItem.new(@template, content, options)
      @content << MenuContent.new(@template, mi, options[:menu_content])

      return mi
    end

    def separator
      s = @template.content_tag :div, '', :class => MENU_SEPARATOR_CLASS
      @content << MenuContent.new(@template, s)

      return s
    end    

    private

    def wrap_content(content)
      @template.content_tag :ul, content, html_options
    end
    
    def initialize_options(options)
      options[:menu_item] ||= {}
      options[:menu_content] ||= {}
      return options
    end    
  end

  class MenuGroup < Menu
    self.css_class = MENU_GROUP_CLASS
  end

  class MenuContent < AbstractContent
    self.css_class = MENU_CONTENT_CLASS
  end

  class MenuItem < AbstractItem
    self.css_class = MENU_ITEM_CLASS
  end
end