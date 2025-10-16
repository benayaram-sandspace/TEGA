# Admin Management Scripts

This directory contains scripts to manage admin users in the Tega system.

## Available Scripts

### 1. `createNewAdmin.js` - Interactive Admin Creation
Creates a new admin with interactive prompts for all details.

**Usage:**
```bash
cd server
node scripts/createNewAdmin.js
```

**Features:**
- Interactive prompts for username, email, password, and gender
- Password confirmation
- Hidden password input (shows asterisks)
- Email validation
- Duplicate checking
- Secure password hashing

### 2. `createAdminQuick.js` - Quick Admin Creation
Creates a new admin using command-line arguments.

**Usage:**
```bash
cd server
node scripts/createAdminQuick.js <username> <email> <password> [gender]
```

**Examples:**
```bash
# Create admin with default gender (Male)
node scripts/createAdminQuick.js john john@example.com mypassword123

# Create admin with specific gender
node scripts/createAdminQuick.js jane jane@example.com mypassword123 Female

# Create admin with Other gender
node scripts/createAdminQuick.js alex alex@example.com mypassword123 Other
```

**Parameters:**
- `username` (required): Unique username for the admin
- `email` (required): Valid email address
- `password` (required): Password (minimum 6 characters)
- `gender` (optional): Male, Female, or Other (defaults to Male)

### 3. `listAdmins.js` - List All Admins
Displays all existing admin users in the system.

**Usage:**
```bash
cd server
node scripts/listAdmins.js
```

**Features:**
- Shows all admin details
- Displays creation and update timestamps
- Shows active/inactive status
- Sorted by creation date (newest first)

### 4. `createAdmin.js` - Default Admin Creation
Creates the default superadmin (hardcoded).

**Usage:**
```bash
cd server
node scripts/createAdmin.js
```

**Default Credentials:**
- Username: `superadmin`
- Email: `admin@tega.com`
- Password: `Abdul@1144`

## Admin Model Fields

Each admin has the following fields:

- **username**: Unique username (required)
- **email**: Unique email address (required)
- **gender**: Male, Female, or Other
- **acceptTerms**: Boolean (defaults to true)
- **isActive**: Boolean (defaults to true)
- **password**: Hashed password (minimum 6 characters)
- **role**: String (defaults to 'admin')
- **createdAt**: Timestamp
- **updatedAt**: Timestamp

## Security Features

- **Password Hashing**: All passwords are hashed using bcrypt with salt rounds of 12
- **Email Validation**: Email format validation
- **Duplicate Prevention**: Checks for existing usernames and emails
- **Input Validation**: Validates all required fields and constraints

## Error Handling

The scripts handle common errors:
- Duplicate username/email
- Invalid email format
- Weak passwords
- Database connection issues
- Missing required fields

## Environment Requirements

Make sure you have:
1. MongoDB running and accessible
2. `.env` file with `MONGODB_URI` configured
3. Node.js and npm installed
4. All dependencies installed (`npm install`)

## Examples

### Create Multiple Admins

```bash
# Create admin for HR department
node scripts/createAdminQuick.js hr_admin hr@tega.com hrpassword123 Female

# Create admin for IT department
node scripts/createAdminQuick.js it_admin it@tega.com itpassword123 Male

# Create admin for Finance department
node scripts/createAdminQuick.js finance_admin finance@tega.com financepass123 Other
```

### Check Existing Admins

```bash
# List all admins
node scripts/listAdmins.js
```

## Troubleshooting

### Common Issues

1. **"Admin already exists"**
   - The username or email is already in use
   - Use a different username or email

2. **"Invalid email format"**
   - Make sure the email follows standard format: `user@domain.com`

3. **"Password must be at least 6 characters"**
   - Use a password with at least 6 characters

4. **"MongoDB connection error"**
   - Check if MongoDB is running
   - Verify `MONGODB_URI` in `.env` file

5. **"Gender must be Male, Female, or Other"**
   - Use exactly one of these values (case-sensitive)

### Getting Help

If you encounter issues:
1. Check the error message for specific details
2. Verify your MongoDB connection
3. Ensure all required fields are provided
4. Check for duplicate usernames/emails

## Best Practices

1. **Use Strong Passwords**: Use passwords with at least 8 characters, including numbers and special characters
2. **Unique Emails**: Each admin should have a unique email address
3. **Descriptive Usernames**: Use usernames that clearly identify the admin's role
4. **Regular Audits**: Use `listAdmins.js` to regularly check existing admins
5. **Secure Storage**: Never share admin credentials in plain text

## Security Notes

- Passwords are never stored in plain text
- All passwords are hashed using industry-standard bcrypt
- Email addresses are stored in lowercase for consistency
- Usernames and emails must be unique across the system
- Admin accounts are active by default but can be deactivated
