import '../config/env_config.dart';

class ApiEndpoints {
  // ==================== AUTHENTICATION ====================
  static String get register => '${EnvConfig.baseUrl}/api/auth/register';
  static String get login => '${EnvConfig.baseUrl}/api/auth/login';
  static String get logout => '${EnvConfig.baseUrl}/api/auth/logout';
  static String get forgotPassword =>
      '${EnvConfig.baseUrl}/api/auth/forgot-password';
  static String get verifyOTP => '${EnvConfig.baseUrl}/api/auth/verify-otp';
  static String get resetPassword =>
      '${EnvConfig.baseUrl}/api/auth/reset-password';
  static String get sendRegistrationOTP =>
      '${EnvConfig.baseUrl}/api/auth/register/send-otp';
  static String get verifyRegistrationOTP =>
      '${EnvConfig.baseUrl}/api/auth/register/verify-otp';
  static String get refreshToken =>
      '${EnvConfig.baseUrl}/api/auth/refresh-token';
  static String get checkEmail => '${EnvConfig.baseUrl}/api/auth/check-email';

  // ==================== ADMIN DASHBOARD ====================
  static String get adminDashboard =>
      '${EnvConfig.baseUrl}/api/admin/dashboard';

  // Admin - Principal Management
  static String get adminPrincipals =>
      '${EnvConfig.baseUrl}/api/admin/principals';
  static String adminPrincipalById(String id) =>
      '${EnvConfig.baseUrl}/api/admin/principals/$id';
  static String get adminRegisterPrincipal =>
      '${EnvConfig.baseUrl}/api/admin/principals/register';

  // Admin - Student Management
  static String get adminStudents => '${EnvConfig.baseUrl}/api/admin/students';
  static String adminStudentById(String id) =>
      '${EnvConfig.baseUrl}/api/admin/students/$id';
  static String get adminCreateStudent =>
      '${EnvConfig.baseUrl}/api/admin/students/create';
  static String get adminBulkImportStudents =>
      '${EnvConfig.baseUrl}/api/admin/students/bulk-import';

  // Admin - Notifications
  static String get adminNotifications =>
      '${EnvConfig.baseUrl}/api/admin/notifications';
  static String adminNotificationById(String id) =>
      '${EnvConfig.baseUrl}/api/admin/notifications/$id';

  // Admin - Payments (Unified view)
  static String get adminPayments => '${EnvConfig.baseUrl}/api/admin/payments';

  // Admin - Courses
  static String get adminCourses => '${EnvConfig.baseUrl}/api/admin/courses';

  // Admin - UPI Settings
  static String get adminUPISettings =>
      '${EnvConfig.baseUrl}/api/admin/upi-settings';

  // ==================== STUDENT ====================
  static String get studentDashboard =>
      '${EnvConfig.baseUrl}/api/student/dashboard';
  static String get studentSidebarCounts =>
      '${EnvConfig.baseUrl}/api/student/sidebar-counts';
  static String get studentNotifications =>
      '${EnvConfig.baseUrl}/api/notifications/user';
  static String get studentProfile =>
      '${EnvConfig.baseUrl}/api/student/profile';

  // Learning History & Progress (using available endpoints)
  static String get studentProgress =>
      '${EnvConfig.baseUrl}/api/student/progress';
  static String get learningHistory =>
      '${EnvConfig.baseUrl}/api/student/learning-history';

  // Transaction History & Payments
  static String get paymentHistory =>
      '${EnvConfig.baseUrl}/api/payments/history';
  static String get razorpayPaymentHistory =>
      '${EnvConfig.baseUrl}/api/razorpay/history';
  static String get tegaExamPaymentHistory =>
      '${EnvConfig.baseUrl}/api/tega-exam-payments/history';
  static String get studentUpdateProfile =>
      '${EnvConfig.baseUrl}/api/student/profile/update';
  static String get studentUploadPhoto =>
      '${EnvConfig.baseUrl}/api/student/profile/upload-photo';
  static String get studentRemovePhoto =>
      '${EnvConfig.baseUrl}/api/student/profile/remove-photo';

  // ==================== PAYMENTS ====================
  // Public routes
  static String get paymentCourses =>
      '${EnvConfig.baseUrl}/api/payments/courses';
  static String paymentCoursePricing(String courseId) =>
      '${EnvConfig.baseUrl}/api/payments/courses/$courseId/pricing';

  // Protected routes
  static String get paymentCreateOrder =>
      '${EnvConfig.baseUrl}/api/payments/create-order';
  static String get paymentProcessDummy =>
      '${EnvConfig.baseUrl}/api/payments/process-dummy';
  static String get paymentVerify => '${EnvConfig.baseUrl}/api/payments/verify';
  static String get paymentUPIVerify =>
      '${EnvConfig.baseUrl}/api/payments/upi-verify';
  static String paymentCourseAccess(String courseId) =>
      '${EnvConfig.baseUrl}/api/payments/course-access/$courseId';
  static String paymentReceipt(String paymentId) =>
      '${EnvConfig.baseUrl}/api/payments/receipt/$paymentId';

  // Admin payment routes
  static String get adminPaymentsList =>
      '${EnvConfig.baseUrl}/api/payments/admin/payments';
  static String get adminPaymentStats =>
      '${EnvConfig.baseUrl}/api/payments/admin/stats';
  static String adminPaymentById(String id) =>
      '${EnvConfig.baseUrl}/api/payments/admin/payments/$id';

  // ==================== COURSES (Legacy System) ====================
  // Public routes
  static String get courses => '${EnvConfig.baseUrl}/api/courses';
  static String courseById(String id) => '${EnvConfig.baseUrl}/api/courses/$id';
  static String courseContent(String id) =>
      '${EnvConfig.baseUrl}/api/courses/$id/content';

  // Admin routes
  static String get adminCreateCourse =>
      '${EnvConfig.baseUrl}/api/courses/admin/create';
  static String get adminUploadCourse =>
      '${EnvConfig.baseUrl}/api/courses/admin/upload';
  static String get adminBulkUploadCourses =>
      '${EnvConfig.baseUrl}/api/courses/admin/bulk-upload';
  static String adminUpdateCourse(String id) =>
      '${EnvConfig.baseUrl}/api/courses/admin/$id';
  static String adminDeleteCourse(String id) =>
      '${EnvConfig.baseUrl}/api/courses/admin/$id';

  // ==================== REAL-TIME COURSES (New System) ====================
  // Public routes
  static String get realTimeCourses =>
      '${EnvConfig.baseUrl}/api/realtime-courses';
  static String realTimeCourseById(String id) =>
      '${EnvConfig.baseUrl}/api/realtime-courses/$id';

  // Student routes (protected)
  static String realTimeCourseAccess(String id) =>
      '${EnvConfig.baseUrl}/api/realtime-courses/$id/access';
  static String realTimeCourseEnrollmentStatus(String id) =>
      '${EnvConfig.baseUrl}/api/realtime-courses/$id/enrollment-status';
  static String realTimeCourseEnroll(String id) =>
      '${EnvConfig.baseUrl}/api/realtime-courses/$id/enroll';
  static String realTimeCourseLectureProgress(
    String courseId,
    String lectureId,
  ) =>
      '${EnvConfig.baseUrl}/api/realtime-courses/$courseId/lectures/$lectureId/progress';
  static String realTimeCourseQuizSubmit(String courseId, String lectureId) =>
      '${EnvConfig.baseUrl}/api/realtime-courses/$courseId/lectures/$lectureId/quiz-submit';
  static String realTimeCourseHeartbeat(String id) =>
      '${EnvConfig.baseUrl}/api/realtime-courses/$id/heartbeat';
  static String get realTimeStudentEnrollments =>
      '${EnvConfig.baseUrl}/api/enrollments/student/enrollments';

  // Admin routes
  static String get adminCreateRealTimeCourse =>
      '${EnvConfig.baseUrl}/api/realtime-courses/admin/create';
  static String adminUpdateRealTimeCourse(String id) =>
      '${EnvConfig.baseUrl}/api/realtime-courses/admin/$id';
  static String adminDeleteRealTimeCourse(String id) =>
      '${EnvConfig.baseUrl}/api/realtime-courses/admin/$id';
  static String adminPublishRealTimeCourse(String id) =>
      '${EnvConfig.baseUrl}/api/realtime-courses/admin/$id/publish';
  static String get adminRealTimeCourseAnalytics =>
      '${EnvConfig.baseUrl}/api/realtime-courses/admin/analytics';

  // ==================== EXAMS ====================
  // Admin routes
  static String get adminExams => '${EnvConfig.baseUrl}/api/exams/admin';
  static String adminExamById(String id) =>
      '${EnvConfig.baseUrl}/api/exams/admin/$id';
  static String adminExamRegistrations(String id) =>
      '${EnvConfig.baseUrl}/api/exams/admin/$id/registrations';
  static String adminExamAttempts(String id) =>
      '${EnvConfig.baseUrl}/api/exams/admin/$id/attempts';
  static String adminExamRetakes(String id) =>
      '${EnvConfig.baseUrl}/api/exams/admin/$id/retakes';

  // Student routes
  static String get studentExams =>
      '${EnvConfig.baseUrl}/api/exams/student/available';
  static String get studentExamResults =>
      '${EnvConfig.baseUrl}/api/exams/student/results';
  static String studentRegisterExam(String id) =>
      '${EnvConfig.baseUrl}/api/exams/student/$id/register';
  static String studentStartExam(String id) =>
      '${EnvConfig.baseUrl}/api/exams/student/$id/start';
  static String studentSaveAnswer(String attemptId) =>
      '${EnvConfig.baseUrl}/api/exams/student/attempt/$attemptId/save-answer';
  static String studentSubmitExam(String attemptId) =>
      '${EnvConfig.baseUrl}/api/exams/student/attempt/$attemptId/submit';
  static String studentExamResult(String attemptId) =>
      '${EnvConfig.baseUrl}/api/exams/student/attempt/$attemptId/result';

  // Payment attempts
  static String examPaymentAttempt(String id) =>
      '${EnvConfig.baseUrl}/api/exams/$id/payment-attempt';

  // Resume Builder
  static String get studentResume => '${EnvConfig.baseUrl}/api/student/resume';
  static String get studentResumeTemplates =>
      '${EnvConfig.baseUrl}/api/student/resume/templates';
  static String studentResumeExportPDF(String resumeId) =>
      '${EnvConfig.baseUrl}/api/student/resume/$resumeId/export-pdf';

  // ==================== PLACEMENT / COMPANY QUESTIONS ====================
  // Admin routes
  static String get adminPlacementQuestions =>
      '${EnvConfig.baseUrl}/api/placement/admin/questions';
  static String adminPlacementQuestionById(String id) =>
      '${EnvConfig.baseUrl}/api/placement/admin/questions/$id';
  static String get adminBulkUploadQuestions =>
      '${EnvConfig.baseUrl}/api/placement/admin/questions/bulk-upload';
  static String get adminPlacementModules =>
      '${EnvConfig.baseUrl}/api/placement/admin/modules';
  static String adminPlacementModuleById(String id) =>
      '${EnvConfig.baseUrl}/api/placement/admin/modules/$id';
  static String get adminPlacementStats =>
      '${EnvConfig.baseUrl}/api/placement/admin/stats';

  // Student routes
  static String get studentPlacementModules =>
      '${EnvConfig.baseUrl}/api/placement/student/modules';
  static String studentPlacementModuleQuestions(String moduleId) =>
      '${EnvConfig.baseUrl}/api/placement/student/modules/$moduleId/questions';
  static String get studentSubmitAnswer =>
      '${EnvConfig.baseUrl}/api/placement/student/submit-answer';
  static String get studentPlacementProgress =>
      '${EnvConfig.baseUrl}/api/placement/student/progress';
  static String get studentMockInterviews =>
      '${EnvConfig.baseUrl}/api/placement/student/mock-interviews';
  static String studentMockInterviewById(String id) =>
      '${EnvConfig.baseUrl}/api/placement/student/mock-interviews/$id';

  // ==================== JOBS ====================
  // Admin routes
  static String get adminJobs => '${EnvConfig.baseUrl}/api/jobs/admin';
  static String adminJobById(String id) =>
      '${EnvConfig.baseUrl}/api/jobs/admin/$id';
  static String adminUpdateJobStatus(String id) =>
      '${EnvConfig.baseUrl}/api/jobs/admin/$id/status';

  // Public routes
  static String get jobs => '${EnvConfig.baseUrl}/api/jobs';
  static String jobById(String id) => '${EnvConfig.baseUrl}/api/jobs/$id';

  // Student routes
  static String studentApplyJob(String id) =>
      '${EnvConfig.baseUrl}/api/jobs/$id/apply';

  // ==================== INTERNSHIPS ====================
  // Admin routes
  static String get adminInternships =>
      '${EnvConfig.baseUrl}/api/internships/admin';
  static String adminInternshipById(String id) =>
      '${EnvConfig.baseUrl}/api/internships/admin/$id';
  static String adminUpdateInternshipStatus(String id) =>
      '${EnvConfig.baseUrl}/api/internships/admin/$id/status';

  // Public routes
  static String get internships => '${EnvConfig.baseUrl}/api/internships';
  static String internshipById(String id) =>
      '${EnvConfig.baseUrl}/api/internships/$id';

  // Student routes
  static String studentApplyInternship(String id) =>
      '${EnvConfig.baseUrl}/api/internships/$id/apply';

  // ==================== OFFERS (College-specific discounts) ====================
  // Admin routes
  static String get adminOffers => '${EnvConfig.baseUrl}/api/offers/admin';
  static String adminOfferById(String id) =>
      '${EnvConfig.baseUrl}/api/offers/admin/$id';
  static String adminToggleOffer(String id) =>
      '${EnvConfig.baseUrl}/api/offers/admin/$id/toggle';
  static String get adminOfferStats =>
      '${EnvConfig.baseUrl}/api/offers/admin/stats';

  // Public routes
  static String offersByInstitute(String instituteName) =>
      '${EnvConfig.baseUrl}/api/offers/institute/$instituteName';
  static String offersByCourseOrExam(String type, String id) =>
      '${EnvConfig.baseUrl}/api/offers/$type/$id';

  // ==================== RESUME ====================
  static String get resumeCreate => '${EnvConfig.baseUrl}/api/resume/create';
  static String get resumeGet => '${EnvConfig.baseUrl}/api/resume';
  static String get resumeUpdate => '${EnvConfig.baseUrl}/api/resume/update';
  static String get resumeDelete => '${EnvConfig.baseUrl}/api/resume/delete';
  static String get resumeUpload => '${EnvConfig.baseUrl}/api/resume/upload';
  static String get resumeGenerate =>
      '${EnvConfig.baseUrl}/api/resume/generate';
  static String resumeDownload(String resumeId) =>
      '${EnvConfig.baseUrl}/api/resume/download/$resumeId';

  // ==================== CERTIFICATES ====================
  static String certificateGenerate(String courseId) =>
      '${EnvConfig.baseUrl}/api/certificates/generate/$courseId';
  static String certificateVerify(String certificateNumber) =>
      '${EnvConfig.baseUrl}/api/certificates/verify/$certificateNumber';
  static String certificateDownload(String certificateId) =>
      '${EnvConfig.baseUrl}/api/certificates/download/$certificateId';
  static String get studentCertificates =>
      '${EnvConfig.baseUrl}/api/certificates/student';

  // ==================== QUESTION PAPERS ====================
  // Admin routes
  static String get adminQuestionPapers =>
      '${EnvConfig.baseUrl}/api/question-papers/admin';
  static String adminQuestionPaperById(String id) =>
      '${EnvConfig.baseUrl}/api/question-papers/admin/$id';
  static String get adminUploadQuestionPaper =>
      '${EnvConfig.baseUrl}/api/question-papers/admin/upload';

  // Public routes
  static String questionPaperById(String id) =>
      '${EnvConfig.baseUrl}/api/question-papers/$id';

  // ==================== COLLEGES ====================
  static String get colleges => '${EnvConfig.baseUrl}/api/colleges';
  static String collegeById(String id) =>
      '${EnvConfig.baseUrl}/api/colleges/$id';

  // ==================== PRINCIPAL (College Admin) ====================
  static String get principalDashboard =>
      '${EnvConfig.baseUrl}/api/principal/dashboard';
  static String get principalStudents =>
      '${EnvConfig.baseUrl}/api/principal/students';
  static String get principalProfile =>
      '${EnvConfig.baseUrl}/api/principal/profile';

  // ==================== VIDEOS ====================
  static String videoSignedUrl(String filename) =>
      '${EnvConfig.baseUrl}/api/videos/signed-url/$filename';

  // ==================== HEALTH & TEST ====================
  static String get health => '${EnvConfig.baseUrl}/api/health';
  static String get test => '${EnvConfig.baseUrl}/api/test';
  static String get testModels =>
      '${EnvConfig.baseUrl}/api/test-models/test-models';

  // ==================== UTILITY METHODS ====================
  /// Build URL with query parameters
  static String buildUrlWithParams(
    String baseUrl,
    Map<String, dynamic> params,
  ) {
    if (params.isEmpty) return baseUrl;

    final queryString = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
        )
        .join('&');

    return '$baseUrl?$queryString';
  }

  /// Build URL for file upload endpoints
  static String uploadsPath(String filename) =>
      '${EnvConfig.baseUrl}/uploads/$filename';
}
