# Tega Auth Starter - Backend Server

A comprehensive Node.js/Express backend for the Tega Auth Starter application with payment processing, course management, and user authentication.

## 🚀 Features

- **User Authentication**: JWT-based authentication for students, principals, and admins
- **Payment Processing**: Integration with Razorpay for secure payments
- **Course Management**: Complete course catalog with pricing and enrollment
- **Exam Access Control**: Payment-based access to exams and assessments
- **Admin Dashboard**: Comprehensive admin panel for managing users and payments
- **Email Notifications**: Password reset and payment confirmation emails
- **Database Seeding**: Automated database population with sample data

## 📋 Prerequisites

- Node.js (v14 or higher)
- MongoDB (v4.4 or higher)
- npm or yarn package manager

## 🛠️ Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd tega-auth-starter/server
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment Configuration**
   Create a `.env` file in the server directory:
   ```env
   # Server Configuration
   PORT=5000
   NODE_ENV=development

   # MongoDB Configuration
   MONGODB_URI=mongodb://localhost:27017/tega-auth-starter

   # JWT Configuration
   JWT_SECRET=your-super-secret-jwt-key-here
   JWT_EXPIRE=7d

   # Email Configuration
   EMAIL_HOST=smtp.gmail.com
   EMAIL_PORT=587
   EMAIL_USER=your-email@gmail.com
   EMAIL_PASS=your-app-password

   # Razorpay Configuration
   RAZORPAY_KEY_ID=rzp_test_your_razorpay_key_id
   RAZORPAY_KEY_SECRET=your_razorpay_key_secret

   # Client URL
   CLIENT_URL=http://localhost:3000
   ```

4. **Database Setup**
   ```bash
   # Start MongoDB (if not running)
   mongod

   # Seed the database with initial data
   npm run seed
   ```

5. **Start the server**
   ```bash
   # Development mode
   npm run dev

   # Production mode
   npm start
   ```

## 📊 Database Models

### Payment Model
- Stores payment information and transaction details
- Supports multiple payment methods (card, UPI, net banking)
- Integrates with Razorpay for secure payments
- Tracks payment status and refund information

### Course Model
- Manages course information and pricing
- Supports course categories and difficulty levels
- Includes syllabus, requirements, and learning outcomes
- Tracks enrollment counts and ratings

### User Models
- **Student**: Regular users who can enroll in courses
- **Principal**: Educational institution administrators
- **Admin**: System administrators with full access

## 🔌 API Endpoints

### Authentication Routes (`/api/auth`)
- `POST /register` - User registration
- `POST /login` - User login
- `POST /forgot-password` - Password reset request
- `POST /reset-password` - Password reset
- `POST /logout` - User logout

### Payment Routes (`/api/payments`)
- `GET /courses` - Get all available courses
- `GET /pricing` - Get course pricing information
- `POST /create-order` - Create Razorpay payment order
- `POST /process-dummy` - Process dummy payment (development)
- `POST /verify` - Verify Razorpay payment
- `GET /history` - Get user payment history
- `GET /access/:courseId` - Check course access
- `GET /paid-courses` - Get user's paid courses
- `POST /refund` - Process payment refund
- `GET /stats` - Get payment statistics (admin)

### Admin Routes (`/api/admin`)
- `GET /dashboard` - Admin dashboard data
- `GET /students` - Get all students
- `GET /principals` - Get all principals
- `POST /create-student` - Create new student
- `POST /create-principal` - Create new principal
- `PUT /edit-user/:id` - Edit user information
- `DELETE /delete-user/:id` - Delete user

### Student Routes (`/api/student`)
- `GET /profile` - Get student profile
- `PUT /profile` - Update student profile
- `GET /dashboard` - Student dashboard data

### Principal Routes (`/api/principal`)
- `GET /profile` - Get principal profile
- `PUT /profile` - Update principal profile
- `GET /dashboard` - Principal dashboard data

## 💳 Payment Integration

### Razorpay Setup
1. Create a Razorpay account at [razorpay.com](https://razorpay.com)
2. Get your API keys from the Razorpay dashboard
3. Add the keys to your `.env` file:
   ```env
   RAZORPAY_KEY_ID=rzp_test_your_key_id
   RAZORPAY_KEY_SECRET=your_key_secret
   ```

### Payment Flow
1. **Course Selection**: User selects a course
2. **Order Creation**: Backend creates Razorpay order
3. **Payment Processing**: User completes payment via Razorpay
4. **Payment Verification**: Backend verifies payment signature
5. **Access Granting**: User gains access to course and exams

### Dummy Payment (Development)
For development and testing, use the dummy payment endpoint:
```bash
POST /api/payments/process-dummy
{
  "courseId": "java-programming",
  "paymentMethod": "card",
  "paymentDetails": {
    "cardNumber": "1234567890123456",
    "cardHolder": "John Doe"
  }
}
```

## 🗄️ Database Seeding

Run the database seeder to populate initial data:
```bash
npm run seed
```

This will create:
- 5 courses with detailed information
- Sample pricing (all courses at ₹799)
- Course categories and difficulty levels
- Instructor information

## 🔒 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Password Hashing**: bcrypt for password security
- **Payment Verification**: Cryptographic signature verification
- **Input Validation**: Comprehensive request validation
- **CORS Protection**: Cross-origin resource sharing configuration
- **Rate Limiting**: Protection against brute force attacks

## 📈 Monitoring & Analytics

### Payment Statistics
- Total payments and revenue
- Payment status distribution
- Course enrollment analytics
- User payment history

### Admin Dashboard
- User management
- Payment monitoring
- Course analytics
- System health metrics

## 🚀 Deployment

### Environment Variables
Ensure all required environment variables are set in production:
- Database connection string
- JWT secret key
- Razorpay API keys
- Email configuration
- Client URL for CORS

### Production Considerations
- Use HTTPS in production
- Set up proper logging
- Configure database backups
- Set up monitoring and alerts
- Use environment-specific configurations

## 🧪 Testing

Run tests (when implemented):
```bash
npm test
```

## 📝 API Documentation

For detailed API documentation, see the individual route files or use tools like:
- Postman collection
- Swagger/OpenAPI documentation
- API testing tools

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the ISC License.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

## 🔄 Updates

Stay updated with the latest changes:
- Monitor the repository for updates
- Check the changelog
- Follow the development roadmap
