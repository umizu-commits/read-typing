class AddArticleIdToTypingResults < ActiveRecord::Migration[8.1]
  def change
    add_reference :typing_results, :article, null: true, foreign_key: true
  end
end
