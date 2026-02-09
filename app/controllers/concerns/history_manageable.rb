# frozen_string_literal: true

module PromptManager
  module HistoryManageable
    extend ActiveSupport::Concern

    def initialize_history(history)
      @history = history.to_a
    end

    def set_active_message_uuid(uuid)
      @active_message_uuid = uuid
    end

    def push_to_history(new_state)
      @history << new_state
    end
  end
end
