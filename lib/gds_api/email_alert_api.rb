require_relative "base"
require_relative "exceptions"

# Adapter for the Email Alert API
#
# @see https://github.com/alphagov/email-alert-api
# @api documented
class GdsApi::EmailAlertApi < GdsApi::Base
  # Get or Post subscriber list
  #
  # @param attributes [Hash] document_type, links, tags used to search existing subscriber lists
  def find_or_create_subscriber_list(attributes)
    find_subscriber_list(attributes)
  rescue GdsApi::HTTPNotFound
    create_subscriber_list(attributes)
  end

  # Get a subscriber list
  #
  # @param attributes [Hash] document_type, links, tags used to search existing subscriber lists
  def find_subscriber_list(attributes)
    tags = attributes["tags"]
    links = attributes["links"]
    document_type = attributes["document_type"]
    email_document_supertype = attributes["email_document_supertype"]
    government_document_supertype = attributes["government_document_supertype"]
    gov_delivery_id = attributes["gov_delivery_id"]
    combine_mode = attributes["combine_mode"]

    if tags && links
      message = "please provide either tags or links (or neither), but not both"
      raise ArgumentError, message
    end

    params = {}
    params[:tags] = tags if tags
    params[:links] = links if links
    params[:document_type] = document_type if document_type
    params[:email_document_supertype] = email_document_supertype if email_document_supertype
    params[:government_document_supertype] = government_document_supertype if government_document_supertype
    params[:gov_delivery_id] = gov_delivery_id if gov_delivery_id
    params[:combine_mode] = combine_mode if combine_mode

    query_string = nested_query_string(params)
    get_json("#{endpoint}/subscriber-lists?" + query_string)
  end

  # Post a subscriber list
  #
  # @param attributes [Hash] document_type, links, tags used to search existing subscriber lists
  def create_subscriber_list(attributes)
    post_json("#{endpoint}/subscriber-lists", attributes)
  end

  # Post a content change
  #
  # @param content_change [Hash] Valid content change attributes
  def create_content_change(content_change, headers = {})
    post_json("#{endpoint}/content-changes", content_change, headers)
  end

  # Post a message
  #
  # @param message [Hash] Valid message attributes
  def create_message(message, headers = {})
    post_json("#{endpoint}/messages", message, headers)
  end

  # Send email
  #
  # @param email_params [Hash] address, subject, body
  def create_email(email_params)
    post_json("#{endpoint}/emails", email_params)
  end

  # Unpublishing alert
  #
  # @param message [Hash] content_id
  #
  # Used by email-alert-service to send a message to email-alert-api
  # when an unpublishing message is put on the Rabbitmq queue by
  # publishing-api
  def send_unpublish_message(message)
    post_json("#{endpoint}/unpublish-messages", message)
  end

  # Get topic matches
  #
  # @param attributes [Hash] tags, links, document_type,
  # email_document_supertype, government_document_supertype
  #
  # @return [Hash] topics, enabled, disabled
  def topic_matches(attributes)
    query_string = nested_query_string(attributes)
    get_json("#{endpoint}/topic-matches.json?#{query_string}")
  end

  # Unsubscribe subscriber from subscription
  #
  # @param [string] Subscription uuid
  #
  # @return [nil]
  def unsubscribe(uuid)
    post_json("#{endpoint}/unsubscribe/#{uri_encode(uuid)}")
  end

  # Unsubscribe subscriber from everything
  #
  # @param [integer] Subscriber id
  #
  # @return [nil]
  def unsubscribe_subscriber(id)
    delete_json("#{endpoint}/subscribers/#{uri_encode(id)}")
  end

  # Subscribe
  #
  # @return [Hash] subscription_id
  def subscribe(subscriber_list_id:, address:, frequency: "immediately")
    post_json(
      "#{endpoint}/subscriptions",
      subscriber_list_id: subscriber_list_id,
      address: address,
      frequency: frequency,
    )
  end

  # Get a Subscriber List
  #
  # @return [Hash] subscriber_list: {
  #  id
  #  title
  #  gov_delivery_id
  #  created_at
  #  updated_at
  #  document_type
  #  tags
  #  links
  #  email_document_supertype
  #  government_document_supertype
  #  subscriber_count
  # }
  def get_subscriber_list(slug:)
    get_json("#{endpoint}/subscriber-lists/#{uri_encode(slug)}")
  end

  # Get a Subscription
  #
  # @return [Hash] subscription: {
  #  id
  #  subscriber_list
  #  subscriber
  #  created_at
  #  updated_at
  #  ended_at
  #  ended_reason
  #  frequency
  #  source
  # }
  def get_subscription(id)
    get_json("#{endpoint}/subscriptions/#{uri_encode(id)}")
  end

  # Get the latest Subscription that has the same subscriber_list
  # and email as the Subscription associated with the `id` passed.
  # This may or may not be the same Subscription.
  #
  # @return [Hash] subscription: {
  #  id
  #  subscriber_list
  #  subscriber
  #  created_at
  #  updated_at
  #  ended_at
  #  ended_reason
  #  frequency
  #  source
  # }
  def get_latest_matching_subscription(id)
    get_json("#{endpoint}/subscriptions/#{uri_encode(id)}/latest")
  end

  # Get Subscriptions for a Subscriber
  #
  # @param [integer] Subscriber id
  # @param [string] Subscription order - title, created_at
  #
  # @return [Hash] subscriber, subscriptions
  def get_subscriptions(id:, order: nil)
    if order
      get_json("#{endpoint}/subscribers/#{uri_encode(id)}/subscriptions?order=#{uri_encode(order)}")
    else
      get_json("#{endpoint}/subscribers/#{uri_encode(id)}/subscriptions")
    end
  end

  # Patch a Subscriber
  #
  # @param [integer] Subscriber id
  # @param [string] Subscriber new_address
  #
  # @return [Hash] subscriber
  def change_subscriber(id:, new_address:)
    patch_json(
      "#{endpoint}/subscribers/#{uri_encode(id)}",
      new_address: new_address,
    )
  end

  # Patch a Subscription
  #
  # @param [string] Subscription id
  # @param [string] Subscription frequency
  #
  # @return [Hash] subscription
  def change_subscription(id:, frequency:)
    patch_json(
      "#{endpoint}/subscriptions/#{uri_encode(id)}",
      frequency: frequency,
    )
  end

  # Verify a subscriber has control of a provided email
  #
  # @param [string]       address       Address to send verification email to
  # @param [string]       destination   Path on GOV.UK that subscriber will be emailed
  # @param [string, nil]  redirect      Path on GOV.UK to be encoded into the token for redirecting
  #
  # @return [Hash]  subscriber
  #
  def send_subscriber_verification_email(address:, destination:, redirect: nil)
    post_json(
      "#{endpoint}/subscribers/auth-token",
      address: address,
      destination: destination,
      redirect: redirect,
    )
  end

  # Verify a subscriber intends to be added to a subscription
  #
  # @param [string]       address       Address to send verification email to
  # @param [string]       frequency     How often the subscriber wishes to be notified of new items
  # @param [string]       topic_id      The slugs/ID for the topic being subscribed to
  #
  # return [Hash]  subscription
  #
  def send_subscription_verification_email(address:, frequency:, topic_id:)
    post_json(
      "#{endpoint}/subscriptions/auth-token",
      address: address,
      frequency: frequency,
      topic_id: topic_id,
    )
  end

  # Fetch an OIDC auth URI which can be used to verify a user has an account with a validated email
  #
  # @param [string]  destination  Path on GOV.UK that subscriber will be sent to after logging in
  #
  # @return  [Hash]  nonce and auth URI
  def get_oidc_url(destination:)
    query_string = nested_query_string(destination: destination)
    get_json("#{endpoint}/subscribers/oidc?" + query_string)
  end

  # Validate an OIDC response and return the associated user, if their email is validated
  #
  # @param [string]  code         Code provided by the OIDC identity provider
  # @param [string]  nonce        Nonce returned by the previous call to get_oidc_url
  # @param [string]  destination  Destination passed to the previous call to get_oidc_url
  #
  # @return  [Hash]  user_id and subscriber
  def verify_oidc_response(code:, nonce:, destination:)
    post_json(
      "#{endpoint}/subscribers/oidc",
      code: code,
      nonce: nonce,
      destination: destination,
    )
  end

private

  def nested_query_string(params)
    Rack::Utils.build_nested_query(params)
  end
end
