class AddIndexToTypingResultsOnUserIdAndCreatedAt < ActiveRecord::Migration[8.1]
  def change
    add_index :typing_results, [ :user_id, :created_at ]
  end
end
