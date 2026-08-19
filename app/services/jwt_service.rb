class JwtService
  ALGORITHM = "HS256"
  ISSUER="dlq_saas"
  AUDIENCE="dlq_saas_api"
  EXPIRATION=15.minutes

  def self.encode(user_id:)
    issued_at = Time.current.to_i

    payload = {
      sub: user_id.to_s,
      iss: ISSUER,
      aud: AUDIENCE,
      iat: issued_at,
      exp: issued_at + EXPIRATION.to_i
    }

    JWT.encode(payload, secret, ALGORITHM)
  end


  def self.decode(token)
    options = {
      algorithm: ALGORITHM,
      required_claims: %w[sub iss aud iat exp],
      iss: ISSUER,
      verify_iss: true,
      aud: AUDIENCE,
      verify_aud: true
    }

    JWT.decode(token, secret, true, options).first
  end

  def self.secret
    Rails.application.credentials.jwt_secret || "super-secret-banana"
  end

  private_class_method :secret
end
