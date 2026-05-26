module PromptNavigator
  module Helpers
    def history_list(card_path, active_uuid: nil, delete_path: nil)
      render "prompt_navigator/history", locals: {
        card_path: card_path,
        active_uuid: active_uuid,
        delete_path: delete_path
      }
    end
  end
end
