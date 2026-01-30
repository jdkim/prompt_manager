module PromptManager
  module Helpers
    def history_list(card_path, active_id: nil)
      render "prompt_manager/history", locals: { card_path: card_path, active_id: active_id }
    end
  end
end
