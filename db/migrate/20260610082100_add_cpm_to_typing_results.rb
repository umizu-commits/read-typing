class AddCpmToTypingResults < ActiveRecord::Migration[8.1]
  def change
    add_column :typing_results, :cpm, :float
  end
end
