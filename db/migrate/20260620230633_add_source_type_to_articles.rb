class AddSourceTypeToArticles < ActiveRecord::Migration[8.1]
  def change
    change_column_null :articles, :url, true
    add_column :articles, :source_type, :string, null: false, default: "url"
  end
end
