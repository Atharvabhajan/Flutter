# API Testing Commands

## Quick Start Guide

### 1. Start MongoDB

```bash
# Make sure MongoDB is running on localhost:27017
# Or update MONGODB_URI in .env for MongoDB Atlas
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Create .env file

```bash
cp .env.example .env
# Update values if needed
```

### 4. Start Server

```bash
npm run dev
```

---

## Testing Endpoints with curl

### Register New User

```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "phone": "9876543210"
  }'
```

**Expected Response:**

```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "userId": "...",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "9876543210"
  },
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

---

### Login User

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

**Note:** Save the token from response for next requests

---

### Add Emergency Contact (Protected)

```bash
curl -X POST http://localhost:5000/api/contacts/add \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <YOUR_TOKEN>" \
  -d '{
    "name": "Mom",
    "phone": "9876543211",
    "relation": "Family",
    "email": "mom@example.com",
    "priority": 1
  }'
```

---

### Get All Emergency Contacts (Protected)

```bash
curl -X GET http://localhost:5000/api/contacts \
  -H "Authorization: Bearer <YOUR_TOKEN>"
```

---

### Update Emergency Contact (Protected)

```bash
curl -X PUT http://localhost:5000/api/contacts/<CONTACT_ID> \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <YOUR_TOKEN>" \
  -d '{
    "name": "Mom Updated",
    "priority": 1
  }'
```

---

### Delete Emergency Contact (Protected)

```bash
curl -X DELETE http://localhost:5000/api/contacts/<CONTACT_ID> \
  -H "Authorization: Bearer <YOUR_TOKEN>"
```

---

### Health Check

```bash
curl http://localhost:5000/health
```

---

## Postman Collection Example

**1. Environment Variables (set in Postman):**

```
base_url: http://localhost:5000
token: <token_from_login>
```

**2. Request Examples:**

| Method | Endpoint           | Auth | Body                                   |
| ------ | ------------------ | ---- | -------------------------------------- |
| POST   | /api/auth/register | No   | name, email, password, phone           |
| POST   | /api/auth/login    | No   | email, password                        |
| POST   | /api/contacts/add  | YES  | name, phone, relation, email, priority |
| GET    | /api/contacts      | YES  | -                                      |
| PUT    | /api/contacts/:id  | YES  | name, phone, relation, email, priority |
| DELETE | /api/contacts/:id  | YES  | -                                      |

---

## Common Issues & Solutions

### Issue: MongoDB Connection Error

**Solution:**

- Ensure MongoDB is running locally
- Or update MONGODB_URI in .env with MongoDB Atlas connection string

### Issue: JWT Token Expired

**Solution:**

- Login again to get a new token
- Update JWT_EXPIRE in .env if needed

### Issue: Phone Validation Error

**Solution:**

- Phone must be exactly 10 digits
- Format: 9876543210 (no spaces or special characters)

### Issue: Email Already Registered

**Solution:**

- Use a different email for registration
- Or login with existing credentials

### Issue: 401 Unauthorized on Protected Routes

**Solution:**

- Ensure token is included in Authorization header
- Format: `Authorization: Bearer <token>`
- Check if token is valid and not expired

---

## Rate Limiting (Optional Enhancement)

To add rate limiting, install `express-rate-limit`:

```bash
npm install express-rate-limit
```

Then add to server.js:

```javascript
const rateLimit = require("express-rate-limit");

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
});

app.use(limiter);
```

---

## CORS (Optional Enhancement)

To enable CORS for frontend integration:

```bash
npm install cors
```

Then add to server.js:

```javascript
const cors = require("cors");
app.use(cors());
```

---

## Validation Enhancements

Already installed: `express-validator`

Usage example (already implemented):

```javascript
const { body, validationResult } = require("express-validator");

router.post(
  "/register",
  [body("email").isEmail(), body("password").isLength({ min: 6 })],
  register,
);
```

---

## Production Checklist

- [ ] Update JWT_SECRET to a strong random string
- [ ] Change NODE_ENV to 'production'
- [ ] Use MongoDB Atlas instead of local MongoDB
- [ ] Enable HTTPS/SSL
- [ ] Set up environment-specific .env files
- [ ] Add rate limiting
- [ ] Add logging and monitoring
- [ ] Add request validation middleware
- [ ] Enable CORS for your frontend domain
- [ ] Set up CI/CD pipeline
- [ ] Add comprehensive error logging
- [ ] Implement refresh token mechanism

---

**Happy Coding! 🚀**
