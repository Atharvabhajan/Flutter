# Quick Start Guide

## 🚀 Get Running in 5 Minutes

### Step 1: Install Dependencies (1 min)

```bash
cd Silent-Emergency-Shield-Backend
npm install
```

### Step 2: Setup Environment (1 min)

```bash
cp .env.example .env
```

Edit `.env` and make sure you have:

```
MONGODB_URI=mongodb://localhost:27017/silent-emergency-shield
JWT_SECRET=your-secret-key-here
JWT_EXPIRE=7d
PORT=5000
NODE_ENV=development
```

### Step 3: Start MongoDB (1 min)

```bash
# Windows - if installed locally
mongod

# Or use MongoDB Atlas (cloud)
# Update MONGODB_URI in .env with your connection string
```

### Step 4: Start Server (1 min)

```bash
npm run dev
```

You should see:

```
✓ Server running on http://localhost:5000
✓ Environment: development
✓ Health check: http://localhost:5000/health
✓ MongoDB Connected: localhost
```

### Step 5: Test API (1 min)

```bash
# Test health check
curl http://localhost:5000/health

# Register user
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"John","email":"john@example.com","password":"pass123","phone":"9876543210"}'
```

---

## 📁 Project Structure at a Glance

```
├── config/database.js         ← DB connection
├── controllers/               ← Business logic
│   ├── authController.js      (register, login)
│   └── contactController.js   (CRUD contacts)
├── models/                    ← Database schemas
│   ├── User.js
│   └── EmergencyContact.js
├── routes/                    ← API endpoints
│   ├── authRoutes.js
│   └── contactRoutes.js
├── middlewares/               ← JWT verification
│   └── authMiddleware.js
├── services/                  ← Utilities
│   └── authService.js
├── server.js                  ← Main app
└── package.json              ← Dependencies
```

---

## 🔑 API Endpoints Quick Reference

### Auth (No token needed)

```
POST   /api/auth/register      → Create account
POST   /api/auth/login         → Get JWT token
```

### Contacts (Need token)

```
POST   /api/contacts/add       → Add contact
GET    /api/contacts           → List contacts
PUT    /api/contacts/:id       → Update contact
DELETE /api/contacts/:id       → Delete contact
```

### Server

```
GET    /health                 → Server status
```

---

## 🧪 Quick Test Workflow

### 1. Register

```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Alice",
    "email": "alice@test.com",
    "password": "pass123",
    "phone": "1234567890"
  }'
```

**Save the token from response**

### 2. Add Contact

```bash
TOKEN="your-token-here"
curl -X POST http://localhost:5000/api/contacts/add \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Mom",
    "phone": "1234567891",
    "relation": "Family",
    "priority": 1
  }'
```

### 3. Get Contacts

```bash
curl -X GET http://localhost:5000/api/contacts \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🔧 Common Commands

| Task         | Command                             |
| ------------ | ----------------------------------- |
| Install deps | `npm install`                       |
| Start dev    | `npm run dev`                       |
| Start prod   | `npm start`                         |
| Check health | `curl http://localhost:5000/health` |

---

## 📊 Key Features

✅ **User Authentication**

- Registration with validation
- Secure login with JWT tokens
- Password hashing with bcryptjs

✅ **Emergency Contacts Management**

- Add/Edit/Delete contacts
- Priority-based sorting
- User-specific data (no cross-access)

✅ **Clean Architecture**

- Separated concerns (controllers, models, services)
- Middleware for cross-cutting concerns
- Reusable route patterns

✅ **Security**

- JWT token authentication
- Password hashing
- Input validation
- Protected routes

✅ **Production Ready**

- Environment configuration
- Error handling
- Logging
- Scalable structure

---

## 🐛 Troubleshooting

| Problem                  | Solution                                           |
| ------------------------ | -------------------------------------------------- |
| MongoDB connection error | Make sure MongoDB is running or update MONGODB_URI |
| Port 5000 in use         | Change PORT in .env                                |
| Module not found         | Run `npm install`                                  |
| Token expired            | Login again to get new token                       |
| 10-digit phone required  | Use format like "1234567890"                       |

---

## 📚 Documentation Files

| File                | Purpose                                          |
| ------------------- | ------------------------------------------------ |
| README.md           | Complete documentation                           |
| API-TESTING.md      | API testing guide with curl examples             |
| WORKFLOW-EXAMPLE.md | Complete workflow with request/response examples |
| ARCHITECTURE.md     | System design and architecture diagrams          |
| QUICK-START.md      | This file - get started fast                     |

---

## 🚀 Next Steps

1. **Modify Models**: Add more fields to User or EmergencyContact as needed
2. **Add Validation**: Use express-validator for stricter validation
3. **Add Logging**: Integrate winston or morgan for better logging
4. **Add Testing**: Setup Jest/Mocha for unit tests
5. **Deploy**: Push to Heroku, AWS, or your hosting platform

---

## 💡 Pro Tips

- Use Postman/Thunder Client for easier API testing
- Keep JWT_SECRET secure in production
- Use MongoDB Atlas for cloud deployment
- Add rate limiting before going live
- Monitor logs in production
- Use HTTPS in production
- Implement refresh tokens for better security

---

## 📞 Support Resources

- Express.js Docs: https://expressjs.com
- MongoDB Docs: https://docs.mongodb.com
- Mongoose Docs: https://mongoosejs.com
- JWT Docs: https://jwt.io
- bcryptjs: https://github.com/dcodeIO/bcrypt.js

---

**You're all set! Happy coding! 🎉**

For detailed API documentation, see [README.md](README.md)
For complete workflow examples, see [WORKFLOW-EXAMPLE.md](WORKFLOW-EXAMPLE.md)
For architecture overview, see [ARCHITECTURE.md](ARCHITECTURE.md)
