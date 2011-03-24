class OauthToken < ActiveRecord::Base
  belongs_to :client_application
  belongs_to :user
  validates_uniqueness_of :token
  validates_presence_of :client_application, :token
  before_validation :generate_keys, :on => :create
  before_validation :init_scope, :on => :create
  before_create :set_expiry_time
  serialize :scope
  
  ALLOWED_SCOPES = [:offline_access, :read_projects, :write_projects]
  
  def scope=(value)
    if value.is_a? String
      self[:scope] = value.split(' ').map(&:to_sym)
    else
      self[:scope] = value ? value.map(&:to_sym) : []
    end
  end

  def invalidated?
    invalidated_at != nil || (valid_to != nil && valid_to < Time.now)
  end

  def invalidate!
    update_attribute(:invalidated_at, Time.now)
  end

  def authorized?
    authorized_at != nil && !invalidated?
  end

  def to_query
    "oauth_token=#{token}&oauth_token_secret=#{secret}"
  end
  
  def expires_in
    self.valid_to ? (self.valid_to - Time.now).to_i : nil
  end
  
  def default_expiry_time
    Time.now + 30.minutes
  end
  
  def set_expiry_time
    self.valid_to ||= default_expiry_time
  end

  protected

  def generate_keys
    self.token = OAuth::Helper.generate_key(40)[0,40]
    self.secret = OAuth::Helper.generate_key(40)[0,40]
  end
  
  def init_scope
    return if self.class == Oauth2Verifier
    self.scope ||= []
    self.scope = self.scope & ALLOWED_SCOPES
  end
end
