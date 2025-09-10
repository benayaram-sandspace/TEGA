# TEGA Login Routing Guide

## 🎯 **Role-Based Dashboard Routing**

The TEGA app now properly routes users to their appropriate dashboards based on their login credentials and role.

### **📋 Login Credentials & Routing**

| User Type | Email | Password | Dashboard Destination |
|-----------|-------|----------|----------------------|
| **Admin** | `admin@tega.com` | `admin123` | **Admin Dashboard** |
| **College Principal** | `principal@college.com` | `principal123` | **College Dashboard** |
| **Student** | `user@tega.com` | `user123` | **Student Dashboard** |

### **🔄 Login Flow**

1. **User enters credentials** on the login page
2. **System validates** the credentials
3. **Role is determined** from the user data
4. **User is redirected** to the appropriate dashboard:

#### **Admin Login Flow:**
```
Login Page → Admin Dashboard
```
- **Features**: Full system administration
- **Access**: All colleges, students, reports, settings

#### **College Principal Login Flow:**
```
Login Page → College Dashboard
```
- **Features**: College-specific management
- **Access**: Student analytics, career tracking, reports for their college

#### **Student Login Flow:**
```
Login Page → Student Dashboard
```
- **Features**: Personal learning and career development
- **Access**: Quizzes, progress tracking, resume building

### **🚀 Splash Screen Auto-Routing**

If a user is already logged in (valid session), the splash screen automatically routes them to their appropriate dashboard:

- **Admin** → Admin Dashboard
- **College Principal** → College Dashboard  
- **Student** → Student Dashboard
- **No Session** → Login Page

### **⚙️ Technical Implementation**

#### **Login Page Logic:**
```dart
if (_authService.isAdmin) {
  // Navigate to Admin Dashboard
} else if (_authService.hasRole(UserRole.moderator)) {
  // Navigate to College Dashboard
} else if (_authService.hasRole(UserRole.user)) {
  // Navigate to Student Dashboard
} else {
  // Navigate to Home Page (fallback)
}
```

#### **Splash Screen Logic:**
```dart
if (_authService.isSessionValid()) {
  // Auto-route based on role
} else {
  // Go to Login Page
}
```

### **🎨 Dashboard Features**

#### **Admin Dashboard:**
- System-wide analytics
- College management
- User management
- Global reports
- System settings

#### **College Dashboard:**
- Student management
- Career progress tracking
- Learning analytics
- Resume & interview monitoring
- College-specific reports
- Settings & support

#### **Student Dashboard:**
- Personal learning path
- Quiz and assessment
- Progress tracking
- Resume building
- Career guidance

### **✅ Testing Instructions**

1. **Test Admin Login:**
   - Email: `admin@tega.com`
   - Password: `admin123`
   - Expected: Redirected to Admin Dashboard

2. **Test College Principal Login:**
   - Email: `principal@college.com`
   - Password: `principal123`
   - Expected: Redirected to College Dashboard

3. **Test Student Login:**
   - Email: `user@tega.com`
   - Password: `user123`
   - Expected: Redirected to Student Dashboard

4. **Test Auto-Routing:**
   - Login with any credentials
   - Close and reopen the app
   - Expected: Automatically redirected to appropriate dashboard

### **🔧 Error Handling**

- **Invalid Credentials**: Shows error message, stays on login page
- **No College Data**: College principals redirected to login page
- **Session Expired**: All users redirected to login page
- **Unknown Role**: Users redirected to home page

### **📱 User Experience**

- **Seamless Navigation**: Users go directly to their relevant dashboard
- **Persistent Sessions**: Logged-in users skip login on app restart
- **Role-Appropriate Access**: Each user sees only relevant features
- **Consistent Branding**: All dashboards maintain TEGA design language

---

**Last Updated**: December 2024  
**Version**: 1.0.0
