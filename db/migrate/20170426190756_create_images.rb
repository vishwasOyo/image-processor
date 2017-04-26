class CreateImages < ActiveRecord::Migration[5.0]
  def change
    create_table :images do |t|
      t.string :name
      t.string :original_url
      t.string :short_url
      t.integer :status

      t.timestamps
    end
  end
end
