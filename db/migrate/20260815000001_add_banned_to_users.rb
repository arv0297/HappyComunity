# frozen_string_literal: true

class AddBannedToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :banned, :boolean, default: false, null: false
    add_index :users, :banned
  end
end
