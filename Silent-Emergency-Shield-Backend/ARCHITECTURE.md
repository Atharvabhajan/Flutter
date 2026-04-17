# Architecture & Project Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENT (Mobile App / Web)                │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTP/REST
                         │
┌────────────────────────▼────────────────────────────────────┐
│                   EXPRESS.JS SERVER                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              ROUTE LAYER                            │  │
│  │  ┌─────────────┐          ┌──────────────────┐     │  │
│  │  │/api/auth    │          │/api/contacts     │     │  │
│  │  └─────────────┘          └──────────────────┘     │  │
│  └──────────────────────────────────────────────────────┘  │
│                         │                                   │
│  ┌──────────────────────▼──────────────────────────────┐  │
│  │           MIDDLEWARE LAYER                         │  │
│  │  ┌─────────────────────────────────────────────┐   │  │
│  │  │ Authentication Middleware (JWT Validation) │   │  │
│  │  └─────────────────────────────────────────────┘   │  │
│  └──────────────────────┬──────────────────────────────┘  │
│                         │                                   │
│  ┌──────────────────────▼──────────────────────────────┐  │
│  │         CONTROLLER LAYER                           │  │
│  │  ┌─────────────┐          ┌──────────────────┐    │  │
│  │  │authController           │contactController │    │  │
│  │  └─────────────┘          └──────────────────┘    │  │
│  └──────────────────────┬──────────────────────────────┘  │
│                         │                                   │
│  ┌──────────────────────▼──────────────────────────────┐  │
│  │          SERVICE LAYER                             │  │
│  │  ┌─────────────────────────────────────────────┐   │  │
│  │  │ authService (JWT Token Generation)         │   │  │
│  │  │ Password Hashing (bcryptjs)                │   │  │
│  │  └─────────────────────────────────────────────┘   │  │
│  └──────────────────────┬──────────────────────────────┘  │
│                         │                                   │
│  ┌──────────────────────▼──────────────────────────────┐  │
│  │            MODEL LAYER (MONGOOSE)                  │  │
│  │  ┌──────────────┐        ┌──────────────────────┐ │  │
│  │  │ User Model   │        │EmergencyContact Model│ │  │
│  │  └──────────────┘        └──────────────────────┘ │  │
│  └──────────────────────┬──────────────────────────────┘  │
└─────────────────────────┼────────────────────────────────┘
                          │
                          │ Mongoose ODM
                          │
┌─────────────────────────▼────────────────────────────────────┐
│                    MONGODB DATABASE                          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Collections:                                         │   │
│  │  • users                                            │   │
│  │  • emergencycontacts                               │   │
│  │                                                     │   │
│  │ Indexes:                                           │   │
│  │  • users.email (unique)                          │   │
│  │  • emergencycontacts.userId                      │   │
│  │  • emergencycontacts.priority                    │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Folder Structure with Descriptions

```
Silent-Emergency-Shield-Backend/
│
├── config/
│   └── database.js
│       └─ Database connection configuration
│         Handles MongoDB connection with Mongoose
│
├── controllers/
│   ├── authController.js
│   │   ├─ register() → Create new user account
│   │   └─ login() → Authenticate user and return JWT
│   │
│   └── contactController.js
│       ├─ addContact() → Create new emergency contact
│       ├─ getContacts() → Fetch user's all contacts
│       ├─ updateContact() → Modify existing contact
│       └─ deleteContact() → Remove contact
│
├── models/
│   ├── User.js
│   │   └─ Fields: name, email, password (hashed), phone, timestamps
│   │
│   └── EmergencyContact.js
│       └─ Fields: userId, name, phone, relation, email, priority, timestamps
│
├── routes/
│   ├── authRoutes.js
│   │   ├─ POST /api/auth/register
│   │   └─ POST /api/auth/login
│   │
│   └── contactRoutes.js
│       ├─ POST /api/contacts/add
│       ├─ GET /api/contacts
│       ├─ PUT /api/contacts/:id
│       └─ DELETE /api/contacts/:id
│
├── middlewares/
│   └── authMiddleware.js
│       └─ Validates JWT token for protected routes
│
├── services/
│   └── authService.js
│       └─ generateToken() → Creates JWT
│
├── server.js
│   └─ Main Express app entry point
│      Sets up routes, middleware, error handlers
│
├── package.json
│   └─ Dependencies and scripts
│
├── .env.example
│   └─ Environment variables template
│
├── .gitignore
│   └─ Git ignore patterns
│
└── Documentation/
    ├── README.md
    ├── API-TESTING.md
    └── WORKFLOW-EXAMPLE.md
```

---

## Data Flow Diagram

### Registration Flow

```
Client
  │
  └─→ POST /api/auth/register
        │
        ├─→ authController.register()
        │     │
        │     ├─→ Validate input (name, email, password, phone)
        │     ├─→ Check if email exists
        │     ├─→ Create User model
        │     │     │
        │     │     └─→ Pre-save hook: Hash password with bcrypt
        │     │
        │     └─→ Generate JWT token
        │
        ├─→ Response: User data + JWT token
        │
        └─← Client (store token for future requests)
```

### Login Flow

```
Client
  │
  └─→ POST /api/auth/login
        │
        ├─→ authController.login()
        │     │
        │     ├─→ Validate input (email, password)
        │     ├─→ Find user in database
        │     ├─→ Compare password using bcrypt
        │     │
        │     └─→ Generate JWT token
        │
        ├─→ Response: User data + JWT token
        │
        └─← Client (store token)
```

### Protected Route Flow (Add Contact)

```
Client
  │ Authorization: Bearer <JWT_TOKEN>
  │
  └─→ POST /api/contacts/add
        │
        ├─→ authMiddleware
        │     │
        │     ├─→ Extract token from header
        │     ├─→ Verify JWT signature
        │     ├─→ Decode token → Extract userId
        │     │
        │     └─→ Attach userId to request object
        │
        ├─→ contactController.addContact()
        │     │
        │     ├─→ Validate input
        │     ├─→ Create EmergencyContact with userId
        │     │
        │     └─→ Save to database
        │
        ├─→ Response: Contact data
        │
        └─← Client
```

### Retrieve Contacts Flow

```
Client
  │ Authorization: Bearer <JWT_TOKEN>
  │
  └─→ GET /api/contacts
        │
        ├─→ authMiddleware → Verify JWT → Extract userId
        │
        ├─→ contactController.getContacts()
        │     │
        │     ├─→ Query database for contacts where userId matches
        │     ├─→ Sort by priority (ascending)
        │     │
        │     └─→ Return array of contacts
        │
        ├─→ Response: [Contact1, Contact2, Contact3...] sorted by priority
        │
        └─← Client
```

---

## Request/Response Flow with Error Handling

```
┌─────────────────────────────────┐
│      Incoming Request           │
└────────┬────────────────────────┘
         │
         ▼
┌──────────────────────────────────┐      ┌──────────────────┐
│  Express Middleware              │─────→│ JSON Parser      │
│                                  │      └──────────────────┘
└────────┬─────────────────────────┘
         │
         ▼
┌──────────────────────────────────┐      ┌──────────────────┐
│  JWT Middleware (if protected)   │─────→│ Token Validation │
│                                  │      └──────────────────┘
└────────┬─────────────────────────┘           │
         │                                     ├─→ Valid? Continue
         │                                     └─→ Invalid? 401 Error
         ▼
┌──────────────────────────────────┐
│  Route Handler / Controller      │
├──────────────────────────────────┤
│  ├─→ Input Validation            │
│  ├─→ Business Logic              │
│  ├─→ Database Operations         │
│  └─→ Response Formatting         │
└────────┬─────────────────────────┘
         │
         ├─→ Success → 200/201 OK
         │
         └─→ Error   → 400/401/403/404/500 Error
                       with error message
         │
         ▼
┌──────────────────────────────────┐
│      JSON Response               │
└─────────────────────────────────┘
```

---

## Database Schema

### User Collection

```javascript
{
  _id: ObjectId,
  name: String,                    // Required, max 50 chars
  email: String,                   // Required, unique, validated
  password: String,                // Required, hashed with bcrypt
  phone: String,                   // Required, 10 digits
  createdAt: Date,                 // Auto-generated
  updatedAt: Date,                 // Auto-generated
  __v: Number                      // Mongoose version key
}
```

### Emergency Contact Collection

```javascript
{
  _id: ObjectId,
  userId: ObjectId,                // Reference to User
  name: String,                    // Required, max 50 chars
  phone: String,                   // Required, 10 digits
  relation: String,                // Enum: Family|Friend|Doctor|Other
  email: String,                   // Optional, validated if provided
  priority: Number,                // 1-10, default: 1
  createdAt: Date,                 // Auto-generated
  updatedAt: Date,                 // Auto-generated
  __v: Number                      // Mongoose version key
}
```

---

## Authentication Flow (JWT)

```
Registration/Login
    │
    ├─→ Server generates JWT:
    │     JWT = base64(header.payload.signature)
    │     Payload: { userId, iat, exp }
    │
    ├─→ Server sends JWT to client
    │
    └─→ Client stores JWT (localStorage/sessionStorage)

Protected Route Request
    │
    ├─→ Client sends JWT in Authorization header:
    │     Authorization: Bearer <JWT>
    │
    ├─→ Server middleware:
    │     1. Extract token from header
    │     2. Verify signature using JWT_SECRET
    │     3. Decode payload
    │     4. If valid: Extract userId
    │     5. If invalid: Return 401 Unauthorized
    │
    └─→ Controller receives userId in request object
```

---

## Security Layers

```
┌─────────────────────────────────────────┐
│        Input Validation Layer           │
│  - Schema validation (Mongoose)         │
│  - Email format validation              │
│  - Phone format validation (10 digits)  │
│  - Required fields check                │
└─────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│     Authentication Layer (JWT)          │
│  - Token signature verification         │
│  - Token expiration check (7 days)      │
│  - Token extraction from header         │
└─────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│     Authorization Layer                 │
│  - User can only access own resources   │
│  - Contact ownership verification       │
│  - Role-based access (can be extended)  │
└─────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│     Data Protection Layer               │
│  - Password hashing (bcryptjs)          │
│  - Unique email constraint              │
│  - Indexed queries for performance      │
└─────────────────────────────────────────┘
```

---

## Scalability Considerations

### Current Features

- ✅ Modular structure (easy to extend)
- ✅ Service layer (business logic separation)
- ✅ Middleware pattern (reusable)
- ✅ Database indexing (for performance)

### Future Enhancements

- Rate limiting (express-rate-limit)
- Request validation (express-validator)
- Logging system (winston, morgan)
- Caching (Redis)
- Message queues (Bull, RabbitMQ)
- Refresh tokens (token rotation)
- API versioning (/api/v1/...)
- Role-based access control (RBAC)
- Audit logging
- Two-factor authentication (2FA)

---

## Technology Stack

| Layer       | Technology | Purpose                    |
| ----------- | ---------- | -------------------------- |
| Runtime     | Node.js    | JavaScript runtime         |
| Framework   | Express.js | Web framework              |
| Database    | MongoDB    | NoSQL database             |
| ODM         | Mongoose   | MongoDB object modeling    |
| Auth        | JWT        | Token-based authentication |
| Security    | bcryptjs   | Password hashing           |
| Environment | dotenv     | Configuration management   |

---

**Architecture designed for clarity, maintainability, and scalability.**
