class AddPermissions < ActiveRecord::Migration[5.2]
  def up
		Role.all.each{|tr|
			changed = false

			if tr.permissions.include?(:view_issues) then
				tr.permissions += [
				]
				changed = true
			end
			if tr.permissions.include?(:edit_issues) then
				tr.permissions += [
          :csys_git_export,
				]
				changed = true
			end
			if changed then
				tr.save
			end
		}
  end

  def down

  end
end
