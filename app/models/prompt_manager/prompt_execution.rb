module PromptManager
  class PromptExecution < ApplicationRecord
    belongs_to :previous, class_name: "PromptManager::PromptExecution", optional: true

    before_create :set_execution_id

    private

    def set_execution_id
      self.execution_id ||= SecureRandom.uuid
    end
  end
end
