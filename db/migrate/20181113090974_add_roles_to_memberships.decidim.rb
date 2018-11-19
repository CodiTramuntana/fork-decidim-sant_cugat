# frozen_string_literal: true
# This migration comes from decidim (originally 20181011080252)

class AddRolesToMemberships < ActiveRecord::Migration[5.2]
  def up
    add_column :decidim_user_group_memberships, :role, :string, default: "requested"
    execute("UPDATE decidim_user_group_memberships SET role = 'creator'")
    change_column_null :decidim_user_group_memberships, :role, false

    groups_with_multiple_users = Decidim::UserGroup.find_each.select do |group|
      group.memberships.count > 1
    end

    groups_with_multiple_users.each do |group|
      memberships = group.memberships.order(:created_at).to_a
      memberships.shift
      memberships.each do |membership|
        membership.role = "admin"
        membership.save!
      end
    end

    add_index(
      :decidim_user_group_memberships,
      %w(role decidim_user_group_id),
      where: "(role = 'creator')",
      name: "decidim_group_membership_one_creator_per_group",
      unique: true
    )
  end

  def down
    remove_column :decidim_user_group_memberships, :role
    remove_index(
      :decidim_user_group_memberships,
      name: "decidim_group_membership_one_creator_per_group"
    )
  end
end
