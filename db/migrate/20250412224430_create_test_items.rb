# frozen_string_literal: true

class CreateTestItems < ActiveRecord::Migration[7.2]
  def change
    create_table :test_items do |t|
      t.integer :unique_field
      t.index :unique_field, unique: true
      t.text :data

      t.timestamps
    end
  end
end
