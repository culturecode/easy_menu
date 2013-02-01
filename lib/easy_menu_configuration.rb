module EasyMenu
  module Configuration
    def self.included(base)
      base.class_eval do
        class_attribute :config
        self.config = Hash.new{|hash, key| raise "#{key} has not been set in Easy Menu Configuration"}.merge(Default)
      end      
    end

    Default = {
      # CLASSES

      :default_theme_class              => 'default_theme',
      :menu_bar_class                   => 'menu_bar',
      :menu_bar_content_class           => 'menu_bar_content',
      :menu_bar_group_class             => 'menu_bar_group',
      :menu_bar_content_with_menu_class => 'with_menu no_js', # no_js class will be removed by browser if it has js, disabling the hover behaviour and enabling a click behaviour
      :menu_bar_item_class              => 'menu_bar_item',
      :menu_bar_item_arrow_class        => 'arrow',
      :menu_bar_input_class             => 'menu_bar_input',
      :menu_bar_separator_class         => 'menu_bar_separator',
      :menu_bar_trigger_class           => :menu_bar_item, # This element is a menu item but behaves differently
      :menu_class                       => 'menu',
      :menu_content_class               => 'menu_content',
      :menu_group_class                 => 'menu_group',
      :menu_group_title_class           => 'menu_group_title',
      :menu_item_class                  => 'menu_item',
      :menu_separator_class             => 'menu_separator',
      :click_blocker_class              => 'click_blocker',
      :selected_class                   => 'selected',
      :disabled_class                   => 'disabled',
      :grouped_class                    => 'grouped',
      :first_group_item_class           => 'first_group_item',
      :last_group_item_class            => 'last_group_item',
      
      # ELEMENTS
      :menu_bar_content_element         => :li,
      :menu_bar_item_element            => :div,
      :menu_bar_trigger_element         => :div,
      :menu_bar_input_element           => :label,

      :menu_element                     => :ul,
      :menu_content_element             => :li,
      :menu_group_title_element         => :div,
      :menu_group_element               => :ul,
      :menu_item_element                => :div      
    }

    Bootstrap =  {
      :menu_bar_content_with_menu_class => 'dropdown',
      :menu_bar_item_arrow_class => 'caret',
      :menu_class => 'dropdown-menu',
      :menu_item_element => nil,
      :menu_bar_trigger_element => :a,
      :menu_bar_trigger_class => 'dropdown-toggle'
    }
  end
end