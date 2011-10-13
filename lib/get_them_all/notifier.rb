module GetThemAll
  module Notifier
    def notify(name, *args)
      ActiveSupport::Notifications.publish(name, *args)
    end
  end
end
