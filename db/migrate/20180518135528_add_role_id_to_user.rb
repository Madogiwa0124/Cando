class AddRoleIdToUser < ActiveRecord::Migration[5.2]
  def change
    add_reference :users, :role, default: Role.find_by(code: :staff).id
  end
end
