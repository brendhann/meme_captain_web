class DropBlockedIps < ActiveRecord::Migration
  def change
    drop_table :blocked_ips do |t|
      t.text :ip, null: false
      t.timestamps null: false
    end
  end
end
