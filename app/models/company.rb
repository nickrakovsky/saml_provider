# frozen_string_literal: true

# == Schema Information
#
# Table name: companies
#
#  id            :integer          not null, primary key
#  name          :string           not null
#  saml_settings :json             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#


class Company < ApplicationRecord

  has_many :users

  validates :name, presence: true

end
