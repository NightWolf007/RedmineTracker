class Content < Qt::Widget
  signals 'action_changed(QString)', :socket_error
  slots 'show_action(QString)', :start_action, :stop_action,
        :to_show, :to_edit, :to_new, :delete_action, :save_action,
        :refresh_show_timestamps, :handle_socket_error

  def initialize(parent = nil, width = 0, height = 0)
    super(parent)
    setMinimumWidth(width) if width.present?
    setMinimumHeight(height) if height.present?
    init_current_action
    init_ui
    @current_action.present? ? to_show : hide_all
  end

  def init_current_action
    @current_action = Action.all.first
    @current_action_id = @current_action.try(:id)
  end

  def init_ui
    layout = Qt::VBoxLayout.new(self)
    layout.setContentsMargins(0, 0, 0, 0)

    init_widgets_ui

    layout.addWidget @header
    layout.addWidget @action_show
    layout.addWidget @action_edit
    layout.addWidget @action_show_footer
    layout.addWidget @action_edit_footer

    connect_widgets
  end

  def init_widgets_ui
    @header = ContentHeader.new(self, width, 50)
    @action_show = ActionsShow.new(self, width, height - 100)
    @action_show_footer = ActionsShowFooter.new(self, width, 50)
    @action_edit = ActionsEdit.new(self, width, height - 100)
    @action_edit_footer = ActionsEditFooter.new(self, width, 50)
  end

  def connect_widgets
    connect(@action_show.timer, SIGNAL(:timeout),
            self, SLOT(:refresh_show_timestamps))
    connect(@action_show, SIGNAL(:socket_error),
            self, SLOT(:handle_socket_error))
    connect(@action_edit, SIGNAL(:socket_error),
            self, SLOT(:handle_socket_error))
    connect_show_footer
    connect_edit_footer
  end

  def connect_show_footer
    connect(@action_show_footer.start_button, SIGNAL(:clicked),
            self, SLOT(:start_action))
    connect(@action_show_footer.stop_button, SIGNAL(:clicked),
            self, SLOT(:stop_action))
    connect(@action_show_footer.edit_button, SIGNAL(:clicked),
            self, SLOT(:to_edit))
  end

  def connect_edit_footer
    connect(@action_edit_footer.cancel_button, SIGNAL(:clicked),
            self, SLOT(:to_show))
    connect(@action_edit_footer.delete_button, SIGNAL(:clicked),
            self, SLOT(:delete_action))
    connect(@action_edit_footer.save_button, SIGNAL(:clicked),
            self, SLOT(:save_action))
  end

  def hide_all
    @header.title = ''
    @action_show.hide
    @action_show_footer.hide
    @action_edit.hide
    @action_edit_footer.hide
  end

  def to_show
    @current_action = Action.find(@current_action_id)
    refresh_views
    @action_show.show
    @action_show_footer.show
    @action_edit.hide
    @action_edit_footer.hide
  end

  def to_edit
    refresh_views
    @action_edit.show
    @action_edit_footer.show
    @action_edit_footer.delete_button.show
    @action_show.hide
    @action_show_footer.hide
  end

  def to_new
    @current_action = Action.new
    to_edit
    @action_edit_footer.delete_button.hide
  end

  def delete_action
    @current_action.destroy
    init_current_action
    action_changed(@current_action_id)
    to_show
  end

  def save_action
    @current_action.name = @action_edit.name
    @current_action.project_id = @action_edit.project_id
    @current_action.issue_id = @action_edit.issue_id
    @current_action.activity_id = @action_edit.activity_id
    @current_action.save
    @current_action_id = @current_action.id
    action_changed(@current_action_id)
    to_show
  end

  def refresh
    @current_action = Action.all.first
    @header.title = @current_action.name
    @action_show.show_action @current_action
    @action_edit.show_action @current_action
  end

  def to_online
    refresh
    @action_edit.to_online
  end

  def to_offline
    @action_show.to_offline
    @action_edit.to_offline
  end

  protected

  def refresh_views
    @header.title = @current_action.name
    @action_show.show_action @current_action
    @action_show_footer.show_action @current_action
    @action_edit.show_action @current_action
  end

  def refresh_show_timestamps
    @action_show.refresh_timestamps(@current_action)
  end

  def show_action(action_id)
    @current_action_id = action_id
    to_show
  end

  def start_action
    @current_action.start
    @current_action.save
    refresh_views
  end

  def stop_action
    @action_show.timer.stop
    @current_action.stop
    @current_action.save
    save_to_remote if @current_action.time_from_start != 0.0
    refresh_views
  end

  def save_to_remote
    t = Transaction.save_action @current_action
    t.handle
  rescue SocketError
    t.save
    socket_error
  end

  def handle_socket_error
    socket_error
  end
end
