class AddCategoryToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :category, :string
  end
end
