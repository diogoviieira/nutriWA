# Security Considerations

## Current Security Status

This application was built as a take-home challenge focused on appointment request logic and data integrity. Several security features were intentionally deferred for production implementation.

## Known Security Limitations

### 1. **No Authentication/Authorization** (Critical)

**Issue:** The nutritionist panel API endpoints (`/api/nutritionists/:id/appointment_requests`) have no authentication. Anyone who knows a nutritionist's ID can:
- View all pending requests
- Accept or reject requests on behalf of that nutritionist

**Impact:** Complete unauthorized access to nutritionist panel functionality.

**Production Fix Required:**
```ruby
# Add authentication gem (e.g., Devise)
gem 'devise'

# In API controller:
class Api::AppointmentRequestsController < ApplicationController
  before_action :authenticate_nutritionist!
  before_action :verify_nutritionist_ownership

  private

  def verify_nutritionist_ownership
    @nutritionist = current_nutritionist
    head :forbidden unless @nutritionist.id == params[:nutritionist_id].to_i
  end
end
```

### 2. **CSRF Protection Disabled for API**

**Issue:** `protect_from_forgery with: :null_session` disables CSRF checks for API endpoints.

**Impact:** Cross-site request forgery attacks possible if session-based auth is added later.

**Production Fix:** Use token-based authentication (JWT, OAuth) instead of session cookies for API endpoints.

### 3. **Email Address Exposure**

**Issue:** API responses include full guest email addresses in plaintext JSON.

**Impact:** Email harvesting if API access is compromised.

**Mitigation:**
```ruby
# Mask email in API responses
def request_json(request)
  {
    id: request.id,
    guest_name: request.guest_name,
    guest_email_preview: mask_email(request.guest_email),
    # ... other fields
  }
end

def mask_email(email)
  email.gsub(/(.{2})(.*)(@.*)/, '\1***\3')
end
```

### 4. **Rate Limiting**

**Issue:** No rate limiting on appointment request submissions or API calls.

**Impact:** Potential for spam/DoS attacks.

**Production Fix:**
```ruby
# Add rack-attack gem
gem 'rack-attack'

# In config/initializers/rack_attack.rb
Rack::Attack.throttle('appointment_requests/ip', limit: 5, period: 1.hour) do |req|
  req.ip if req.path.include?('/appointment_requests') && req.post?
end
```

### 5. **SQL Injection in Distance Calculation**

**Issue:** String interpolation used in `CASE WHEN` SQL for distance sorting.

**Current Status:** Low risk because values come from hardcoded `CITY_COORDINATES` hash, not user input.

**Best Practice Fix:**
```ruby
# Use connection.quote for all SQL string interpolation
distance_sql = CITY_COORDINATES.map do |city, coords|
  "WHEN LOWER(nutritionists.location) = #{connection.quote(city)} THEN ..."
end
```

## Implemented Security Features

### ✅ Data Integrity Protections

1. **Partial Unique Indexes:** Prevent race conditions for:
   - One pending request per guest email
   - One accepted appointment per nutritionist/slot

2. **Transaction Safety:** Critical operations wrapped in database transactions with pessimistic locking.

3. **Email Format Validation:** Prevents invalid email addresses.

4. **Future-Only Appointments:** Validates requested times are in the future.

### ✅ Input Validation

1. **Strong Parameters:** Mass assignment protection via `permit` whitelists.
2. **Email Format Validation:** Using `URI::MailTo::EMAIL_REGEXP`.
3. **Presence Validations:** All required fields validated.

### ✅ Error Handling

1. **Custom Exceptions:** `InvalidTransitionError` for state machine violations.
2. **Graceful Error Responses:** API returns appropriate HTTP status codes.

## Production Deployment Checklist

Before deploying to production:

- [ ] Implement authentication system (Devise, JWT, or similar)
- [ ] Add authorization checks to all API endpoints
- [ ] Enable rate limiting (rack-attack or similar)
- [ ] Set up SSL/TLS for all traffic
- [ ] Configure Content Security Policy headers
- [ ] Implement CORS restrictions for API
- [ ] Add logging and monitoring for suspicious activity
- [ ] Set up email verification for guest appointments
- [ ] Configure proper session security (secure cookies, timeout)
- [ ] Run security audit tools (Brakeman, bundler-audit)
- [ ] Set up secret management (Rails credentials, ENV vars)
- [ ] Configure database connection encryption
- [ ] Implement backup and disaster recovery

## Reporting Security Issues

For this take-home challenge, security issues are documented here for discussion during the interview. In production, security issues should be reported via a responsible disclosure process.
