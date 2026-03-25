# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-25

### Added

- LLM platform labels on history cards with brand-colored pill badges (OpenAI, Anthropic, Google, Ollama)

## [0.3.0] - 2026-03-18

### Added

- `PromptExecution#build_context` method for building summarization context from ancestor executions

### Changed

- `PromptExecution#ancestors` method moved to private scope (internal use only)

## [0.1.0] - 2026-02-24

### Added

- Initial release
- `PromptExecution` model for tracking LLM prompt execution history with self-referencing tree structure
- `HistoryManageable` controller concern for history state management
- Visual history stack UI with ERB partials (`_history`, `_history_card`)
- Stimulus-powered SVG arrow visualization between parent-child history cards
- `history_list` view helper for rendering the history component
- `prompt_navigator:modeling` Rails generator for creating migrations
- Automatic asset pipeline integration (CSS and JavaScript)
