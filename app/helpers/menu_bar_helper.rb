module MenuBarHelper
  def menu_bar(*args, &block)
    MenuBar.new(self, *args, &block)
  end
end