class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.string :url, null: false
      t.text :body, null: false

      t.timestamps
    end
    add_index :articles, :url, unique: true
  end
end
