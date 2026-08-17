# frozen_string_literal: true

class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.integer :rating, null: false
      t.text :content

      t.timestamps
    end

    add_index :reviews, [ :user_id, :book_id ], unique: true
    add_check_constraint :reviews, "rating >= 1 AND rating <= 5", name: "rating_range_check"
  end
end
