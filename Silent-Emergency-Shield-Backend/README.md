# Silent Emergency Shield - Backend

A clean and scalable Express.js backend for managing emergency contacts and user authentication.

## 📁 Folder Structure

```
Silent-Emergency-Shield-Backend/
├── config/
│   └── database.js              # MongoDB connection configuration
├── controllers/
│   ├── authController.js        # Authentication logic (register, login)
│   └── contactController.js     # Emergency contact management logic
├── middlewares/
│   └── authMiddleware.js        # JWT authentication middleware
├── models/
│   ├── User.js                  # User schema with password hashing
│   └── EmergencyContact.js      # Emergency contact schema
├── routes/
│   ├── authRoutes.js            # Authentication routes
│   └── contactRoutes.js         # Contact management routes
├── services/
│   └── authService.js           # JWT token generation service
├── server.js                     # Main server file
├── package.json                 # Project dependencies
├── .env.example                 # Environment variables template
└── .gitignore                   # Git ignore file
```

## 🚀 Setup Instructions

### 1. Prerequisites

- Node.js (v14 or higher)
- MongoDB (running locally or MongoDB Atlas connection string)

### 2. Install Dependencies

```bash
npm install
```

### 3. Environment Configuration

Create a `.env` file based on `.env.example`:

```bash
cp .env.example .env
```

Update `.env` with your configuration:

```
MONGODB_URI=mongodb://localhost:27017/silent-emergency-shield
JWT_SECRET=your-super-secret-jwt-key-change-this
JWT_EXPIRE=7d
PORT=5000
NODE_ENV=development
```

### 4. Run the Server

**Development mode** (with auto-reload):

```bash
npm run dev
```

**Production mode**:

```bash
npm start
```

The server will start on `http://localhost:5000`

## 📚 API Endpoints

### Authentication Endpoints

#### Register User

```
POST /api/auth/register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "phone": "9876543210"
}

Response: 201 Created
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "userId": "65abc123...",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "9876543210"
  },
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

#### Login User

```
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}

Response: 200 OK
{
  "success": true,
  "message": "Logged in successfully",
  "data": {
    "userId": "65abc123...",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "9876543210"
  },
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

### Emergency Contact Endpoints (Protected Routes)

All contact endpoints require JWT token in Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

#### Add Emergency Contact

```
POST /api/contacts/add
Content-Type: application/json
Authorization: Bearer <token>

{
  "name": "Mom",
  "phone": "9876543211",
  "relation": "Family",
  "email": "mom@example.com",
  "priority": 1
}

Response: 201 Created
{
  "success": true,
  "message": "Emergency contact added successfully",
  "data": {
    "_id": "65abc456...",
    "userId": "65abc123...",
    "name": "Mom",
    "phone": "9876543211",
    "relation": "Family",
    "email": "mom@example.com",
    "priority": 1,
    "createdAt": "2024-01-15T10:30:00.000Z"
  }
}
```

#### Get All Emergency Contacts

```
GET /api/contacts
Authorization: Bearer <token>

Response: 200 OK
{
  "success": true,
  "message": "Contacts retrieved successfully",
  "count": 2,
  "data": [
    {
      "_id": "65abc456...",
      "userId": "65abc123...",
      "name": "Mom",
      "phone": "9876543211",
      "relation": "Family",
      "priority": 1,
      "createdAt": "2024-01-15T10:30:00.000Z"
    },
    {
      "_id": "65abc789...",
      "userId": "65abc123...",
      "name": "Doctor",
      "phone": "9876543212",
      "relation": "Doctor",
      "priority": 2,
      "createdAt": "2024-01-15T11:00:00.000Z"
    }
  ]
}
```

#### Update Emergency Contact

```
PUT /api/contacts/:id
Content-Type: application/json
Authorization: Bearer <token>

{
  "name": "Mom Updated",
  "phone": "9876543211",
  "priority": 1
}

Response: 200 OK
{
  "success": true,
  "message": "Contact updated successfully",
  "data": { ... }
}
```

#### Delete Emergency Contact

```
DELETE /api/contacts/:id
Authorization: Bearer <token>

Response: 200 OK
{
  "success": true,
  "message": "Contact deleted successfully"
}
```

#### Health Check

```
GET /health

Response: 200 OK
{
  "success": true,
  "message": "Server is running",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

## 🔐 Security Features

- **Password Hashing**: Uses bcryptjs for secure password storage
- **JWT Authentication**: Secure token-based authentication
- **Input Validation**: Server-side validation for all inputs
- **Protected Routes**: Contact endpoints require valid JWT token
- **Authorization**: Users can only access their own contacts

## 📋 Data Models

### User Model

```
{
  name: String (required)
  email: String (required, unique, validated)
  password: String (required, hashed)
  phone: String (required, 10 digits)
  createdAt: Date
  updatedAt: Date
}
```

### Emergency Contact Model

```
{
  userId: ObjectId (ref: User, required)
  name: String (required)
  phone: String (required, 10 digits)
  relation: String (Family, Friend, Doctor, Other)
  email: String (optional, validated)
  priority: Number (1-10, default: 1)
  createdAt: Date
  updatedAt: Date
}
```

## 🛠️ Development

### Install Development Dependencies

```bash
npm install
```

### Run with Nodemon (Auto-reload)

```bash
npm run dev
```

## 📦 Dependencies

- **express**: Web framework
- **mongoose**: MongoDB ODM
- **bcryptjs**: Password hashing
- **jsonwebtoken**: JWT authentication
- **dotenv**: Environment variable management
- **nodemon**: Development auto-reload (dev dependency)

## 🌐 Testing the API

Use tools like:

- **Postman**: GUI-based API testing
- **Thunder Client**: VS Code extension
- **curl**: Command-line testing

Example curl command:

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"password123"}'
```

## 🤝 Best Practices Implemented

- ✅ Modular folder structure (controllers, routes, models, services, middlewares)
- ✅ Clean and readable code
- ✅ Proper error handling
- ✅ Input validation
- ✅ JWT-based authentication
- ✅ Password hashing with bcrypt
- ✅ Environment-based configuration
- ✅ Scalable architecture
- ✅ Consistent response format
- ✅ API documentation

## 📝 Notes

- Phone numbers must be 10 digits
- JWT tokens expire after 7 days (configurable in .env)
- All contact endpoints are protected and require authentication
- Contacts are sorted by priority (lowest number = highest priority)

## 🚀 Ready to Deploy

The backend is production-ready and can be deployed to:

- Heroku
- AWS (EC2, Lambda)
- DigitalOcean
- Azure
- Google Cloud

Remember to:

1. Set strong JWT_SECRET in production
2. Use MongoDB Atlas for cloud database
3. Set NODE_ENV=production
4. Use environment-specific configurations

---

**Version**: 1.0.0  
**Last Updated**: January 2024  
**Status**: Production Ready ✅
