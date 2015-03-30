Deface::Override.new :virtual_path  => 'context_menus/issues',
                     :name          => 'add-link-create-new-point-in-context-menu',
                     :insert_before  => 'erb[silent]:contains("if User.current.logged?")',
                     :text          => <<eos
  <% if @project.present? #TODO Add a way to specify a project if we are in the /issues page %>
    <li><%= context_menu_link l(:button_create_point_de_situation), project_points_path(:project_id=>@project.id, :ids => @issue_ids),
                            :method => :post,
                            :class => 'icon-add',
                            :disabled => !User.current.allowed_to?(:add_issues, @projects) %></li>
  <% end %>
eos

Deface::Override.new :virtual_path  => 'context_menus/issues',
                     :name          => 'add-id-to-context-menu',
                     :surround      => 'ul',
                     :text          => '<div id="larger-context-menu"><%= render_original %></div>'
