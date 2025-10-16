// Email template utilities for TEGA platform - Minimal with Official Logo
import path from 'path';
import fs from 'fs';

// Minimal email template with official TEGA logo (small size to avoid "View entire message")
const getBaseEmailTemplate = (title, content, showLogo = true) => {
  // Multiple fallback options for logo to ensure it displays in all environments
  const clientUrl = process.env.CLIENT_URL || 'http://localhost:3000';
  const logoUrl = showLogo ? `${clientUrl}/maillogo.jpg` : '';
  
  return `
    <html>
    <body style="font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f8f9fa;">
      <div style="max-width: 500px; margin: 20px auto; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); overflow: hidden;">
        <div style="background: #1e3a8a; color: white; padding: 20px; text-align: center;">
          ${logoUrl ? `<img src="${logoUrl}" alt="TEGA Logo" style="width: 80px; height: 80px; margin-bottom: 0; display: block; margin-left: auto; margin-right: auto; max-width: 80px; height: auto;" onerror="this.style.display='none';">` : ''}
        </div>
        
        <div style="padding: 25px;">
          ${content}
        </div>
        
        <div style="text-align: center; margin-top: 20px; padding: 15px; border-top: 1px solid #e9ecef; background-color: #f8f9fa;">
          <p style="color: #6c757d; font-size: 12px; margin: 0;">© 2024 TEGA - Empowering Education</p>
        </div>
      </div>
    </body>
    </html>
  `;
};

// Professional Login notification template
export const getLoginNotificationTemplate = (userName, loginTime, userAgent, ipAddress) => {
  const content = `
    <h2 style="color: #1e3a8a; font-size: 24px; margin: 0 0 15px 0; font-weight: 600;">Welcome back, ${userName}!</h2>
    
    <div style="background-color: #f8f9fa; padding: 15px; border-radius: 6px; margin: 15px 0;">
      <p style="color: #495057; font-size: 14px; margin: 0 0 8px 0; font-weight: 500;">Login Details:</p>
      <p style="color: #6c757d; font-size: 13px; margin: 0 0 5px 0;">📅 Time: ${loginTime}</p>
      <p style="color: #6c757d; font-size: 13px; margin: 0 0 5px 0;">💻 Device: ${userAgent.length > 25 ? userAgent.substring(0, 25) + '...' : userAgent}</p>
      <p style="color: #6c757d; font-size: 13px; margin: 0;">🌐 IP: ${ipAddress}</p>
    </div>
    
    <div style="text-align: center; margin: 20px 0;">
      <a href="${process.env.CLIENT_URL || 'http://localhost:3000'}/dashboard" style="background: #1e3a8a; color: white; padding: 12px 24px; text-decoration: none; font-size: 14px; border-radius: 6px; display: inline-block; font-weight: 500;">Go to Dashboard</a>
    </div>
    
    <p style="color: #dc3545; font-size: 12px; margin: 15px 0 0 0; text-align: center;">⚠️ If this wasn't you, please reset your password immediately.</p>
  `;
  
  return getBaseEmailTemplate('Login Successful - TEGA Platform', content);
};

// Professional Password reset OTP email template
export const getPasswordResetTemplate = (userName, otp) => {
  const content = `
    <h2 style="color: #1e3a8a; font-size: 24px; margin: 0 0 15px 0; font-weight: 600;">Password Reset Request</h2>
    
    <p style="color: #495057; font-size: 16px; margin: 0 0 15px 0;">Hello <strong>${userName}</strong>,</p>
    <p style="color: #6c757d; font-size: 14px; margin: 0 0 20px 0;">You requested to reset your password. Use the code below:</p>
    
    <div style="text-align: center; margin: 20px 0; padding: 20px; border: 2px solid #1e3a8a; border-radius: 8px; background-color: #f8f9fa;">
      <div style="font-size: 32px; font-weight: bold; color: #1e3a8a; margin: 10px 0; letter-spacing: 4px; font-family: 'Courier New', monospace;">${otp}</div>
      <p style="color: #dc3545; margin: 10px 0 0 0; font-size: 12px; font-weight: 500;">⏰ Expires in 10 minutes</p>
    </div>
    
    <p style="color: #6c757d; font-size: 13px; margin: 15px 0 0 0; text-align: center;">If you didn't request this password reset, please ignore this email.</p>
  `;
  
  return getBaseEmailTemplate('Password Reset - TEGA', content);
};

// Professional Registration OTP template
export const getRegistrationOTPTemplate = (userName, otp) => {
  const content = `
    <h2 style="color: #1e3a8a; font-size: 24px; margin: 0 0 15px 0; font-weight: 600;">Welcome to TEGA, ${userName}!</h2>
    
    <p style="color: #495057; font-size: 16px; margin: 0 0 15px 0;">Complete your registration with the verification code below:</p>
    
    <div style="text-align: center; margin: 20px 0; padding: 20px; border: 2px solid #1e3a8a; border-radius: 8px; background-color: #f8f9fa;">
      <div style="font-size: 28px; font-weight: bold; color: #1e3a8a; margin: 10px 0; letter-spacing: 3px; font-family: 'Courier New', monospace;">${otp}</div>
      <p style="color: #dc3545; margin: 10px 0 0 0; font-size: 12px; font-weight: 500;">⏰ Expires in 5 minutes</p>
    </div>
    
    <div style="background-color: #e7f3ff; padding: 15px; border-radius: 6px; margin: 15px 0;">
      <p style="color: #1e3a8a; font-size: 14px; margin: 0 0 8px 0; font-weight: 500;">🎓 What's next after verification:</p>
      <ul style="color: #495057; font-size: 13px; margin: 0; padding-left: 20px;">
        <li>Access training courses and certifications</li>
        <li>Apply for internships and job opportunities</li>
        <li>Build your professional resume</li>
        <li>Track your learning progress</li>
      </ul>
    </div>
    
    <p style="color: #6c757d; font-size: 13px; margin: 15px 0 0 0; text-align: center;">If you didn't create this account, please ignore this email.</p>
  `;
  
  return getBaseEmailTemplate('Complete Your Registration - TEGA', content);
};

// Professional Welcome template
export const getWelcomeTemplate = (userName) => {
  const content = `
    <h2 style="color: #1e3a8a; font-size: 24px; margin: 0 0 15px 0; font-weight: 600;">Welcome to TEGA, ${userName}!</h2>
    
    <p style="color: #495057; font-size: 16px; margin: 0 0 15px 0;">🎉 Your account has been created successfully! You're now part of the TEGA community.</p>
    
    <div style="background-color: #e7f3ff; padding: 20px; border-radius: 8px; margin: 20px 0;">
      <p style="color: #1e3a8a; font-size: 16px; margin: 0 0 15px 0; font-weight: 500;">🚀 What you can do now:</p>
      <div style="display: flex; flex-wrap: wrap; gap: 15px;">
        <div style="flex: 1; min-width: 200px; background: white; padding: 15px; border-radius: 6px; border-left: 4px solid #1e3a8a;">
          <p style="color: #1e3a8a; font-size: 14px; margin: 0 0 5px 0; font-weight: 500;">📚 Training Courses</p>
          <p style="color: #6c757d; font-size: 12px; margin: 0;">Access professional courses and certifications</p>
        </div>
        <div style="flex: 1; min-width: 200px; background: white; padding: 15px; border-radius: 6px; border-left: 4px solid #1e3a8a;">
          <p style="color: #1e3a8a; font-size: 14px; margin: 0 0 5px 0; font-weight: 500;">💼 Job Opportunities</p>
          <p style="color: #6c757d; font-size: 12px; margin: 0;">Apply for internships and full-time positions</p>
        </div>
        <div style="flex: 1; min-width: 200px; background: white; padding: 15px; border-radius: 6px; border-left: 4px solid #1e3a8a;">
          <p style="color: #1e3a8a; font-size: 14px; margin: 0 0 5px 0; font-weight: 500;">📄 Resume Builder</p>
          <p style="color: #6c757d; font-size: 12px; margin: 0;">Create professional resumes with our tools</p>
        </div>
        <div style="flex: 1; min-width: 200px; background: white; padding: 15px; border-radius: 6px; border-left: 4px solid #1e3a8a;">
          <p style="color: #1e3a8a; font-size: 14px; margin: 0 0 5px 0; font-weight: 500;">🏆 Certificates</p>
          <p style="color: #6c757d; font-size: 12px; margin: 0;">Earn certificates for completed courses</p>
        </div>
      </div>
    </div>
    
    <div style="text-align: center; margin: 25px 0;">
      <a href="${process.env.CLIENT_URL || 'http://localhost:3000'}/dashboard" style="background: #1e3a8a; color: white; padding: 15px 30px; text-decoration: none; font-size: 16px; border-radius: 8px; display: inline-block; font-weight: 500;">Start Your Journey</a>
    </div>
    
    <p style="color: #6c757d; font-size: 13px; margin: 15px 0 0 0; text-align: center;">💡 Complete your profile to get personalized recommendations and better opportunities.</p>
  `;
  
  return getBaseEmailTemplate('Welcome to TEGA!', content);
};

// Professional Principal Welcome template (with credentials)
export const getPrincipalWelcomeTemplate = (principalName, email, password) => {
  const content = `
    <h2 style="color: #1e3a8a; font-size: 24px; margin: 0 0 15px 0; font-weight: 600;">Welcome to TEGA, ${principalName}!</h2>
    
    <p style="color: #495057; font-size: 16px; margin: 0 0 15px 0;">An admin has created a principal account for you on the TEGA Platform.</p>
    
    <div style="background-color: #e7f3ff; padding: 20px; border-radius: 8px; margin: 20px 0;">
      <p style="color: #1e3a8a; font-size: 16px; margin: 0 0 15px 0; font-weight: 500;">🔑 Your Login Credentials:</p>
      <div style="background: white; padding: 15px; border-radius: 6px; margin: 10px 0;">
        <p style="color: #495057; font-size: 14px; margin: 0 0 8px 0;"><strong>Email:</strong> ${email}</p>
        <p style="color: #495057; font-size: 14px; margin: 0;"><strong>Temporary Password:</strong> <code style="background: #f8f9fa; padding: 4px 8px; border-radius: 4px; font-family: 'Courier New', monospace; color: #1e3a8a;">${password}</code></p>
      </div>
      <p style="color: #dc3545; font-size: 13px; margin: 15px 0 0 0;">⚠️ We strongly recommend changing your password after your first login.</p>
    </div>
    
    <div style="background-color: #f8f9fa; padding: 15px; border-radius: 6px; margin: 15px 0;">
      <p style="color: #1e3a8a; font-size: 14px; margin: 0 0 8px 0; font-weight: 500;">📋 As a Principal, you can:</p>
      <ul style="color: #495057; font-size: 13px; margin: 0; padding-left: 20px;">
        <li>Manage students from your institution</li>
        <li>Monitor course enrollments and progress</li>
        <li>View and approve student applications</li>
        <li>Access institutional reports and analytics</li>
      </ul>
    </div>
    
    <div style="text-align: center; margin: 25px 0;">
      <a href="${process.env.CLIENT_URL || 'http://localhost:3000'}/principal/login" style="background: #1e3a8a; color: white; padding: 15px 30px; text-decoration: none; font-size: 16px; border-radius: 8px; display: inline-block; font-weight: 500;">Login to Your Account</a>
    </div>
    
    <p style="color: #6c757d; font-size: 13px; margin: 15px 0 0 0; text-align: center;">If you did not expect this account creation, please contact your admin immediately.</p>
  `;
  
  return getBaseEmailTemplate('Your Principal Account - TEGA Platform', content);
};