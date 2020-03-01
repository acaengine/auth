# frozen_string_literal: true

class Authentication
  include NoBrainer::Document
  include AuthTimestamps

  table_config name: 'authentication'

  field :uid,      type: String
  field :provider, type: String
  field :user_id,  type: String, index: true

  def self.by_user(user)
    Authentication.where(user_id: user.id).to_a
  end

  def self.for_user(user_id)
    Authentication.where(user_id: user_id).to_a
  end

  def self.from_omniauth(auth)
    self.find("auth-#{auth['provider']}-#{auth['uid']}")
  end

  def self.create_with_omniauth(auth, user_id)
    authen = Authentication.new
    authen.provider = auth['provider']
    authen.uid = auth['uid']
    authen.user_id = user_id
    authen.save!
    authen
  end

  # the before_signup block gives installations the ability to reject
  # signups or modify the user record before any user/auth records are
  # stored. if the block returns false, user signup is rejected.
  def self.before_signup(&block)
    @before_signup = block
  end

  def self.before_signup_block
    @before_signup || (->(user, provider, auth) { true })
  end

  # the after_login block gives installations the ability to perform post
  # login functions, such as syncing user permissions from a remote server
  def self.after_login(&block)
    @after_login = block
  end

  def self.after_login_block
    @after_login || (->(user, provider, auth) { nil })
  end

  protected

  before_create :generate_id
  def generate_id
    self.id = "auth-#{self.provider}-#{self.uid}"
  end
end
