const String baseUrl = 'http://192.168.0.180:5001';

class ApiEndpoints {
  // ==================== AUTHENTICATION ====================
  static const String register = '$baseUrl/api/auth/register';
  static const String login = '$baseUrl/api/auth/login';
  static const String logout = '$baseUrl/api/auth/logout';
  static const String forgotPassword = '$baseUrl/api/auth/forgot-password';
  static const String verifyOTP = '$baseUrl/api/auth/verify-otp';
  static const String resetPassword = '$baseUrl/api/auth/reset-password';
  static const String sendRegistrationOTP =
      '$baseUrl/api/auth/register/send-otp';
  static const String verifyRegistrationOTP =
      '$baseUrl/api/auth/register/verify-otp';
  static const String refreshToken = '$baseUrl/api/auth/refresh-token';
  static const String checkEmail = '$baseUrl/api/auth/check-email';

  // ==================== ADMIN DASHBOARD ====================
  static const String adminDashboard = '$baseUrl/api/admin/dashboard';

  // Admin - Principal Management
  static const String adminPrincipals = '$baseUrl/api/admin/principals';
  static String adminPrincipalById(String id) =>
      '$baseUrl/api/admin/principals/$id';
  static const String adminRegisterPrincipal =
      '$baseUrl/api/admin/principals/register';

  // Admin - Student Management
  static const String adminStudents = '$baseUrl/api/admin/students';
  static String adminStudentById(String id) =>
      '$baseUrl/api/admin/students/$id';
  static const String adminCreateStudent = '$baseUrl/api/admin/students/create';
  static const String adminBulkImportStudents =
      '$baseUrl/api/admin/students/bulk-import';

  // Admin - Notifications
  static const String adminNotifications = '$baseUrl/api/admin/notifications';
  static String adminNotificationById(String id) =>
      '$baseUrl/api/admin/notifications/$id';

  // Admin - Payments (Unified view)
  static const String adminPayments = '$baseUrl/api/admin/payments';

  // Admin - Courses
  static const String adminCourses = '$baseUrl/api/admin/courses';

  // Admin - UPI Settings
  static const String adminUPISettings = '$baseUrl/api/admin/upi-settings';

  // ==================== STUDENT ====================
  static const String studentDashboard = '$baseUrl/api/student/dashboard';
  static const String studentSidebarCounts =
      '$baseUrl/api/student/sidebar-counts';
  static const String studentNotifications =
      '$baseUrl/api/student/notifications';
  static const String studentProfile = '$baseUrl/api/student/profile';
  static const String studentUpdateProfile =
      '$baseUrl/api/student/profile/update';
  static const String studentUploadPhoto =
      '$baseUrl/api/student/profile/upload-photo';
  static const String studentRemovePhoto =
      '$baseUrl/api/student/profile/remove-photo';

  // ==================== PAYMENTS ====================
  // Public routes
  static const String paymentCourses = '$baseUrl/api/payments/courses';
  static String paymentCoursePricing(String courseId) =>
      '$baseUrl/api/payments/courses/$courseId/pricing';

  // Protected routes
  static const String paymentCreateOrder = '$baseUrl/api/payments/create-order';
  static const String paymentProcessDummy =
      '$baseUrl/api/payments/process-dummy';
  static const String paymentVerify = '$baseUrl/api/payments/verify';
  static const String paymentUPIVerify = '$baseUrl/api/payments/upi-verify';
  static const String paymentHistory = '$baseUrl/api/payments/history';
  static String paymentCourseAccess(String courseId) =>
      '$baseUrl/api/payments/course-access/$courseId';
  static String paymentReceipt(String paymentId) =>
      '$baseUrl/api/payments/receipt/$paymentId';

  // Admin payment routes
  static const String adminPaymentsList =
      '$baseUrl/api/payments/admin/payments';
  static const String adminPaymentStats = '$baseUrl/api/payments/admin/stats';
  static String adminPaymentById(String id) =>
      '$baseUrl/api/payments/admin/payments/$id';

  // ==================== COURSES (Legacy System) ====================
  // Public routes
  static const String courses = '$baseUrl/api/courses';
  static String courseById(String id) => '$baseUrl/api/courses/$id';
  static String courseContent(String id) => '$baseUrl/api/courses/$id/content';

  // Admin routes
  static const String adminCreateCourse = '$baseUrl/api/courses/admin/create';
  static const String adminUploadCourse = '$baseUrl/api/courses/admin/upload';
  static const String adminBulkUploadCourses =
      '$baseUrl/api/courses/admin/bulk-upload';
  static String adminUpdateCourse(String id) =>
      '$baseUrl/api/courses/admin/$id';
  static String adminDeleteCourse(String id) =>
      '$baseUrl/api/courses/admin/$id';

  // ==================== REAL-TIME COURSES (New System) ====================
  // Public routes
  static const String realTimeCourses = '$baseUrl/api/realtime-courses';
  static String realTimeCourseById(String id) =>
      '$baseUrl/api/realtime-courses/$id';

  // Student routes (protected)
  static String realTimeCourseAccess(String id) =>
      '$baseUrl/api/realtime-courses/$id/access';
  static String realTimeCourseEnrollmentStatus(String id) =>
      '$baseUrl/api/realtime-courses/$id/enrollment-status';
  static String realTimeCourseEnroll(String id) =>
      '$baseUrl/api/realtime-courses/$id/enroll';
  static String realTimeCourseLectureProgress(
    String courseId,
    String lectureId,
  ) => '$baseUrl/api/realtime-courses/$courseId/lectures/$lectureId/progress';
  static String realTimeCourseQuizSubmit(String courseId, String lectureId) =>
      '$baseUrl/api/realtime-courses/$courseId/lectures/$lectureId/quiz-submit';
  static String realTimeCourseHeartbeat(String id) =>
      '$baseUrl/api/realtime-courses/$id/heartbeat';

  // Admin routes
  static const String adminCreateRealTimeCourse =
      '$baseUrl/api/realtime-courses/admin/create';
  static String adminUpdateRealTimeCourse(String id) =>
      '$baseUrl/api/realtime-courses/admin/$id';
  static String adminDeleteRealTimeCourse(String id) =>
      '$baseUrl/api/realtime-courses/admin/$id';
  static String adminPublishRealTimeCourse(String id) =>
      '$baseUrl/api/realtime-courses/admin/$id/publish';
  static const String adminRealTimeCourseAnalytics =
      '$baseUrl/api/realtime-courses/admin/analytics';

  // ==================== EXAMS ====================
  // Admin routes
  static const String adminExams = '$baseUrl/api/exams/admin';
  static String adminExamById(String id) => '$baseUrl/api/exams/admin/$id';
  static String adminExamRegistrations(String id) =>
      '$baseUrl/api/exams/admin/$id/registrations';
  static String adminExamAttempts(String id) =>
      '$baseUrl/api/exams/admin/$id/attempts';
  static String adminExamRetakes(String id) =>
      '$baseUrl/api/exams/admin/$id/retakes';

  // Student routes
  static const String studentExams = '$baseUrl/api/exams/student/available';
  static String studentRegisterExam(String id) =>
      '$baseUrl/api/exams/student/$id/register';
  static String studentStartExam(String id) =>
      '$baseUrl/api/exams/student/$id/start';
  static String studentSaveAnswer(String attemptId) =>
      '$baseUrl/api/exams/student/attempt/$attemptId/save-answer';
  static String studentSubmitExam(String attemptId) =>
      '$baseUrl/api/exams/student/attempt/$attemptId/submit';
  static String studentExamResult(String attemptId) =>
      '$baseUrl/api/exams/student/attempt/$attemptId/result';

  // Payment attempts
  static String examPaymentAttempt(String id) =>
      '$baseUrl/api/exams/$id/payment-attempt';

  // ==================== PLACEMENT / COMPANY QUESTIONS ====================
  // Admin routes
  static const String adminPlacementQuestions =
      '$baseUrl/api/placement/admin/questions';
  static String adminPlacementQuestionById(String id) =>
      '$baseUrl/api/placement/admin/questions/$id';
  static const String adminBulkUploadQuestions =
      '$baseUrl/api/placement/admin/questions/bulk-upload';
  static const String adminPlacementModules =
      '$baseUrl/api/placement/admin/modules';
  static String adminPlacementModuleById(String id) =>
      '$baseUrl/api/placement/admin/modules/$id';
  static const String adminPlacementStats =
      '$baseUrl/api/placement/admin/stats';

  // Student routes
  static const String studentPlacementModules =
      '$baseUrl/api/placement/student/modules';
  static String studentPlacementModuleQuestions(String moduleId) =>
      '$baseUrl/api/placement/student/modules/$moduleId/questions';
  static const String studentSubmitAnswer =
      '$baseUrl/api/placement/student/submit-answer';
  static const String studentPlacementProgress =
      '$baseUrl/api/placement/student/progress';
  static const String studentMockInterviews =
      '$baseUrl/api/placement/student/mock-interviews';
  static String studentMockInterviewById(String id) =>
      '$baseUrl/api/placement/student/mock-interviews/$id';

  // ==================== JOBS ====================
  // Admin routes
  static const String adminJobs = '$baseUrl/api/jobs/admin';
  static String adminJobById(String id) => '$baseUrl/api/jobs/admin/$id';
  static String adminUpdateJobStatus(String id) =>
      '$baseUrl/api/jobs/admin/$id/status';

  // Public routes
  static const String jobs = '$baseUrl/api/jobs';
  static String jobById(String id) => '$baseUrl/api/jobs/$id';

  // Student routes
  static String studentApplyJob(String id) => '$baseUrl/api/jobs/$id/apply';

  // ==================== OFFERS (College-specific discounts) ====================
  // Admin routes
  static const String adminOffers = '$baseUrl/api/offers/admin';
  static String adminOfferById(String id) => '$baseUrl/api/offers/admin/$id';
  static String adminToggleOffer(String id) =>
      '$baseUrl/api/offers/admin/$id/toggle';
  static const String adminOfferStats = '$baseUrl/api/offers/admin/stats';

  // Public routes
  static String offersByInstitute(String instituteName) =>
      '$baseUrl/api/offers/institute/$instituteName';
  static String offersByCourseOrExam(String type, String id) =>
      '$baseUrl/api/offers/$type/$id';

  // ==================== RESUME ====================
  static const String resumeCreate = '$baseUrl/api/resume/create';
  static const String resumeGet = '$baseUrl/api/resume';
  static const String resumeUpdate = '$baseUrl/api/resume/update';
  static const String resumeDelete = '$baseUrl/api/resume/delete';
  static const String resumeUpload = '$baseUrl/api/resume/upload';
  static const String resumeGenerate = '$baseUrl/api/resume/generate';
  static String resumeDownload(String resumeId) =>
      '$baseUrl/api/resume/download/$resumeId';

  // ==================== CERTIFICATES ====================
  static String certificateGenerate(String courseId) =>
      '$baseUrl/api/certificates/generate/$courseId';
  static String certificateVerify(String certificateNumber) =>
      '$baseUrl/api/certificates/verify/$certificateNumber';
  static String certificateDownload(String certificateId) =>
      '$baseUrl/api/certificates/download/$certificateId';
  static const String studentCertificates = '$baseUrl/api/certificates/student';

  // ==================== QUESTION PAPERS ====================
  // Admin routes
  static const String adminQuestionPapers =
      '$baseUrl/api/question-papers/admin';
  static String adminQuestionPaperById(String id) =>
      '$baseUrl/api/question-papers/admin/$id';
  static const String adminUploadQuestionPaper =
      '$baseUrl/api/question-papers/admin/upload';

  // Public routes
  static String questionPaperById(String id) =>
      '$baseUrl/api/question-papers/$id';

  // ==================== COLLEGES ====================
  static const String colleges = '$baseUrl/api/colleges';
  static String collegeById(String id) => '$baseUrl/api/colleges/$id';

  // ==================== PRINCIPAL (College Admin) ====================
  static const String principalDashboard = '$baseUrl/api/principal/dashboard';
  static const String principalStudents = '$baseUrl/api/principal/students';
  static const String principalProfile = '$baseUrl/api/principal/profile';

  // ==================== HEALTH & TEST ====================
  static const String health = '$baseUrl/api/health';
  static const String test = '$baseUrl/api/test';
  static const String testModels = '$baseUrl/api/test-models/test-models';

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
  static String uploadsPath(String filename) => '$baseUrl/uploads/$filename';
}
