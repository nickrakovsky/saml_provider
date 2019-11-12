# frozen_string_literal: true

class ClientController < SamlIdp::IdpController

  skip_before_action :verify_authenticity_token, only: %i[acs logout]

  def index
    @attrs = {}
  end

  def sso
    settings = saml_settings(url_base)
    if settings.nil?
      render action: :no_settings
      return
    end

    request = OneLogin::RubySaml::Authrequest.new
    redirect_to(request.create(settings))
  end

  def acs
    settings = saml_settings(url_base)
    response = OneLogin::RubySaml::Response.new(params[:SAMLResponse], settings: settings)

    if response.is_valid?
      session[:nameid] = response.nameid
      session[:attributes] = response.attributes
      @attrs = session[:attributes]
      logger.info "Sucessfully logged"
      logger.info "NAMEID: #{response.nameid}"
      render action: :index
    else
      logger.info "Response Invalid. Errors: #{response.errors}"
      @errors = response.errors
      render action: :fail
    end
  end

  def metadata
    settings = saml_settings(url_base)
    meta = OneLogin::RubySaml::Metadata.new
    render xml: meta.generate(settings, true)
  end

  # Trigger SP and IdP initiated Logout requests
  def logout
    # If we're given a logout request, handle it in the IdP logout initiated method
    if params[:SAMLRequest]
      idp_logout_request

    # We've been given a response back from the IdP
    elsif params[:SAMLResponse]
      process_logout_response
    elsif params[:slo]
      sp_logout_request
    else
      reset_session
    end
  end

  # Create an SP initiated SLO
  def sp_logout_request
    # LogoutRequest accepts plain browser requests w/o paramters
    settings = saml_settings(url_base)

    if settings.idp_slo_target_url.nil?
      logger.info "SLO IdP Endpoint not found in settings, executing then a normal logout'"
      reset_session
    else

      # Since we created a new SAML request, save the transaction_id
      # to compare it with the response we get back
      logout_request = OneLogin::RubySaml::Logoutrequest.new
      session[:transaction_id] = logout_request.uuid
      logger.info "New SP SLO for User ID: '#{session[:nameid]}', Transaction ID: '#{session[:transaction_id]}'"

      settings.name_identifier_value = session[:nameid] if settings.name_identifier_value.nil?

      relay_state = url_for controller: "saml", action: "index"
      redirect_to(logout_request.create(settings, RelayState: relay_state))
    end
  end

  # After sending an SP initiated LogoutRequest to the IdP, we need to accept
  # the LogoutResponse, verify it, then actually delete our session.
  def process_logout_response
    settings = saml_settings(url_base)
    request_id = session[:transaction_id]
    logout_response = OneLogin::RubySaml::Logoutresponse.new(
      params[:SAMLResponse], settings, matches_request_id: request_id, get_params: params
    )
    logger.info "LogoutResponse is: #{logout_response.response}"

    # Validate the SAML Logout Response
    if !logout_response.validate
      error_msg = "The SAML Logout Response is invalid.  Errors: #{logout_response.errors}"
      logger.error error_msg
      render inline: error_msg
    elsif logout_response.success?
      # Actually log out this session
      logger.info "Delete session for '#{session[:nameid]}'"
      reset_session
    end
  end

  # Method to handle IdP initiated logouts
  def idp_logout_request
    settings = saml_settings(url_base)
    logout_request = OneLogin::RubySaml::SloLogoutrequest.new(
      params[:SAMLRequest], settings: settings
    )
    unless logout_request.is_valid?
      error_msg = "IdP initiated LogoutRequest was not valid!. Errors: #{logout_request.errors}"
      logger.error error_msg
      render inline: error_msg
    end
    logger.info "IdP initiated Logout for #{logout_request.nameid}"

    # Actually log out this session
    reset_session

    logout_response = OneLogin::RubySaml::SloLogoutresponse.new.create(
      settings, logout_request.id, nil, RelayState: params[:RelayState]
    )
    redirect_to logout_response
  end

  def url_base
    "#{request.protocol}#{request.host_with_port}"
  end

  private

  def saml_settings(url_base)
    # this is just for testing purposes.
    # should retrieve SAML-settings based on subdomain, IP-address, NameID or similar
    settings = OneLogin::RubySaml::Settings.new

    url_base ||= "http://localhost:3000"

    # Example settings data, replace this values!

    # When disabled, saml validation errors will raise an exception.
    settings.soft = true

    # SP section
    settings.issuer = "#{url_base}/saml/metadata"
    settings.assertion_consumer_service_url = "#{url_base}/saml/acs"
    settings.assertion_consumer_logout_service_url = "#{url_base}/saml/logout"

    onelogin_app_id = "<onelogin-app-id>"

    # IdP section
    settings.idp_entity_id = "https://app.onelogin.com/saml/metadata/#{onelogin_app_id}"
    settings.idp_sso_target_url = "https://app.onelogin.com/trust/saml2/http-redirect/sso/#{onelogin_app_id}"
    settings.idp_slo_target_url = "https://app.onelogin.com/trust/saml2/http-redirect/slo/#{onelogin_app_id}"
    settings.idp_cert = ""


    # or settings.idp_cert_fingerprint = ""
    #    settings.idp_cert_fingerprint_algorithm = XMLSecurity::Document::SHA1

    settings.name_identifier_format = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"

    # Security section
    settings.security[:authn_requests_signed] = false
    settings.security[:logout_requests_signed] = false
    settings.security[:logout_responses_signed] = false
    settings.security[:metadata_signed] = false
    settings.security[:digest_method] = XMLSecurity::Document::SHA1
    settings.security[:signature_method] = XMLSecurity::Document::RSA_SHA1

    settings
  end

end
