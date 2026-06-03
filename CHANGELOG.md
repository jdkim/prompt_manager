# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-06-04

### Added

- Leaf-only delete button on history cards. Cards with no children (i.e. leaves of the lineage tree) render a small trash icon; non-leaves don't, so the host can't break the chain by deleting a mid-tree node by accident. Host owns the destroy route as before.

### Changed

- History cards strip inline `data:` image URIs from rendered prompt/response previews — large base64 blobs no longer balloon the sidebar.
- Tighter spacing between heading and card stack; uniform vertical rhythm between cards; bolder connector arrow stroke.
- Curved-arrow control point offset rescaled so arcs stay tidy when the stack grows tall; platform-badge tooltip now shows the full model name on hover.

### Tested

- `PromptExecution` lineage walk (multi-hop ancestry returned oldest-first).
- `PromptExecution.delete_set!` FK invariants — intra-set `previous_id` nulling and `ActiveRecord::InvalidForeignKey` when references leak outside the set.

## [2.0.0] - 2026-04-22

### Added

- `PromptExecution.delete_set!(ids)` class method for safely bulk-deleting a set of executions. Nulls the intra-set `previous_id` foreign key before deletion so hosts don't have to reason about the self-referential DAG. Raises `ActiveRecord::InvalidForeignKey` when any id in the set is still referenced from outside, letting callers choose whether to tolerate orphans.

### Changed

- **BREAKING:** Raised minimum Ruby version from 3.2.0 to 3.4.9.

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
