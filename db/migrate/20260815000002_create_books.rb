# frozen_string_literal: true

class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.string :title, null: false
      t.string :author, null: false
      t.decimal :average_rating, precision: 3, scale: 1
      t.integer :reviews_count, default: 0, null: false

      t.timestamps
    end

    add_index :books, :average_rating
  end
end
