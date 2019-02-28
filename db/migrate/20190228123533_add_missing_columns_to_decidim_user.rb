# frozen_string_literal: true
class AddMissingColumnsToDecidimUser < ActiveRecord::Migration[5.2]
  def up
    add_column :decidim_users, :following_count, :integer, null: false, default: 0 unless column_exists? :decidim_users, :following_count
    add_column :decidim_users, :followers_count, :integer, null: false, default: 0 unless column_exists? :decidim_users, :followers_count
    remove_column :decidim_users, :following_users_count if column_exists? :decidim_users, :following_users_count
  end

  def down
    remove_column :decidim_users, :following_count unless column_exists? :decidim_users, :following_count
    remove_column :decidim_users, :followers_count unless column_exists? :decidim_users, :followers_count
    add_column :decidim_users, :following_users_count, :integer, null: false, default: 0 if column_exists? :decidim_users, :following_users_count
  end
end
