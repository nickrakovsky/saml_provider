company = Company.create(
  name: "ACME Inc.",
  saml_settings: {
    idp_entity_id: "https://samltest.id/saml/idp",
    idp_sso_target_url: "https://samltest.id/idp/profile/SAML2/Redirect/SSO",
    idp_slo_target_url: "https://samltest.id/idp/profile/SAML2/Redirect/SLO"
  }
)

user = company.users.create(
  email: "test@test.com",
  password: "password",
  password_confirmation: "password"
)
