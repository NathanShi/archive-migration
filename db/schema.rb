ActiveRecord::Schema.define(:version => 20180403201737) do
  create_table "testing" do |t|
    t.string   "name",                          :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end
end
