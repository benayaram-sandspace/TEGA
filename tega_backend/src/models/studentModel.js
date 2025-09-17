import mongoose from "mongoose";

const studentSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      ref: "User",
      unique: true,
    },
    college: {
      type: String,
      required: true,
      trim: true,
    },
    status: {
      type: String,
      required: true,
      enum: ["active", "inactive", "graduated", "suspended"],
      default: "active",
    },
    student_id: {
      type: String,
      sparse: true,
      unique: true,
      trim: true,
    },
    branch: {
      type: String,
      trim: true,
    },
    year_of_study: {
      type: String,
      trim: true,
    },
    cgpa: {
      type: Number,
      min: 0,
      max: 10,
    },
    percentage: {
      type: Number,
      min: 0,
      max: 100,
    },
    interests: {
      type: [String],
      default: [],
    },
    job_readiness: {
      type: Number,
      min: 0,
      max: 100,
    },
    profile_image_url: {
      type: String,
      trim: true,
    },
    notification_count: {
      type: Number,
      default: 0,
      min: 0,
    },
    course: {
      type: String,
      trim: true,
    },
    year: {
      type: String,
      trim: true,
    },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: function (doc, ret) {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        return ret;
      },
    },
    toObject: {
      virtuals: true,
      transform: function (doc, ret) {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        return ret;
      },
    },
  }
);

studentSchema.index({ student_id: 1 });
studentSchema.index({ college: 1 });
studentSchema.index({ status: 1 });
studentSchema.index({ branch: 1, year_of_study: 1 });

studentSchema.virtual("formatted_course").get(function () {
  if (this.course) {
    return this.course;
  }
  if (this.branch && this.year_of_study) {
    return `${this.branch} | ${this.year_of_study}`;
  }
  return "";
});

studentSchema.methods.updateJobReadiness = function (newReadiness) {
  this.job_readiness = newReadiness;
  return this.save();
};

studentSchema.methods.incrementNotificationCount = function () {
  this.notification_count += 1;
  return this.save();
};

studentSchema.methods.resetNotificationCount = function () {
  this.notification_count = 0;
  return this.save();
};

studentSchema.statics.findByCollege = function (collegeName) {
  return this.find({ college: collegeName });
};

studentSchema.statics.findActiveStudents = function () {
  return this.find({ status: "active" });
};

studentSchema.statics.findByBranchAndYear = function (branch, year) {
  return this.find({
    branch: branch,
    year_of_study: year,
  });
};

studentSchema.pre("save", function (next) {
  if (!this.year && this.year_of_study) {
    this.year = this.year_of_study;
  }
  if (!this.course && this.branch && this.year_of_study) {
    this.course = `${this.branch} | ${this.year_of_study}`;
  }
  next();
});

const Student = mongoose.model("Student", studentSchema);

export default Student;
