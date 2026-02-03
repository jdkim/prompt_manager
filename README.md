# PromptManager

Rails engine for managing prompt execution history with visual interface.

## Features

- Visual history stack with parent-child relationships
- Modern CSS with nested syntax
- Stimulus-powered interactive arrows
- Automatic asset pipeline integration
- Active state highlighting
- Responsive design with hover effects
- Built-in model for tracking prompt executions

## Installation

Add this line to your application's Gemfile:

```ruby
gem "prompt_manager"
```

And then execute:

```bash
$ bundle install
```

Generate the migration for prompt executions:

```bash
$ rails generate prompt_manager:modeling
$ rails db:migrate
```

This will create the `prompt_manager_prompt_executions` table with the following fields:

- `execution_id` - Unique identifier (UUID) for each prompt execution
- `prompt` - The prompt text
- `llm_platform` - The LLM platform used (e.g., "openai", "anthropic")
- `model` - The model name (e.g., "gpt-4", "claude-3")
- `configuration` - Model configuration settings
- `response` - The LLM response
- `previous_id` - Reference to the parent execution (for history tree)

## Usage

### Basic Setup

In your application's layout file (`app/views/layouts/application.html.erb`), make sure you have `<%= yield :head %>` in the `<head>` section:

```erb
<head>
  <title>Your App</title>
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  
  <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
  <%= javascript_importmap_tags %>
  
  <%= yield :head %>
</head>
```

Include the history partial in your view:

```erb
<%= render 'prompt_manager/history', locals: { active_uuid: @current_execution_id, card_path: ->(execution_id) { my_path(execution_id) } } %>
```

### Asset Pipeline Configuration

The engine automatically configures the asset pipeline to include:
- `prompt_manager/history.css` - Styles for the history component
- `controllers/history_controller.js` - Stimulus controller for arrow drawing

The assets are automatically precompiled and made available to your application. For Rails 7+ with importmap, the CSS will be loaded via `stylesheet_link_tag` when you render the history partial, and the Stimulus controller will be automatically registered.

### Controller Setup

Include `HistoryManageable` concern in your controller:

```ruby
class MyController < ApplicationController
  include HistoryManageable
  
  def index
    # Initialize history with prompt executions
    initialize_history(PromptManager::PromptExecution.all)
    
    # Set the active execution ID (optional)
    set_active_message_uuid(params[:execution_id])
  end
  
  def create
    # Add new execution to history
    new_execution = PromptManager::PromptExecution.create(
      prompt: params[:prompt],
      llm_platform: "openai",
      model: "gpt-4",
      configuration: params[:config].to_json,
      response: llm_response,
      previous: @current_execution
    )
    push_to_history(new_execution)
  end
end
```

### Using PromptExecution Model

The `PromptManager::PromptExecution` model has the following attributes and methods:

```ruby
execution = PromptManager::PromptExecution.create(
  prompt: "Your prompt text",
  llm_platform: "openai",
  model: "gpt-4",
  configuration: "{\"temperature\": 0.7}",
  response: "LLM response text",
  previous: parent_execution  # Optional: for building history tree
)

# Access fields
execution.execution_id  # UUID, automatically generated
execution.prompt        # The prompt text
execution.llm_platform  # LLM platform used
execution.model         # Model name
execution.configuration # Configuration JSON
execution.response      # LLM response
execution.previous      # Parent execution (belongs_to association)
```

### Using the Helper Method

The helper methods are automatically included in your views. You can use the `history_list` helper:

```erb
<%= history_list(->(execution_id) { my_item_path(execution_id) }, active_uuid: @current_execution_id) %>
```

### Customizing the Card Path

The `card_path` parameter should be a callable (Proc or lambda) that takes an execution_id and returns a path:

```erb
<%= render 'prompt_manager/history', 
    locals: { 
      active_uuid: @current_execution_id, 
      card_path: ->(execution_id) { my_item_path(execution_id) }
    } 
%>
```

Or using the helper:

```erb
<%= history_list(->(execution_id) { my_item_path(execution_id) }, active_uuid: @current_execution_id) %>
```

## Troubleshooting

### Styles not loading

Make sure you have `<%= yield :head %>` in your application layout's `<head>` section.

### Arrows not appearing

The arrow visualization requires:
1. Stimulus to be properly configured in your application
2. The `history_controller.js` to be loaded (automatic with importmap)
3. Parent-child relationships to be properly set using the `previous` association in your PromptExecution records

### History not displaying

Ensure that:
1. `@history` instance variable is set in your controller using `initialize_history`
2. Your PromptExecution records have `execution_id` values (automatically generated on create)
3. The `card_path` callable is correctly defined and returns valid paths

## Requirements

- Rails >= 8.1.2
- Stimulus (Hotwired)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "prompt_manager"
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install prompt_manager
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
