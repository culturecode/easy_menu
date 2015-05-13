# TODO make menu bar group an actual group instead of a state toggle
require 'easy_menu_helpers'
require 'easy_menu_configuration'

class MenuBar
  include EasyMenu::Helpers
  include EasyMenu::Configuration

  attr_reader :content, :groups

  def initialize(template, options = {})
    @template = template
    @options = options.reverse_merge(:theme => config[:default_theme_class], :remove_dangling_separators => true)
    config.merge! options[:config] if options[:config] # Allow per menu overriding of configuration
    config[:template] = @template

    @content = []
    @groups = [] # Subset of content that allows user to perform simpler non-sequential insertion into a particular group

    yield self if block_given?
  end

  def empty?
    @content.blank?
  end

  def group(options = {})
    initialize_options(options)

    mbg = MenuBarGroup.new(@template, options.merge(@options.slice(:config)))
    mbc = MenuBarContent.new(config, mbg, options[:menu_bar_content])

    yield mbg if block_given?

    store_menu_bar_content(mbc, options)
    @groups << mbg

    return mbg
  end

  def menu_bar_content(content = nil, options = {}, &block)
    initialize_options(options)

    if block_given?
      options = content || options
      content = block.call
    end

    mbc = MenuBarContent.new(config, content, options)

    store_menu_bar_content(mbc, options)

    return mbc
  end

  def menu_bar_item(content, options = {})
    initialize_options(options)

    raise if config[:template].is_a?(Hash) || config[:template].nil?

    mbi = MenuBarItem.new config, content, options
    mbc = MenuBarContent.new(config, mbi, options[:menu_bar_content])

    store_menu_bar_content(mbc, options)

    return mbi
  end

  def menu_bar_input(content, options = {})
    initialize_options(options)

    mbin = MenuBarInput.new config, content, options
    mbi = MenuBarItem.new config, mbin, options[:menu_bar_item]
    mbc = MenuBarContent.new(config, mbi, options[:menu_bar_content])

    store_menu_bar_content(mbc, options)

    return mbi
  end

  def menu(button_text, options = {})
    initialize_options(options)

    arrow = @template.content_tag(:span, '', :class => config[:menu_bar_item_arrow_class])

    m = Menu.new(config, options)
    mbt = MenuBarTrigger.new(config, button_text.html_safe + arrow, m, options[:menu_bar_item])

    yield m if block_given?

    # We give the menu bar content a special class so we can treat its contents differently than one without a menu inside
    mbc = MenuBarContent.new(config, mbt, merge_class(options[:menu_bar_content], config[:menu_bar_content_with_menu_class]))

    store_menu_bar_content(mbc, options)

    return m
  end

  def separator(options = {})
    s = @template.content_tag :div, '', :class => config[:menu_bar_separator_class]
    mbc = MenuBarContent.new(config, s, options.reverse_merge(:remove_if_dangling => @options[:remove_dangling_separators]))

    store_menu_bar_content(mbc, options)

    return s
  end

  def to_s
    @content.pop if @content.last && @content.last.options[:remove_if_dangling]
    wrap_content(@content.join.html_safe)
  end

  def to_str
    to_s
  end

  def html_safe?
    true
  end

  private

  def initialize_options(options)
    options[:menu_bar_item] ||= {}
    options[:menu_bar_content] ||= {}

    # Alignment always lies with the content wrapper
    options[:menu_bar_content][:align] ||= options.delete(:align)

    return options
  end

  def html_options
    html_opts = @options.slice(*html_option_keys)

    # Set up the css class
    merge_class(html_opts, css_class, @options[:theme])
    merge_class(html_opts, 'no_js') if @options[:js] == false

    return html_opts
  end

  def store_menu_bar_content(mbc, options = {})
    if options[:index]
      @content.insert(options[:index], mbc)
    # Ensure that right aligned menu bar content appears on the page in the order it is inserted
    elsif mbc.right_aligned?
      @content.prepend(mbc)
    else
      @content << mbc
    end
  end

  # ABSTRACT CLASSES

  class AbstractContent
    include EasyMenu::Helpers

    attr_reader :content, :config, :options
    def initialize(config, content, options = {})
      raise if config[:template].is_a?(Hash) || config[:template].nil?
      @config = config
      @template = config[:template]
      @content = Array(content)
      @options = options
    end

    def empty?
      @content.all?(&:blank?)
    end

    def to_s
      empty? ? '' : wrap_content(@content.join.html_safe) # Don't render anything if empty
    end

    def right_aligned?
      options[:align].to_s == 'right'
    end

    private

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
      html_opts = @click_blocker_html_options.dup
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
    def initialize(config, content, menu, options)
      @menu = menu
      super(config, content, options)
    end

    # If the menu has no content, don't show the menu bar trigger
    def empty?
      @menu.empty?
    end

    def to_s
      super + @menu.to_s
    end
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

      mc = MenuContent.new(config, [mgt, mg], options[:menu_content])

      store_menu_content(mc, options)

      return mg
    end

    def menu_content(content = nil, options = {}, &block)
      initialize_options(options)

      if block_given?
        options = content || options
        content = block.call
      end

      mc = MenuContent.new(config, content, options)

      store_menu_content(mc, options)
    end

    def menu_item(content, options = {})
      initialize_options(options)

      mi = MenuItem.new(config, content, options)
      mc = MenuContent.new(config, mi, options[:menu_content])

      store_menu_content(mc, options)

      return mi
    end

    def separator(options = {})
      s = @template.content_tag :div, '', :class => config[:menu_separator_class]
      mc = MenuContent.new(config, s)

      store_menu_content(mc, options)

      return s
    end

    private

    def initialize_options(options)
      options[:menu_item] ||= {}
      options[:menu_content] ||= {}
      options[:menu_group_title] ||= {}

      return options
    end

    def store_menu_content(mc, options = {})
      if options[:index]
        @content.insert(options[:index], mc)
      else
        @content << mc
      end
    end
  end

  class MenuGroup < Menu
  end

  class MenuContent < AbstractContent
  end

  class MenuItem < AbstractItem
  end
end
