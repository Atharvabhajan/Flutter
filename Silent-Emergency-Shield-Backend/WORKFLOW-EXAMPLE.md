# Complete Workflow Example

This file demonstrates a complete workflow of the Silent Emergency Shield API.

## Scenario: User Registration, Login, and Contact Management

### Step 1: Register a New User

**Endpoint:** `POST /api/auth/register`

**Request:**

```json
{
  "name": "Alice Johnson",
  "email": "alice@example.com",
  "password": "SecurePass123",
  "phone": "9876543210"
}
```

**Response (201 Created):**

```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "userId": "65a1b2c3d4e5f6g7h8i9j0k1",
    "name": "Alice Johnson",
    "email": "alice@example.com",
    "phone": "9876543210"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2NWExYjJjM2Q0ZTVmNmc3aDhpOWowazEiLCJpYXQiOjE3MDUnEzAxMCwiZXhwIjoxNzA1NzU4NjEwfQ.9jR..."
}
```

**Save the token for subsequent requests!**

---

### Step 2: Login (If Already Registered)

**Endpoint:** `POST /api/auth/login`

**Request:**

```json
{
  "email": "alice@example.com",
  "password": "SecurePass123"
}
```

**Response (200 OK):**

```json
{
  "success": true,
  "message": "Logged in successfully",
  "data": {
    "userId": "65a1b2c3d4e5f6g7h8i9j0k1",
    "name": "Alice Johnson",
    "email": "alice@example.com",
    "phone": "9876543210"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2NWExYjJjM2Q0ZTVmNmc3aDhpOWowazEiLCJpYXQiOjE3MDU3NDA2MjAsImV4cCI6MTcwNjM0NTQyMH0.LmK..."
}
```

---

### Step 3: Add First Emergency Contact

**Endpoint:** `POST /api/contacts/add`

**Headers:**

```
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Request:**

```json
{
  "name": "Mom - Sarah Johnson",
  "phone": "9876543211",
  "relation": "Family",
  "email": "mom@example.com",
  "priority": 1
}
```

**Response (201 Created):**

```json
{
  "success": true,
  "message": "Emergency contact added successfully",
  "data": {
    "_id": "65a1b2c3d4e5f6g7h8i9j0k2",
    "userId": "65a1b2c3d4e5f6g7h8i9j0k1",
    "name": "Mom - Sarah Johnson",
    "phone": "9876543211",
    "relation": "Family",
    "email": "mom@example.com",
    "priority": 1,
    "createdAt": "2024-01-15T10:30:00.000Z",
    "updatedAt": "2024-01-15T10:30:00.000Z"
  }
}
```

---

### Step 4: Add Second Emergency Contact

**Endpoint:** `POST /api/contacts/add`

**Headers:**

```
Authorization: Bearer <YOUR_TOKEN>
```

**Request:**

```json
{
  "name": "Dr. Michael Smith",
  "phone": "9876543212",
  "relation": "Doctor",
  "email": "drsmith@hospital.com",
  "priority": 2
}
```

**Response:**

```json
{
  "success": true,
  "message": "Emergency contact added successfully",
  "data": {
    "_id": "65a1b2c3d4e5f6g7h8i9j0k3",
    "userId": "65a1b2c3d4e5f6g7h8i9j0k1",
    "name": "Dr. Michael Smith",
    "phone": "9876543212",
    "relation": "Doctor",
    "email": "drsmith@hospital.com",
    "priority": 2,
    "createdAt": "2024-01-15T10:35:00.000Z",
    "updatedAt": "2024-01-15T10:35:00.000Z"
  }
}
```

---

### Step 5: Add Third Emergency Contact

**Endpoint:** `POST /api/contacts/add`

**Request:**

```json
{
  "name": "Best Friend - Tom Brown",
  "phone": "9876543213",
  "relation": "Friend",
  "priority": 3
}
```

**Response:**

```json
{
  "success": true,
  "message": "Emergency contact added successfully",
  "data": {
    "_id": "65a1b2c3d4e5f6g7h8i9j0k4",
    "userId": "65a1b2c3d4e5f6g7h8i9j0k1",
    "name": "Best Friend - Tom Brown",
    "phone": "9876543213",
    "relation": "Friend",
    "email": null,
    "priority": 3,
    "createdAt": "2024-01-15T10:40:00.000Z",
    "updatedAt": "2024-01-15T10:40:00.000Z"
  }
}
```

---

### Step 6: Retrieve All Emergency Contacts

**Endpoint:** `GET /api/contacts`

**Headers:**

```
Authorization: Bearer <YOUR_TOKEN>
```

**Response (200 OK):**

```json
{
  "success": true,
  "message": "Contacts retrieved successfully",
  "count": 3,
  "data": [
    {
      "_id": "65a1b2c3d4e5f6g7h8i9j0k2",
      "userId": "65a1b2c3d4e5f6g7h8i9j0k1",
      "name": "Mom - Sarah Johnson",
      "phone": "9876543211",
      "relation": "Family",
      "email": "mom@example.com",
      "priority": 1,
      "createdAt": "2024-01-15T10:30:00.000Z",
      "updatedAt": "2024-01-15T10:30:00.000Z"
    },
    {
      "_id": "65a1b2c3d4e5f6g7h8i9j0k3",
      "userId": "65a1b2c3d4e5f6g7h8i9j0k1",
      "name": "Dr. Michael Smith",
      "phone": "9876543212",
      "relation": "Doctor",
      "email": "drsmith@hospital.com",
      "priority": 2,
      "createdAt": "2024-01-15T10:35:00.000Z",
      "updatedAt": "2024-01-15T10:35:00.000Z"
    },
    {
      "_id": "65a1b2c3d4e5f6g7h8i9j0k4",
      "userId": "65a1b2c3d4e5f6g7h8i9j0k1",
      "name": "Best Friend - Tom Brown",
      "phone": "9876543213",
      "relation": "Friend",
      "email": null,
      "priority": 3,
      "createdAt": "2024-01-15T10:40:00.000Z",
      "updatedAt": "2024-01-15T10:40:00.000Z"
    }
  ]
}
```

---

### Step 7: Update Contact Priority

**Endpoint:** `PUT /api/contacts/65a1b2c3d4e5f6g7h8i9j0k3`

**Request:**

```json
{
  "priority": 1,
  "name": "Dr. Michael Smith - High Priority"
}
```

**Response (200 OK):**

```json
{
  "success": true,
  "message": "Contact updated successfully",
  "data": {
    "_id": "65a1b2c3d4e5f6g7h8i9j0k3",
    "userId": "65a1b2c3d4e5f6g7h8i9j0k1",
    "name": "Dr. Michael Smith - High Priority",
    "phone": "9876543212",
    "relation": "Doctor",
    "email": "drsmith@hospital.com",
    "priority": 1,
    "createdAt": "2024-01-15T10:35:00.000Z",
    "updatedAt": "2024-01-15T11:00:00.000Z"
  }
}
```

---

### Step 8: Retrieve Updated Contacts (Sorted by Priority)

**Endpoint:** `GET /api/contacts`

**Response:**

```json
{
  "success": true,
  "message": "Contacts retrieved successfully",
  "count": 3,
  "data": [
    {
      "_id": "65a1b2c3d4e5f6g7h8i9j0k2",
      "priority": 1,
      "name": "Mom - Sarah Johnson",
      ...
    },
    {
      "_id": "65a1b2c3d4e5f6g7h8i9j0k3",
      "priority": 1,
      "name": "Dr. Michael Smith - High Priority",
      ...
    },
    {
      "_id": "65a1b2c3d4e5f6g7h8i9j0k4",
      "priority": 3,
      "name": "Best Friend - Tom Brown",
      ...
    }
  ]
}
```

---

### Step 9: Delete a Contact

**Endpoint:** `DELETE /api/contacts/65a1b2c3d4e5f6g7h8i9j0k4`

**Response (200 OK):**

```json
{
  "success": true,
  "message": "Contact deleted successfully"
}
```

---

### Step 10: Verify Contact Deletion

**Endpoint:** `GET /api/contacts`

**Response:**

```json
{
  "success": true,
  "message": "Contacts retrieved successfully",
  "count": 2,
  "data": [
    {
      "_id": "65a1b2c3d4e5f6g7h8i9j0k2",
      "name": "Mom - Sarah Johnson",
      ...
    },
    {
      "_id": "65a1b2c3d4e5f6g7h8i9j0k3",
      "name": "Dr. Michael Smith - High Priority",
      ...
    }
  ]
}
```

---

## Error Scenarios

### Invalid Credentials During Login

**Request:**

```json
{
  "email": "alice@example.com",
  "password": "wrongpassword"
}
```

**Response (401 Unauthorized):**

```json
{
  "success": false,
  "message": "Invalid email or password"
}
```

---

### Invalid Token

**Request:** GET /api/contacts
**Header:** `Authorization: Bearer invalidtoken123`

**Response (401 Unauthorized):**

```json
{
  "success": false,
  "message": "Invalid or expired token. Please login again."
}
```

---

### Missing Required Fields

**Request:**

```json
{
  "name": "John Doe",
  "email": "john@example.com"
}
```

**Response (400 Bad Request):**

```json
{
  "success": false,
  "message": "Please provide all required fields"
}
```

---

### Invalid Phone Number

**Request:**

```json
{
  "name": "Emergency Contact",
  "phone": "123",
  "relation": "Family"
}
```

**Response (400 Bad Request):**

```json
{
  "success": false,
  "message": "Phone number must be 10 digits"
}
```

---

### Contact Not Found

**Request:** `DELETE /api/contacts/nonexistentid`

**Response (404 Not Found):**

```json
{
  "success": false,
  "message": "Contact not found"
}
```

---

### Unauthorized Access to Contact

**Scenario:** User A tries to delete User B's contact

**Request:** `DELETE /api/contacts/<UserB_ContactID>`

**Response (403 Forbidden):**

```json
{
  "success": false,
  "message": "Not authorized to delete this contact"
}
```

---

## Testing Flow Summary

```
1. Register → Get Token
2. Login → Get Token (alternative)
3. Add Contact 1 (Priority 1)
4. Add Contact 2 (Priority 2)
5. Add Contact 3 (Priority 3)
6. Get All Contacts → View sorted by priority
7. Update Contact → Change priority/details
8. Get All Contacts → Verify update
9. Delete Contact → Remove one
10. Get All Contacts → Verify deletion
```

---

## API Status Codes

| Code | Meaning      | Example                            |
| ---- | ------------ | ---------------------------------- |
| 200  | OK           | Login, Update, Get                 |
| 201  | Created      | Register, Add Contact              |
| 400  | Bad Request  | Missing fields, validation error   |
| 401  | Unauthorized | Invalid credentials, invalid token |
| 403  | Forbidden    | Unauthorized access to resource    |
| 404  | Not Found    | Contact doesn't exist              |
| 409  | Conflict     | Email already registered           |
| 500  | Server Error | Database error                     |

---

## Tips for Testing

1. **Use Postman Collections:** Organize requests in folders
2. **Use Environment Variables:** Store token and base_url
3. **Test Error Cases:** Intentionally send invalid data
4. **Check Response Status Codes:** Verify correct HTTP status
5. **Validate Response Structure:** Ensure all fields are present
6. **Test Protected Routes:** Always include valid Authorization header
7. **Test Data Persistence:** Verify data survives server restart

---

**Happy Testing! 🎉**
