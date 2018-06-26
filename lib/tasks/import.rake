# frozen_string_literal: true

require 'csv'

namespace :projects do
  task(:import_votes, [:file] => [:environment]) do |_t, args|
    errors = {}
    successes = {}

    ActiveRecord::Base.logger = nil

    CSV.foreach(File.expand_path(args[:file]), headers: true) do |row|
      row = row.to_hash
      puts "Processing #{row['DNI']}"

      handler = CensusAuthorizationHandler.new(
        document_number: row['DNI'],
        date_of_birth: Date.strptime(row['Data de naixement'], '%m/%d/%y')
      )

      authorization = Decidim::Authorization.where(
        unique_id: handler.unique_id
      ).first

      user = if authorization
               puts "User found for #{row['DNI']}: #{authorization.user.id}"
               authorization.user
             else
               user = create_managed_user(row['DNI'])
               handler.user = user
               Decidim::Authorization.create_or_update_from(handler)
               user
            end
      city_projects = (1..5).to_a.map { |i| row["Projecte Ciutat #{i}"] }.compact
      vote_projects(user, 44, city_projects) if city_projects.any?
      area_projects = (1..5).to_a.map { |i| row["Projecte Barri #{i}"] }.compact
      vote_projects(user, 45, area_projects) if area_projects.any?

      successes[row['DNI']] = [city_projects, area_projects]
      puts "Successfully processed: #{row['DNI']}"

    rescue StandardError => e
      errors[row['DNI']] = e
      puts "Error processing: #{row['DNI']} - #{e}"
    end

    puts "#{successes.keys.length} successes"
    puts "#{errors.keys.length} errors"
  end

  def create_managed_user(dni)
    name = Digest::MD5.hexdigest(dni)[0..16]

    Decidim::User.find_or_create_by!(
      organization: Decidim::Organization.first,
      managed: true,
      name: name
    ) do |u|
      u.admin = false
      u.tos_agreement = true
    end
  end

  def vote_projects(user, component_id, project_references)
    raise 'Order existing' if Decidim::Budgets::Order.where(decidim_user_id: user.id, decidim_component_id: component_id).exists?

    order = Decidim::Budgets::Order.create!(
      user: user,
      component: Decidim::Component.find(component_id)
    )

    projects = project_references.map do |reference|
      Decidim::Budgets::Project.find_by!(reference: reference)
    end

    order.projects = projects
    order.checked_out_at = Time.zone.now
    order.save!

    true
  rescue ActiveRecord::RecordInvalid => e
    raise 'Invalid Order'
  rescue ActiveRecord::RecordNotFound => e
    raise 'Invalid Project'
  end
end
