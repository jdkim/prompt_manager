require "test_helper"

# Tests for the PromptExecution tree model. This is the only domain model
# in the gem and the place where a regression would silently corrupt
# conversation state, so the invariants worth pinning are:
#
#   * execution_id auto-assigned via before_create (UUID), never overwritten
#   * build_context walks `previous` links oldest-first, excludes self,
#     honors the `limit:` keyword (most-recent N)
#   * delete_set! nulls intra-set previous_id links FIRST, then bulk-
#     deletes — this is the only way to drop multiple linked rows without
#     tripping the self-referential FK
#   * delete_set! leaves rows owned by callers outside the set untouched
#     and lets the FK error surface (host code decides whether to tolerate
#     orphans)
class PromptNavigator::PromptExecutionTest < ActiveSupport::TestCase
  setup do
    PromptNavigator::PromptExecution.delete_all
  end

  # Build a linear chain: root → mid → leaf. Returns [root, mid, leaf].
  def build_chain
    root = PromptNavigator::PromptExecution.create!(prompt: "p1", response: "r1")
    mid  = PromptNavigator::PromptExecution.create!(prompt: "p2", response: "r2", previous: root)
    leaf = PromptNavigator::PromptExecution.create!(prompt: "p3", response: "r3", previous: mid)
    [ root, mid, leaf ]
  end

  # ----- execution_id auto-assignment -----

  test "before_create assigns a UUID execution_id when none provided" do
    pe = PromptNavigator::PromptExecution.create!(prompt: "p", response: "r")
    assert pe.execution_id.present?
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/, pe.execution_id)
  end

  test "before_create does NOT overwrite a caller-provided execution_id" do
    pe = PromptNavigator::PromptExecution.create!(prompt: "p", response: "r", execution_id: "custom-id")
    assert_equal "custom-id", pe.execution_id
  end

  # ----- build_context (linear ancestry walk) -----

  test "build_context returns an empty array for a root execution (no previous)" do
    root = PromptNavigator::PromptExecution.create!(prompt: "p", response: "r")
    assert_equal [], root.build_context
  end

  test "build_context returns ancestors oldest-first, excluding self" do
    root, mid, leaf = build_chain

    ctx = leaf.build_context
    assert_equal [
      { prompt: "p1", response: "r1" },
      { prompt: "p2", response: "r2" }
    ], ctx
    # Confirm self (leaf) is not in the chain.
    refute_includes ctx, { prompt: leaf.prompt, response: leaf.response }
  end

  test "build_context with limit: keeps only the most recent N ancestors" do
    root = PromptNavigator::PromptExecution.create!(prompt: "p1", response: "r1")
    mid1 = PromptNavigator::PromptExecution.create!(prompt: "p2", response: "r2", previous: root)
    mid2 = PromptNavigator::PromptExecution.create!(prompt: "p3", response: "r3", previous: mid1)
    leaf = PromptNavigator::PromptExecution.create!(prompt: "p4", response: "r4", previous: mid2)

    ctx = leaf.build_context(limit: 2)
    # Most recent 2 ancestors = mid1 + mid2 (root drops off)
    assert_equal [
      { prompt: "p2", response: "r2" },
      { prompt: "p3", response: "r3" }
    ], ctx
  end

  test "build_context with limit: larger than the chain returns everything" do
    _root, _mid, leaf = build_chain
    assert_equal 2, leaf.build_context(limit: 99).size
  end

  test "build_context follows branches via the previous_id link (sibling branches not seen)" do
    root = PromptNavigator::PromptExecution.create!(prompt: "p1", response: "r1")
    PromptNavigator::PromptExecution.create!(prompt: "branch-A", response: "rA", previous: root)
    leaf_b = PromptNavigator::PromptExecution.create!(prompt: "branch-B", response: "rB", previous: root)

    # leaf_b only sees its own lineage (root), never the sibling branch.
    ctx = leaf_b.build_context
    assert_equal [ { prompt: "p1", response: "r1" } ], ctx
  end

  # ----- delete_set! -----

  test "delete_set! removes a linked chain that would otherwise trip the self-referential FK" do
    _root, mid, leaf = build_chain
    # Naive delete_all would raise InvalidForeignKey because deleting root
    # before mid violates the FK. delete_set! nulls the intra-set links first.
    ids = PromptNavigator::PromptExecution.pluck(:id)

    assert_difference -> { PromptNavigator::PromptExecution.count }, -3 do
      PromptNavigator::PromptExecution.delete_set!(ids)
    end
    # Sanity: the rows are actually gone (not just stubbed out).
    assert_not PromptNavigator::PromptExecution.exists?(mid.id)
    assert_not PromptNavigator::PromptExecution.exists?(leaf.id)
  end

  test "delete_set! is a no-op when given an empty or nil id list" do
    build_chain

    assert_no_difference -> { PromptNavigator::PromptExecution.count } do
      PromptNavigator::PromptExecution.delete_set!([])
      PromptNavigator::PromptExecution.delete_set!(nil)
    end
  end

  test "delete_set! tolerates a partial set: rows outside the set keep their previous_id intact" do
    root, mid, leaf = build_chain
    # Delete only the leaf; mid + root must survive with their links intact.
    PromptNavigator::PromptExecution.delete_set!([ leaf.id ])

    assert_not PromptNavigator::PromptExecution.exists?(leaf.id)
    assert_equal root.id, mid.reload.previous_id
  end

  test "delete_set! raises InvalidForeignKey when the set is still referenced from outside" do
    root, mid, _leaf = build_chain
    # Try to delete only root + mid. The leaf (outside the set) still
    # points at mid via previous_id, so the FK on the leaf must trip.
    assert_raises(ActiveRecord::InvalidForeignKey) do
      PromptNavigator::PromptExecution.delete_set!([ root.id, mid.id ])
    end
  end

  # ----- belongs_to :previous -----

  test "previous is optional (root rows have nil previous_id)" do
    pe = PromptNavigator::PromptExecution.create!(prompt: "p", response: "r")
    assert_nil pe.previous_id
    assert_nil pe.previous
  end

  test "previous returns the parent record by id" do
    parent = PromptNavigator::PromptExecution.create!(prompt: "p1", response: "r1")
    child = PromptNavigator::PromptExecution.create!(prompt: "p2", response: "r2", previous: parent)
    assert_equal parent.id, child.previous.id
  end
end
