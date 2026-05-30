# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [ File.expand_path("../test/dummy/db/migrate", __dir__) ]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [ File.expand_path("fixtures", __dir__) ]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  ActiveSupport::TestCase.fixtures :all
end

# Create the prompt_navigator table on the dummy app's in-memory SQLite DB.
# Mirrors the generator's migration template; kept inline so the dummy app
# doesn't need its own migrations directory checked into the gem.
unless ActiveRecord::Base.connection.table_exists?(:prompt_navigator_prompt_executions)
  ActiveRecord::Schema.define do
    create_table :prompt_navigator_prompt_executions do |t|
      t.references :previous,
                   foreign_key: { to_table: :prompt_navigator_prompt_executions },
                   index: true, null: true
      t.string :execution_id
      t.text :prompt
      t.string :llm_platform
      t.string :model
      t.string :configuration
      t.text :response
      t.timestamps
    end
  end
end
