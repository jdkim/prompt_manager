module PromptNavigator
  class PromptExecution < ApplicationRecord
    belongs_to :previous, class_name: "PromptNavigator::PromptExecution", optional: true

    before_create :set_execution_id

    # Builds a context array from the direct lineage for summarization.
    # Each entry contains { prompt:, response: } from ancestor PromptExecutions.
    # Optionally limit to the most recent N ancestors.
    def build_context(limit: nil)
      ancestors(limit: limit).map do
        { prompt: it.prompt, response: it.response }
      end
    end

    # Bulk-delete a set of PromptExecutions, tolerating the self-referential
    # `previous_id` foreign key by first nulling intra-set links. Callers
    # (e.g. a host's Chat#destroy flow) pass the ids of orphaned executions
    # after their owning records (Messages) have been destroyed.
    #
    # Raises ActiveRecord::InvalidForeignKey if any PE in the set is still
    # referenced from outside the set (e.g. another chat's branch); callers
    # decide whether to rescue and leave the orphans in place.
    def self.delete_set!(ids)
      ids = Array(ids).compact
      return if ids.empty?

      where(id: ids).update_all(previous_id: nil)
      where(id: ids).delete_all
    end

    private

    # Returns ancestor PromptExecutions in chronological order (oldest first),
    # excluding self. Optionally limit to the most recent N ancestors.
    def ancestors(limit: nil)
      chain = []
      pe = previous

      while pe
        chain.unshift(pe)
        pe = pe.previous
      end

      limit ? chain.last(limit) : chain
    end

    def set_execution_id
      self.execution_id ||= SecureRandom.uuid
    end
  end
end
