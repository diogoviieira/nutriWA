# NutriWA – Appointment Requests Challenge

Rails application that implements the appointment request workflow defined in the Nutrium take-home challenge.

---

## 📌 Features Implemented

**Guest Flow:**
- Browse nutritionists with search by name, service, or location
- Location-based sorting using approximate distance calculation
- View nutritionist profiles with services and pricing
- Submit appointment requests for specific time slots
- Email notifications when requests are accepted, rejected, or cancelled

**Nutritionist Flow:**
- View pending appointment requests in a React-powered panel
- Accept or reject requests with immediate UI feedback
- Automatic handling of business rules on accept/reject

**Business Rules (enforced at model level):**
- Each guest can only have one pending request at a time (new request auto-cancels previous pending)
- Accepting a request cancels all other pending requests for the same slot
- Rejected/cancelled guests receive email notifications
- Appointment slots must be in the future

---

## 🧠 Technical Decisions & Trade-offs

**Rails 7 + PostgreSQL:**  
Standard stack for Ruby challenges. PostgreSQL enables advanced queries (ILIKE, CASE expressions for distance sorting). No need for microservices or additional complexity for this scope.

**No authentication:**  
Challenge focused on appointment logic, not auth flows. In production, nutritionists would need login (Devise or similar) and guests could remain unauthenticated or use magic links.

**Enum instead of state machine:**  
`AppointmentRequest` has 4 states (pending/accepted/rejected/cancelled). Using Rails enum with custom `accept!`/`reject!` methods keeps it simple and testable. A gem like `aasm` would add overhead without clear benefit here.

**Euclidean distance for location sorting:**  
Location sorting uses approximate coordinates for Portuguese cities. This keeps the implementation simple while satisfying the challenge requirements; real geocoding was intentionally left out of scope.

**React for nutritionist panel only:**  
ERB for public pages (simple, server-rendered). React for the requests panel where nutritionists need instant feedback on accept/reject. Embedded as a single component, no React Router needed.

**Minitest over RSpec:**  
Rails default. Tests are straightforward (validations, business rules, emails). RSpec syntax wouldn't add value here.

**Business logic in models:**  
`accept!` and `reject!` methods live in `AppointmentRequest` model. Controllers stay thin, logic is reusable and easy to test.

---

## 🗂 Data Model

**Nutritionist**  
`has_many :services, :appointment_requests`  
Represents a nutritionist with name, location, optional avatar URL.

**Service**  
`belongs_to :nutritionist`  
Services offered (e.g., "Sports Nutrition", "Weight Management") with price.

**AppointmentRequest**  
`belongs_to :nutritionist`  
Guest name, email, requested datetime, and status.

**Status enum:**  
- `pending` (0) – waiting for nutritionist response
- `accepted` (1) – nutritionist confirmed slot
- `rejected` (2) – nutritionist declined
- `cancelled` (3) – auto-cancelled due to conflict or newer guest request

**Key validations:**
- Email format validation
- Future-only appointment times
- Unique partial index to prevent double-booking same slot

---

## 🚀 Setup & Run Locally

**Prerequisites:**
- Ruby 3.2.3
- Node.js 18+
- PostgreSQL 15+

**Steps:**

```bash
# Install dependencies
bundle install
npm install

# Create database, run migrations, seed sample data
bin/rails db:setup

# Build JavaScript bundle
npm run build

# Start Rails server
bin/rails server
```

**Open in browser:**  
`http://localhost:3000`

**View emails in development:**  
`http://localhost:3000/letter_opener`

**Sample data:**  
6 nutritionists across Portuguese cities (Braga, Porto, Lisboa, Coimbra), each with 2-3 services and sample appointment requests.

This setup assumes a local PostgreSQL instance running with default settings.

---

## 🧪 Tests & CI

**Run tests:**

```bash
# All tests
bin/rails test

# Specific file
bin/rails test test/models/appointment_request_test.rb
```

**What's tested:**
- Model validations (email format, future dates)
- Business rules: one pending request per guest, conflict cancellation on accept
- Mailer deliveries (accepted/rejected/cancelled emails)
- Email content assertions

**CI Pipeline (GitHub Actions):**
- Security scan (Brakeman)
- Code style enforcement (RuboCop)
- Test suite execution (Minitest + PostgreSQL)

**Current stats:**  
9 tests, 39 assertions, 0 failures

---

## 📂 Project Structure

```
app/
├── controllers/
│   ├── nutritionists_controller.rb         # Public pages (index, show)
│   ├── appointment_requests_controller.rb  # Guest booking form
│   └── api/appointment_requests_controller.rb  # React panel backend
├── models/
│   ├── nutritionist.rb       # Search scope, distance calculation
│   ├── appointment_request.rb  # Business logic (accept!, reject!)
│   └── service.rb
├── mailers/
│   └── appointment_request_mailer.rb  # Accepted/rejected/cancelled emails
├── javascript/
│   ├── application.js
│   └── components/RequestsPanel.jsx  # React component for nutritionists
└── views/
    ├── nutritionists/        # ERB templates
    └── appointment_request_mailer/  # Email templates (HTML + text)
```

---

**Sample data:**  
6 nutritionists across Portuguese cities. Profile images use pravatar.cc placeholders.

---

## ⚠️ Known Limitations & Production Considerations

### **Authentication & Authorization** (Critical)
No login system implemented. Nutritionists access panels via direct URL (`/nutritionists/:id/requests`). Anyone with a nutritionist ID can accept/reject requests.

**Production requirement:** Implement authentication (Devise, JWT) with proper authorization checks. See [SECURITY.md](SECURITY.md) for details.

### **API Security**
CSRF protection disabled for API endpoints (`protect_from_forgery with: :null_session`). Acceptable for this demo but requires token-based auth in production.

### **Rate Limiting**
No rate limiting on request submissions. Could be abused for spam/DoS.

**Production requirement:** Add rack-attack or similar rate limiting middleware.

### **Background Jobs**
Emails use `deliver_later` with default ActiveJob adapter (async in-process). Works for development but requires Redis/Sidekiq for production reliability.

### **Distance Calculation**
Euclidean approximation with hardcoded Portuguese city coordinates. Sufficient for this scope but real applications should use PostGIS or geocoding APIs.

### **Real-time Updates**
Nutritionist panel requires manual refresh to see new requests. Consider ActionCable or polling for production.

For comprehensive security documentation, see [SECURITY.md](SECURITY.md).

---