class AddCommentableToCustomFields < ActiveRecord::Migration
  def change
    change_table :custom_fields do |t|
      t.boolean :commentable, default: false
    end
  end
end
