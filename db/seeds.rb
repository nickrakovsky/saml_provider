company = Company.create(
  name: "ACME Inc.",
  saml_settings: {
    idp_entity_id: "https://samltest.id/saml/idp",
    idp_sso_target_url: "https://app.onelogin.com/trust/saml2/http-redirect/sso/onelogin_app_id",
    idp_slo_target_url: "https://app.onelogin.com/trust/saml2/http-redirect/slo/onelogin_app_id"
  }
)

user = company.users.create(
  email: "test@test.com",
  password: "password",
  password_confirmation: "password"
)
