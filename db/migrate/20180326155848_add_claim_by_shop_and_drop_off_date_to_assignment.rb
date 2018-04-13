class AddClaimByShopAndDropOffDateToAssignment < ActiveRecord::Migration
  def change
    add_column :assignments, :drop_off_date, :date
    add_column :assignments, :claim_by_shop, :boolean
  end
end
