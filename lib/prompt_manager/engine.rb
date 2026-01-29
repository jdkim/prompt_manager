# frozen_string_literal: true

module PromptManager
  class Engine < ::Rails::Engine
    isolate_namespace PromptManager

    # Initialize helper methods to be available in ActionView
    # This makes PromptManager::Helpers methods accessible in Rails views
    initializer "prompt_manager.helpers" do
      ActiveSupport.on_load(:action_view) do
        include PromptManager::Helpers
      end
    end

    # Configure asset paths for the engine
    # This ensures that JavaScript and CSS files are properly loaded
    initializer "prompt_manager.assets", before: "sprockets.environment" do |app|
      # Add asset paths
      app.config.assets.paths << root.join("app/assets/stylesheets").to_s
      app.config.assets.paths << root.join("app/javascript").to_s

      # Precompile assets
      if app.config.respond_to?(:assets)
        app.config.assets.precompile += %w[
          prompt_manager/history.css
          prompt_manager/application.css
          controllers/history_controller.js
        ]
      end
    end
  end
end
