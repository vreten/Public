class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :buy_num
      t.string :item_num
      t.text :description
      t.string :qty
      t.string :unit
      t.string :option
      t.string :period_of_performance

      t.timestamps
    end
  end
end
