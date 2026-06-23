class CreateUserAchievements < ActiveRecord::Migration[8.1]
  def change
    create_table :user_achievements do |t|
      t.references :user, null: false, foreign_key: true
      t.string :achievement_key, null: false
      t.datetime :achieved_at, null: false
      t.datetime :notified_at

      t.timestamps
    end

    add_index :user_achievements, [ :user_id, :achievement_key ], unique: true
  end
end
