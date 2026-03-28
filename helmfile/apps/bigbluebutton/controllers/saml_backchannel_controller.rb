# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
# frozen_string_literal: true

# SAML Backchannel Logout Controller for BigBlueButton
#
# Handles SAML 2.0 Single Logout (SLO) backchannel requests from Keycloak.
# When a user logs out from the portal, Keycloak sends a backchannel logout
# request to this endpoint to terminate the user's BBB session.
#
# @see https://docs.bigbluebutton.org/development/api
# @see https://wiki.shibboleth.net/confluence/display/CONCEPT/LogoutService
#
class SamlBackchannelController < ApplicationController
  # Skip CSRF protection for SAML POST requests (server-to-server communication)
  skip_before_action :verify_authenticity_token, only: [:logout]
  
  # Skip authentication for backchannel logout endpoint
  skip_before_action :authenticate_user!, only: [:logout]

  # SAML namespace constants
  SAML_PROTOCOL_NS = 'urn:oasis:names:tc:SAML:2.0:protocol'.freeze
  SAML_ASSERTION_NS = 'urn:oasis:names:tc:SAML:2.0:assertion'.freeze
  SAML_SIGNATURE_NS = 'http://www.w3.org/2000/09/xmldsig#'.freeze

  # Timeout for session termination (seconds)
  SESSION_TERMINATION_TIMEOUT = ENV.fetch('BACKCHANNEL_LOGOUT_BBB_TIMEOUT', 30).to_i

  # Enable verbose logging for debugging
  VERBOSE_LOGGING = ENV.fetch('BACKCHANNEL_LOGOUT_BBB_VERBOSE', 'false') == 'true'

  # Warning time before meeting termination (seconds)
  MEETING_WARNING_DELAY = 5

  ##
  # Handle SAML backchannel logout request
  #
  # POST /saml/logout
  #
  # Accepts SAML LogoutRequest from Keycloak, verifies the signature,
  # terminates any active BBB meetings, and returns a LogoutResponse.
  #
  # @return [String] SAML LogoutResponse XML
  #
  def logout
    log_event(:info, 'saml_backchannel_logout_started', {
      remote_ip: request.remote_ip,
      user_agent: request.user_agent,
      content_type: request.content_type
    })

    begin
      # Read SAML LogoutRequest from POST body
      saml_request = read_saml_request
      return render_error_response(400, 'Invalid SAML request: empty body') if saml_request.blank?

      # Parse the SAML request XML
      logout_request = parse_saml_request(saml_request)
      return render_error_response(400, 'Failed to parse SAML request') unless logout_request

      # Extract request metadata
      request_id = logout_request['ID']
      issuer = extract_issuer(logout_request)
      session_index = extract_session_index(logout_request)
      user_id = extract_user_id(logout_request)

      log_event(:debug, 'saml_request_parsed', {
        request_id: request_id,
        issuer: issuer,
        session_index: session_index,
        user_id: user_id
      }) if VERBOSE_LOGGING

      # Verify the signature from Keycloak
      unless verify_signature(logout_request)
        log_event(:warn, 'saml_signature_verification_failed', {
          request_id: request_id,
          issuer: issuer
        })
        return render_error_response(403, 'Signature verification failed')
      end

      log_event(:info, 'saml_signature_verified', {
        request_id: request_id,
        user_id: user_id
      })

      # Process the logout - terminate BBB sessions
      termination_result = process_logout(user_id, session_index)

      # Log successful logout
      log_event(:info, 'saml_backchannel_logout_completed', {
        request_id: request_id,
        user_id: user_id,
        session_index: session_index,
        meetings_terminated: termination_result[:meetings_terminated],
        sessions_destroyed: termination_result[:sessions_destroyed]
      })

      # Return successful SAML LogoutResponse
      render_successful_response(request_id)

    rescue Nokogiri::XML::SyntaxError => e
      log_event(:error, 'saml_xml_parse_error', {
        error: e.message,
        backtrace: e.backtrace&.first(5)
      })
      render_error_response(400, "Invalid XML: #{e.message}")

    rescue StandardError => e
      log_event(:error, 'saml_backchannel_logout_error', {
        error: e.message,
        error_class: e.class.name,
        backtrace: e.backtrace&.first(10)
      })
      render_error_response(500, "Internal error: #{e.message}")
    end
  end

  private

  ##
  # Read SAML request from POST body
  #
  # @return [String, nil] Raw SAML request XML
  #
  def read_saml_request
    request.body.rewind
    content = request.body.read
    request.body.rewind
    content.presence
  end

  ##
  # Parse SAML LogoutRequest XML
  #
  # @param saml_request [String] Raw SAML XML
  # @return [Nokogiri::XML::Document, nil] Parsed document
  #
  def parse_saml_request(saml_request)
    doc = Nokogiri::XML(saml_request) do |config|
      config.strict.nonet
    end
    doc
  rescue Nokogiri::XML::SyntaxError
    nil
  end

  ##
  # Extract issuer from SAML request
  #
  # @param doc [Nokogiri::XML::Document] Parsed SAML document
  # @return [String, nil] Issuer entity ID
  #
  def extract_issuer(doc)
    issuer_element = doc.at_xpath(
      '//saml:Issuer',
      saml: SAML_ASSERTION_NS
    )
    issuer_element&.text
  end

  ##
  # Extract SessionIndex from SAML request
  #
  # @param doc [Nokogiri::XML::Document] Parsed SAML document
  # @return [String, nil] Session index
  #
  def extract_session_index(doc)
    session_index_element = doc.at_xpath(
      '//samlp:SessionIndex',
      samlp: SAML_PROTOCOL_NS
    )
    session_index_element&.text
  end

  ##
  # Extract user identifier from SAML request
  #
  # The user ID is typically in the NameID element
  #
  # @param doc [Nokogiri::XML::Document] Parsed SAML document
  # @return [String, nil] User identifier
  #
  def extract_user_id(doc)
    name_id_element = doc.at_xpath(
      '//saml:NameID',
      saml: SAML_ASSERTION_NS
    )
    name_id_element&.text
  end

  ##
  # Verify SAML request signature using Keycloak's public key
  #
  # @param doc [Nokogiri::XML::Document] Parsed SAML document
  # @return [Boolean] True if signature is valid
  #
  def verify_signature(doc)
    require_signed = ENV.fetch('BACKCHANNEL_LOGOUT_BBB_REQUIRE_SIGNED_REQUESTS', 'true') == 'true'
    
    # If signature verification is disabled, return true
    return true unless require_signed

    # Find the signature element
    signature_element = doc.at_xpath(
      '//ds:Signature',
      ds: SAML_SIGNATURE_NS
    )

    unless signature_element
      log_event(:warn, 'saml_signature_missing', {})
      return false
    end

    # Get Keycloak's public key for verification
    keycloak_public_key = fetch_keycloak_public_key
    return false unless keycloak_public_key

    # Verify the signature using the public key
    verify_xml_signature(doc, signature_element, keycloak_public_key)
  end

  ##
  # Fetch Keycloak's public key from metadata or environment
  #
  # @return [OpenSSL::PKey::RSA, nil] Public key for signature verification
  #
  def fetch_keycloak_public_key
    # Try environment variable first (preferred for production)
    cert_pem = ENV.fetch('KEYCLOAK_SIGNING_CERTIFICATE', nil)
    
    if cert_pem.present?
      begin
        cert = OpenSSL::X509::Certificate.new(cert_pem)
        return cert.public_key
      rescue OpenSSL::X509::CertificateError => e
        log_event(:error, 'keycloak_cert_parse_error', { error: e.message })
        return nil
      end
    end

    # Fallback: Fetch from Keycloak metadata endpoint
    fetch_keycloak_public_key_from_metadata
  end

  ##
  # Fetch public key from Keycloak SAML metadata
  #
  # @return [OpenSSL::PKey::RSA, nil] Public key
  #
  def fetch_keycloak_public_key_from_metadata
    metadata_url = ENV.fetch('KEYCLOAK_SAML_METADATA_URL', nil)
    return nil unless metadata_url

    begin
      require 'net/http'
      uri = URI(metadata_url)
      response = Net::HTTP.get_response(uri)
      
      return nil unless response.code == '200'

      metadata_doc = Nokogiri::XML(response.body)
      
      # Extract X509 certificate from metadata
      cert_element = metadata_doc.at_xpath(
        '//ds:X509Certificate',
        ds: SAML_SIGNATURE_NS
      )
      
      return nil unless cert_element

      # Decode and create certificate
      cert_der = Base64.decode64(cert_element.text)
      cert = OpenSSL::X509::Certificate.new(cert_der)
      cert.public_key

    rescue StandardError => e
      log_event(:error, 'keycloak_metadata_fetch_error', {
        url: metadata_url,
        error: e.message
      })
      nil
    end
  end

  ##
  # Verify XML signature using public key
  #
  # @param doc [Nokogiri::XML::Document] Full document
  # @param signature_element [Nokogiri::XML::Element] Signature element
  # @param public_key [OpenSSL::PKey::RSA] Public key
  # @return [Boolean] True if valid
  #
  def verify_xml_signature(doc, signature_element, public_key)
    require 'openssl'

    # Extract signed info
    signed_info = signature_element.at_xpath('./ds:SignedInfo', ds: SAML_SIGNATURE_NS)
    signature_value = signature_element.at_xpath('./ds:SignatureValue', ds: SAML_SIGNATURE_NS)

    return false unless signed_info && signature_value

    # Get canonicalization method
    canonicalization_method = signed_info.at_xpath('./ds:CanonicalizationMethod', ds: SAML_SIGNATURE_NS)
    canonicalization_algorithm = canonicalization_method&.[]('Algorithm') || 'http://www.w3.org/2001/10/xml-exc-c14n#'

    # Canonicalize the SignedInfo
    canonicalizer = Nokogiri::XML::Canonicalizer.new(
      Nokogiri::XML::Canonicalizer::EXCLUSIVE_XML_CANONICALIZATION
    )
    canonical_signed_info = canonicalizer.canonicalize(signed_info)

    # Decode signature value
    signature_bytes = Base64.decode64(signature_value.text.strip)

    # Verify signature
    public_key.verify(OpenSSL::Digest::SHA256.new, signature_bytes, canonical_signed_info)
  rescue StandardError => e
    log_event(:error, 'xml_signature_verification_error', { error: e.message })
    false
  end

  ##
  # Process logout - terminate BBB sessions and meetings
  #
  # @param user_id [String] User identifier
  # @param session_index [String, nil] SAML session index
  # @return [Hash] Result with termination counts
  #
  def process_logout(user_id, session_index)
    result = {
      meetings_terminated: 0,
      sessions_destroyed: 0,
      warnings_sent: 0
    }

    return result if user_id.blank?

    # Find active BBB meetings for this user
    active_meetings = find_user_meetings(user_id)

    if active_meetings.any?
      log_event(:info, 'active_meetings_found', {
        user_id: user_id,
        meeting_count: active_meetings.length,
        meeting_ids: active_meetings.map { |m| m[:meeting_id] }
      })

      # Send warning to users in meetings before terminating
      if send_warning_before_termination?
        active_meetings.each do |meeting|
          send_meeting_warning(meeting[:meeting_id], user_id)
          result[:warnings_sent] += 1
        end

        # Wait for warning to be displayed
        sleep(MEETING_WARNING_DELAY)
      end

      # Terminate each meeting
      active_meetings.each do |meeting|
        if terminate_bbb_meeting(meeting[:meeting_id], meeting[:moderator_password])
          result[:meetings_terminated] += 1
          log_event(:info, 'meeting_terminated', {
            meeting_id: meeting[:meeting_id],
            user_id: user_id
          })
        end
      end
    end

    # Destroy Rails sessions for this user
    result[:sessions_destroyed] = destroy_user_sessions(user_id, session_index)

    result
  end

  ##
  # Find active BBB meetings for a user
  #
  # @param user_id [String] User identifier
  # @return [Array<Hash>] List of meetings with meeting_id and moderator_password
  #
  def find_user_meetings(user_id)
    meetings = []

    begin
      # Get all meetings from BBB API
      api_response = call_bbb_api('getMeetings')

      return meetings unless api_response && api_response['meetings']

      meetings_list = api_response['meetings']['meeting']
      meetings_list = [meetings_list] if meetings_list.is_a?(Hash)
      meetings_list ||= []

      # Filter meetings where the user is moderator or creator
      meetings_list.each do |meeting|
        # Check if user is associated with this meeting
        # BBB stores the user who created the meeting in metadata
        creator_id = meeting.dig('metadata', 'bbb-context-name') ||
                     meeting.dig('metadata', 'user-id') ||
                     meeting['meetingName']

        # Also check participant list
        participants = meeting['attendees']&.[]('attendee') || []
        participants = [participants] if participants.is_a?(Hash)

        is_user_meeting = (creator_id == user_id) ||
                          participants.any? { |p| p['userID'] == user_id }

        if is_user_meeting && meeting['running'] == 'true'
          meetings << {
            meeting_id: meeting['meetingID'],
            moderator_password: meeting['moderatorPW'],
            meeting_name: meeting['meetingName']
          }
        end
      end

    rescue StandardError => e
      log_event(:error, 'find_meetings_error', {
        user_id: user_id,
        error: e.message
      })
    end

    meetings
  end

  ##
  # Call BigBlueButton API
  #
  # @param action [String] API action name
  # @param params [Hash] Additional parameters
  # @return [Hash, nil] Parsed API response
  #
  def call_bbb_api(action, params = {})
    bbb_url = ENV.fetch('BBB_SERVER_URL', nil)
    bbb_secret = ENV.fetch('BBB_SECRET_KEY', nil)

    return nil if bbb_url.blank? || bbb_secret.blank?

    # Build API URL with checksum
    query_string = params.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
    checksum_string = "#{action}#{query_string}#{bbb_secret}"
    checksum = Digest::SHA256.hexdigest(checksum_string)

    api_url = "#{bbb_url}/api/#{action}?#{query_string}&checksum=#{checksum}"

    log_event(:debug, 'bbb_api_call', {
      action: action,
      url: api_url.gsub(checksum, '[REDACTED]')
    }) if VERBOSE_LOGGING

    require 'net/http'
    uri = URI(api_url)
    response = Net::HTTP.get_response(uri)

    return nil unless response.code == '200'

    # Parse XML response
    doc = Nokogiri::XML(response.body)
    
    # Convert to hash for easier handling
    response_hash = xml_to_hash(doc.root)
    
    response_hash
  rescue StandardError => e
    log_event(:error, 'bbb_api_error', {
      action: action,
      error: e.message
    })
    nil
  end

  ##
  # Convert XML to Hash
  #
  # @param node [Nokogiri::XML::Node] XML node
  # @return [Hash, String] Converted value
  #
  def xml_to_hash(node)
    if node.children.empty?
      node.text
    elsif node.children.all? { |c| c.text? }
      node.text
    else
      result = {}
      node.children.each do |child|
        next if child.text?
        
        key = child.name
        value = xml_to_hash(child)
        
        if result[key]
          result[key] = [result[key]] unless result[key].is_a?(Array)
          result[key] << value
        else
          result[key] = value
        end
      end
      result
    end
  end

  ##
  # Terminate a BBB meeting
  #
  # @param meeting_id [String] Meeting ID
  # @param moderator_password [String] Moderator password
  # @return [Boolean] True if terminated successfully
  #
  def terminate_bbb_meeting(meeting_id, moderator_password)
    return false if meeting_id.blank? || moderator_password.blank?

    response = call_bbb_api('end', {
      meetingID: meeting_id,
      password: moderator_password
    })

    success = response && response['returncode'] == 'SUCCESS'

    unless success
      log_event(:warn, 'meeting_termination_failed', {
        meeting_id: meeting_id,
        response: response
      })
    end

    success
  rescue StandardError => e
    log_event(:error, 'meeting_termination_error', {
      meeting_id: meeting_id,
      error: e.message
    })
    false
  end

  ##
  # Send warning notification to users in meeting
  #
  # Uses Redis/WebSocket to notify users before meeting termination
  #
  # @param meeting_id [String] Meeting ID
  # @param user_id [String] User who triggered logout
  # @return [Boolean] True if warning sent
  #
  def send_meeting_warning(meeting_id, user_id)
    begin
      # Publish warning via Redis pub/sub or ActionCable
      # This notifies all users in the meeting that it will be terminated
      
      warning_message = {
        type: 'meeting_termination_warning',
        meeting_id: meeting_id,
        message: 'This meeting will end in 5 seconds due to session logout.',
        triggered_by: user_id,
        timestamp: Time.current.iso8601
      }

      # Try to publish via ActionCable if available
      if defined?(ActionCable)
        ActionCable.server.broadcast(
          "meeting_#{meeting_id}",
          warning_message
        )
        log_event(:info, 'meeting_warning_sent', {
          meeting_id: meeting_id,
          channel: "meeting_#{meeting_id}"
        })
        return true
      end

      # Fallback: Try Redis pub/sub directly
      if defined?(Redis)
        redis_client = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
        redis_client.publish(
          "meeting:#{meeting_id}:notifications",
          warning_message.to_json
        )
        redis_client.close
        log_event(:info, 'meeting_warning_sent_redis', {
          meeting_id: meeting_id
        })
        return true
      end

      log_event(:warn, 'meeting_warning_no_channel', {
        meeting_id: meeting_id
      })
      false

    rescue StandardError => e
      log_event(:error, 'meeting_warning_error', {
        meeting_id: meeting_id,
        error: e.message
      })
      false
    end
  end

  ##
  # Check if warning should be sent before termination
  #
  # @return [Boolean]
  #
  def send_warning_before_termination?
    ENV.fetch('BACKCHANNEL_LOGOUT_BBB_SEND_WARNING', 'true') == 'true'
  end

  ##
  # Destroy user sessions from Rails session store
  #
  # @param user_id [String] User identifier
  # @param session_index [String, nil] SAML session index
  # @return [Integer] Number of sessions destroyed
  #
  def destroy_user_sessions(user_id, session_index)
    destroyed_count = 0

    begin
      # Use the session store to find and destroy sessions
      # This depends on the session store being used (Redis, ActiveRecord, etc.)
      
      case Rails.configuration.session_store
      when :active_record_store, ActiveRecord::SessionStore
        # For ActiveRecord session store
        sessions = ActiveRecord::SessionStore::Session
                    .where("data LIKE ?", "%user_id: #{user_id}%")
        
        sessions.each do |session|
          session.destroy
          destroyed_count += 1
        end

      when :redis_store, :redis
        # For Redis session store
        if defined?(Redis)
          redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
          
          # Scan for session keys
          cursor = 0
          loop do
            cursor, keys = redis.scan(cursor, match: 'session:*', count: 100)
            
            keys.each do |key|
              session_data = redis.get(key)
              next unless session_data

              # Check if session belongs to user
              if session_data.include?(user_id) || 
                 (session_index && session_data.include?(session_index))
                redis.del(key)
                destroyed_count += 1
              end
            end

            break if cursor == '0'
          end
          
          redis.close
        end

      else
        # For cookie store or other stores
        # Log that we cannot destroy server-side sessions
        log_event(:warn, 'session_store_not_supported', {
          store: Rails.configuration.session_store.to_s
        })
      end

    rescue StandardError => e
      log_event(:error, 'session_destruction_error', {
        user_id: user_id,
        error: e.message
      })
    end

    destroyed_count
  end

  ##
  # Render successful SAML LogoutResponse
  #
  # @param in_response_to [String] ID of the LogoutRequest
  # @return [void]
  #
  def render_successful_response(in_response_to)
    response_id = "_#{SecureRandom.uuid}"
    issue_instant = Time.current.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
    issuer = saml_sp_entity_id
    destination = saml_slo_response_url

    response_xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <samlp:LogoutResponse
        xmlns:samlp="#{SAML_PROTOCOL_NS}"
        xmlns:saml="#{SAML_ASSERTION_NS}"
        ID="#{response_id}"
        InResponseTo="#{in_response_to}"
        Version="2.0"
        IssueInstant="#{issue_instant}"
        Destination="#{destination}">
        <saml:Issuer>#{issuer}</saml:Issuer>
        <samlp:Status>
          <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
        </samlp:Status>
      </samlp:LogoutResponse>
    XML

    # Sign response if required
    if sign_responses?
      response_xml = sign_saml_response(response_xml)
    end

    render xml: response_xml, content_type: 'application/samlxml', status: :ok
  end

  ##
  # Render error response
  #
  # @param status_code [Integer] HTTP status code
  # @param message [String] Error message
  # @return [void]
  #
  def render_error_response(status_code, message)
    log_event(:warn, 'saml_error_response', {
      status_code: status_code,
      message: message
    })

    # For client errors, return simple error
    if status_code >= 400 && status_code < 500
      render plain: message, status: status_code
    else
      # For server errors, still try to return a SAML error response
      render xml: build_error_response(message), 
             content_type: 'application/samlxml', 
             status: status_code
    end
  end

  ##
  # Build SAML error response
  #
  # @param message [String] Error message
  # @return [String] SAML error response XML
  #
  def build_error_response(message)
    response_id = "_#{SecureRandom.uuid}"
    issue_instant = Time.current.utc.strftime('%Y-%m-%dT%H:%M:%SZ')

    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <samlp:LogoutResponse
        xmlns:samlp="#{SAML_PROTOCOL_NS}"
        xmlns:saml="#{SAML_ASSERTION_NS}"
        ID="#{response_id}"
        Version="2.0"
        IssueInstant="#{issue_instant}">
        <samlp:Status>
          <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Responder"/>
          <samlp:StatusMessage>#{CGI.escapeHTML(message)}</samlp:StatusMessage>
        </samlp:Status>
      </samlp:LogoutResponse>
    XML
  end

  ##
  # Sign SAML response with SP private key
  #
  # @param response_xml [String] Unsigned SAML response
  # @return [String] Signed SAML response
  #
  def sign_saml_response(response_xml)
    private_key_pem = ENV.fetch('SAML_SP_PRIVATE_KEY', nil)
    certificate_pem = ENV.fetch('SAML_SP_CERTIFICATE', nil)

    return response_xml if private_key_pem.blank? || certificate_pem.blank?

    begin
      require 'xml_security'

      doc = Nokogiri::XML(response_xml)
      private_key = OpenSSL::PKey::RSA.new(private_key_pem)
      certificate = OpenSSL::X509::Certificate.new(certificate_pem)

      # Sign the document
      signed_doc = XmlSignature.sign(doc, private_key, certificate)
      signed_doc.to_xml

    rescue StandardError => e
      log_event(:error, 'response_signing_error', { error: e.message })
      response_xml
    end
  end

  ##
  # Get SAML SP entity ID
  #
  # @return [String] Service Provider entity ID
  #
  def saml_sp_entity_id
    ENV.fetch('SAML_SP_ENTITY_ID', "https://#{request.host}/shibboleth")
  end

  ##
  # Get SAML SLO response URL
  #
  # @return [String] SLO response destination URL
  #
  def saml_slo_response_url
    ENV.fetch('SAML_IDP_SLO_URL', "https://#{request.host}/saml/logout")
  end

  ##
  # Check if responses should be signed
  #
  # @return [Boolean]
  #
  def sign_responses?
    ENV.fetch('BACKCHANNEL_LOGOUT_BBB_SIGN_RESPONSES', 'true') == 'true'
  end

  ##
  # Structured JSON logging
  #
  # @param level [Symbol] Log level (:debug, :info, :warn, :error)
  # @param event_type [String] Event type identifier
  # @param data [Hash] Event data
  #
  def log_event(level, event_type, data = {})
    return unless logging_enabled?

    log_entry = {
      timestamp: Time.current.utc.iso8601(3),
      level: level.to_s.upcase,
      event: event_type,
      service: 'bigbluebutton-saml-backchannel',
      **data
    }

    message = "[SAML-Backchannel] #{event_type}"
    
    case level
    when :debug
      Rails.logger.debug { "#{message} | #{log_entry.to_json}" } if VERBOSE_LOGGING
    when :info
      Rails.logger.info { "#{message} | #{log_entry.to_json}" }
    when :warn
      Rails.logger.warn { "#{message} | #{log_entry.to_json}" }
    when :error
      Rails.logger.error { "#{message} | #{log_entry.to_json}" }
    end
  end

  ##
  # Check if logging is enabled
  #
  # @return [Boolean]
  #
  def logging_enabled?
    ENV.fetch('BACKCHANNEL_LOGOUT_LOGGING_ENABLED', 'true') == 'true'
  end
end
