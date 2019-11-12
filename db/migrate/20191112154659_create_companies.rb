class CreateCompanies < ActiveRecord::Migration[5.2]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.json :saml_settings, default: {}, null: false

      t.timestamps
    end
  end
end
