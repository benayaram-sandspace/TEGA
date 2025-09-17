const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

// AdminUser Schema
const adminUserSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      match: [
        /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/,
        "Please enter a valid email",
      ],
    },
    password: {
      type: String,
      required: true,
      minlength: 6,
      select: false, // Don't include password in queries by default
    },
    role: {
      type: String,
      required: true,
      enum: ["super_admin", "admin", "moderator", "viewer"],
      default: "admin",
    },
    status: {
      type: String,
      required: true,
      enum: ["active", "inactive", "pending"],
      default: "pending",
    },
    profileImage: {
      type: String,
      default: "",
    },
    lastLogin: {
      type: Date,
      default: Date.now,
    },
    permissions: {
      type: [String],
      default: [],
      enum: [
        "user_management",
        "college_management",
        "content_management",
        "analytics_view",
        "system_settings",
        "role_management",
        "audit_logs",
        "reports_export",
      ],
    },
    inviteToken: {
      type: String,
      select: false,
    },
    inviteTokenExpiry: {
      type: Date,
      select: false,
    },
    resetPasswordToken: {
      type: String,
      select: false,
    },
    resetPasswordExpiry: {
      type: Date,
      select: false,
    },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: function (doc, ret) {
        ret.id = ret._id;
        ret.createdAt = ret.createdAt;
        ret.lastLogin = ret.lastLogin;
        delete ret._id;
        delete ret.__v;
        delete ret.password;
        return ret;
      },
    },
  }
);

// Indexes for AdminUser
adminUserSchema.index({ email: 1 });
adminUserSchema.index({ role: 1 });
adminUserSchema.index({ status: 1 });

// Hash password before saving
adminUserSchema.pre("save", async function (next) {
  if (!this.isModified("password")) return next();

  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Instance methods for AdminUser
adminUserSchema.methods.comparePassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

adminUserSchema.methods.updateLastLogin = function () {
  this.lastLogin = new Date();
  return this.save();
};

adminUserSchema.methods.hasPermission = function (permission) {
  return this.permissions.includes(permission);
};

adminUserSchema.methods.activate = function () {
  this.status = "active";
  this.inviteToken = undefined;
  this.inviteTokenExpiry = undefined;
  return this.save();
};

// Static methods for AdminUser
adminUserSchema.statics.findActiveAdmins = function () {
  return this.find({ status: "active" });
};

adminUserSchema.statics.findByRole = function (role) {
  return this.find({ role: role });
};

adminUserSchema.statics.getStatistics = async function () {
  const stats = await this.aggregate([
    {
      $facet: {
        totalAdmins: [{ $count: "count" }],
        activeAdmins: [{ $match: { status: "active" } }, { $count: "count" }],
        pendingInvites: [
          { $match: { status: "pending" } },
          { $count: "count" },
        ],
      },
    },
  ]);

  return {
    totalAdmins: stats[0].totalAdmins[0]?.count || 0,
    activeAdmins: stats[0].activeAdmins[0]?.count || 0,
    pendingInvites: stats[0].pendingInvites[0]?.count || 0,
  };
};

// ActivityLog Schema
const activityLogSchema = new mongoose.Schema(
  {
    adminName: {
      type: String,
      required: true,
    },
    adminId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "AdminUser",
      required: true,
    },
    action: {
      type: String,
      required: true,
      trim: true,
    },
    target: {
      type: String,
      required: true,
      trim: true,
    },
    details: {
      type: String,
      required: true,
    },
    actionType: {
      type: String,
      required: true,
      enum: [
        "user_management",
        "college_management",
        "content_management",
        "system_settings",
        "role_management",
        "authentication",
        "data_export",
        "other",
      ],
    },
    ipAddress: {
      type: String,
    },
    userAgent: {
      type: String,
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: { createdAt: "timestamp", updatedAt: false },
    toJSON: {
      virtuals: true,
      transform: function (doc, ret) {
        ret.id = ret._id;
        ret.timestamp = ret.timestamp;
        delete ret._id;
        delete ret.__v;
        return ret;
      },
    },
  }
);

// Indexes for ActivityLog
activityLogSchema.index({ adminId: 1 });
activityLogSchema.index({ actionType: 1 });
activityLogSchema.index({ timestamp: -1 });
activityLogSchema.index({ adminId: 1, timestamp: -1 });

// Static methods for ActivityLog
activityLogSchema.statics.getRecentActivities = function (limit = 50) {
  return this.find()
    .sort({ timestamp: -1 })
    .limit(limit)
    .populate("adminId", "name email role");
};

activityLogSchema.statics.getActivitiesByAdmin = function (
  adminId,
  limit = 50
) {
  return this.find({ adminId }).sort({ timestamp: -1 }).limit(limit);
};

activityLogSchema.statics.getActivitiesByType = function (actionType) {
  return this.find({ actionType }).sort({ timestamp: -1 });
};

activityLogSchema.statics.getStatistics = async function () {
  const stats = await this.aggregate([
    {
      $group: {
        _id: "$actionType",
        count: { $sum: 1 },
      },
    },
  ]);

  const activitiesByType = {};
  let totalActivities = 0;

  stats.forEach((stat) => {
    activitiesByType[stat._id] = stat.count;
    totalActivities += stat.count;
  });

  return {
    totalActivities,
    activitiesByType,
  };
};

// AdminInvite Schema (for tracking pending invites)
const adminInviteSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      match: [
        /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/,
        "Please enter a valid email",
      ],
    },
    role: {
      type: String,
      required: true,
      enum: ["super_admin", "admin", "moderator", "viewer"],
    },
    permissions: {
      type: [String],
      default: [],
    },
    inviteToken: {
      type: String,
      required: true,
      unique: true,
    },
    invitedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "AdminUser",
      required: true,
    },
    status: {
      type: String,
      enum: ["pending", "accepted", "expired"],
      default: "pending",
    },
    expiresAt: {
      type: Date,
      required: true,
      default: () => new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
    },
  },
  {
    timestamps: true,
  }
);

// Index for invite token lookup
adminInviteSchema.index({ inviteToken: 1 });
adminInviteSchema.index({ email: 1 });
adminInviteSchema.index({ status: 1 });
adminInviteSchema.index({ expiresAt: 1 });

// Method to check if invite is expired
adminInviteSchema.methods.isExpired = function () {
  return this.expiresAt < new Date();
};

// Static method to clean up expired invites
adminInviteSchema.statics.cleanupExpired = async function () {
  return this.updateMany(
    {
      status: "pending",
      expiresAt: { $lt: new Date() },
    },
    {
      status: "expired",
    }
  );
};

// Create models
const AdminUser = mongoose.model("AdminUser", adminUserSchema);
const ActivityLog = mongoose.model("ActivityLog", activityLogSchema);
const AdminInvite = mongoose.model("AdminInvite", adminInviteSchema);

// Helper function to get complete admin statistics
async function getAdminStatistics() {
  const adminStats = await AdminUser.getStatistics();
  const activityStats = await ActivityLog.getStatistics();
  const pendingInvites = await AdminInvite.countDocuments({
    status: "pending",
  });

  return {
    totalAdmins: adminStats.totalAdmins,
    activeAdmins: adminStats.activeAdmins,
    pendingInvites: pendingInvites,
    totalActivities: activityStats.totalActivities,
    activitiesByType: activityStats.activitiesByType,
  };
}

module.exports = {
  AdminUser,
  ActivityLog,
  AdminInvite,
  getAdminStatistics,
};
