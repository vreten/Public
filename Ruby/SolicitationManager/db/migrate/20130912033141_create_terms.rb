class CreateTerms < ActiveRecord::Migration
  def change
    create_table :terms do |t|
      t.string :buy_num
      t.string :title
      t.text :specification

      t.timestamps
    end
  end
end
