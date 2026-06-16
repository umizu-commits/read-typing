class ModifyArticlesForAnonymousUsers < ActiveRecord::Migration[8.1]
  def change
    change_column_null :articles, :user_id, true

    remove_index :articles, column: :url, unique: true
    add_index :articles, [ :url, :user_id ], unique: true

    add_column :articles, :expires_at, :datetime
    add_index :articles, :expires_at
  end
end
