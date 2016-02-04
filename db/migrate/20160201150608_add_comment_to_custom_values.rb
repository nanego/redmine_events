class AddCommentToCustomValues < ActiveRecord::Migration
  def change
    change_table :custom_values do |t|
      t.string :comment
    end
  end
end
