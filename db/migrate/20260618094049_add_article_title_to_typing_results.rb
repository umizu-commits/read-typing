class AddArticleTitleToTypingResults < ActiveRecord::Migration[8.1]
  def change
    add_column :typing_results, :article_title, :string
  end
end
