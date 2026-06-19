class AddCorrectCountToTypingResults < ActiveRecord::Migration[8.1]
  def change
    add_column :typing_results, :correct_count, :integer
  end
end
