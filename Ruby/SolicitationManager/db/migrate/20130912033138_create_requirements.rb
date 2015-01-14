class CreateRequirements < ActiveRecord::Migration
  def change
    create_table :requirements do |t|
      t.string :buy_num
      t.string :title
      t.text :specification

      t.timestamps
    end
  end
end
