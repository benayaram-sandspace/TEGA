import '../config/env_config.dart';

/// Production-ready API endpoints for TEGA Flutter app
///
/// This class contains all API endpoints organized by feature modules.
/// All endpoints are validated against the actual backend implementation.
class ApiEndpoints {
  // ==================== AUTHENTICATION ====================
  static String get register => '${EnvConfig.baseUrl}/api/auth/register';
  static String get login => '${EnvConfig.baseUrl}/api/auth/login';
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

  // ==================== STUDENT DASHBOARD & PROFILE ====================
  static String get studentDashboard =>
      '${EnvConfig.baseUrl}/api/student/dashboard';
  static String get studentSidebarCounts =>
      '${EnvConfig.baseUrl}/api/student/sidebar-counts';
  static String get studentProfile =>
      '${EnvConfig.baseUrl}/api/student/profile';
  static String get studentNotifications =>
      '${EnvConfig.baseUrl}/api/student/notifications';
  static String get studentMarkNotificationsRead =>
      '${EnvConfig.baseUrl}/api/student/notifications/mark-read';
  static String get studentUploadPhoto =>
      '${EnvConfig.baseUrl}/api/student/profile/photo';
  static String get studentRemovePhoto =>
      '${EnvConfig.baseUrl}/api/student/profile/photo';

  // ==================== REAL-TIME COURSES ====================
  // Public routes
  static String get realTimeCourses =>
      '${EnvConfig.baseUrl}/api/real-time-courses';
  static String realTimeCourseById(String id) =>
      '${EnvConfig.baseUrl}/api/real-time-courses/$id';
  static String realTimeCourseContent(String id) =>
      '${EnvConfig.baseUrl}/api/real-time-courses/$id/content';

  // Student routes (protected)
  static String realTimeCourseEnrollmentStatus(String id) =>
      '${EnvConfig.baseUrl}/api/real-time-courses/$id/enrollment-status';
  static String realTimeCourseEnroll(String id) =>
      '${EnvConfig.baseUrl}/api/real-time-courses/$id/enroll';
  static String realTimeCourseLectureProgress(
    String courseId,
    String lectureId,
  ) =>
      '${EnvConfig.baseUrl}/api/real-time-courses/$courseId/lectures/$lectureId/progress';
  static String realTimeCourseLectureDuration(
    String courseId,
    String lectureId,
  ) =>
      '${EnvConfig.baseUrl}/api/real-time-courses/$courseId/lectures/$lectureId/duration';
  static String realTimeCourseQuizSubmit(String courseId, String lectureId) =>
      '${EnvConfig.baseUrl}/api/real-time-courses/$courseId/lectures/$lectureId/quiz';
  static String realTimeCourseHeartbeat(String id) =>
      '${EnvConfig.baseUrl}/api/real-time-courses/$id/heartbeat';
  static String realTimeCourseProgress(String id) =>
      '${EnvConfig.baseUrl}/api/real-time-courses/$id/progress';

  // Admin routes
  static String get adminRealTimeCourses =>
      '${EnvConfig.baseUrl}/api/real-time-courses/admin';
  static String get adminRealTimeCoursesAll =>
      '${EnvConfig.baseUrl}/api/real-time-courses/admin/all';
  static String get adminCreateRealTimeCourse =>
      '${EnvConfig.baseUrl}/api/real-time-courses';
  static String adminUpdateRealTimeCourse(String id) =>
      '${EnvConfig.baseUrl}/api/real-time-courses/$id';
  static String adminDeleteRealTimeCourse(String id) =>
      '${EnvConfig.baseUrl}/api/real-time-courses/$id';
  static String adminPublishRealTimeCourse(String id) =>
      '${EnvConfig.baseUrl}/api/real-time-courses/$id/publish';
  static String adminRealTimeCourseAnalytics(String id) =>
      '${EnvConfig.baseUrl}/api/real-time-courses/$id/analytics';

  // ==================== PAYMENTS ====================
  // Public routes
  static String get paymentCourses =>
      '${EnvConfig.baseUrl}/api/payments/courses';
  static String get paymentPricing =>
      '${EnvConfig.baseUrl}/api/payments/pricing';

  // Protected routes
  static String get paymentCreateOrder =>
      '${EnvConfig.baseUrl}/api/payments/create-order';
  static String get paymentProcessDummy =>
      '${EnvConfig.baseUrl}/api/payments/process-dummy';
  static String get paymentVerify => '${EnvConfig.baseUrl}/api/payments/verify';
  static String get paymentUPIVerify =>
      '${EnvConfig.baseUrl}/api/payments/upi/verify';
  static String paymentUPIStatus(String transactionId) =>
      '${EnvConfig.baseUrl}/api/payments/upi/status/$transactionId';
  static String get paymentHistory =>
      '${EnvConfig.baseUrl}/api/payments/history';
  static String paymentCourseAccess(String courseId) =>
      '${EnvConfig.baseUrl}/api/payments/access/$courseId';
  static String get paymentPaidCourses =>
      '${EnvConfig.baseUrl}/api/payments/paid-courses';
  static String paymentOfferPrice(String studentId, [String? feature]) =>
      '${EnvConfig.baseUrl}/api/payments/offer-price/$studentId${feature != null ? '/$feature' : ''}';
  static String paymentReceipt(String transactionId) =>
      '${EnvConfig.baseUrl}/api/payments/receipt/$transactionId';
  static String get paymentRefund => '${EnvConfig.baseUrl}/api/payments/refund';

  // Admin routes
  static String get adminPaymentStats =>
      '${EnvConfig.baseUrl}/api/payments/stats';
  static String get adminPaymentsAll =>
      '${EnvConfig.baseUrl}/api/payments/admin/all';
  static String get adminPaymentStatsAdmin =>
      '${EnvConfig.baseUrl}/api/payments/admin/stats';
  static String get adminPaymentCourses =>
      '${EnvConfig.baseUrl}/api/payments/admin/courses';
  static String get adminPaymentPricing =>
      '${EnvConfig.baseUrl}/api/payments/admin/pricing';

  // ==================== EXAMS ====================
  // Admin routes
  static String get adminExamsAll => '${EnvConfig.baseUrl}/api/exams/admin/all';
  static String get adminCreateExam =>
      '${EnvConfig.baseUrl}/api/exams/admin/create';
  static String adminUpdateExam(String examId) =>
      '${EnvConfig.baseUrl}/api/exams/admin/$examId/update';
  static String adminDeleteExam(String examId) =>
      '${EnvConfig.baseUrl}/api/exams/admin/$examId/delete';
  static String adminExamRegistrations(String examId) =>
      '${EnvConfig.baseUrl}/api/exams/admin/$examId/registrations';
  static String adminExamAttempts(String examId) =>
      '${EnvConfig.baseUrl}/api/exams/admin/$examId/attempts';
  static String adminApproveRetake(String examId, String studentId) =>
      '${EnvConfig.baseUrl}/api/exams/admin/$examId/$studentId/approve-retake';
  static String get adminMarkCompletedInactive =>
      '${EnvConfig.baseUrl}/api/exams/admin/mark-completed-inactive';
  static String get adminReactivateIncorrectlyInactive =>
      '${EnvConfig.baseUrl}/api/exams/admin/reactivate-incorrectly-inactive';

  // Student routes
  static String studentAvailableExams(String studentId) =>
      '${EnvConfig.baseUrl}/api/exams/available/$studentId';
  static String get studentExamResults =>
      '${EnvConfig.baseUrl}/api/exams/my-results';
  static String get examPaymentAttempt =>
      '${EnvConfig.baseUrl}/api/exams/payment-attempt';
  static String examPaymentAttempts(String examId) =>
      '${EnvConfig.baseUrl}/api/exams/$examId/payment-attempts';
  static String studentRegisterExam(String examId) =>
      '${EnvConfig.baseUrl}/api/exams/$examId/register';
  static String studentStartExam(String examId) =>
      '${EnvConfig.baseUrl}/api/exams/$examId/start';
  static String studentSaveAnswer(String examId) =>
      '${EnvConfig.baseUrl}/api/exams/$examId/save-answer';
  static String studentSubmitExam(String examId) =>
      '${EnvConfig.baseUrl}/api/exams/$examId/submit';
  static String studentExamQuestions(String examId) =>
      '${EnvConfig.baseUrl}/api/exams/$examId/questions';
  static String studentExamResultsById(String examId) =>
      '${EnvConfig.baseUrl}/api/exams/$examId/results';
  static String studentExamResultById(String examId) =>
      '${EnvConfig.baseUrl}/api/exams/$examId/result';

  // ==================== PLACEMENT ====================
  // Admin routes
  static String get adminPlacementQuestions =>
      '${EnvConfig.baseUrl}/api/placement/admin/questions';
  static String adminPlacementQuestionById(String id) =>
      '${EnvConfig.baseUrl}/api/placement/admin/questions/$id';
  static String get adminCreatePlacementQuestion =>
      '${EnvConfig.baseUrl}/api/placement/admin/questions';
  static String adminUpdatePlacementQuestion(String id) =>
      '${EnvConfig.baseUrl}/api/placement/admin/questions/$id';
  static String adminDeletePlacementQuestion(String id) =>
      '${EnvConfig.baseUrl}/api/placement/admin/questions/$id';
  static String get adminBulkUploadQuestions =>
      '${EnvConfig.baseUrl}/api/placement/admin/questions/bulk';
  static String get adminPlacementModules =>
      '${EnvConfig.baseUrl}/api/placement/admin/modules';
  static String adminPlacementModuleById(String id) =>
      '${EnvConfig.baseUrl}/api/placement/admin/modules/$id';
  static String get adminCreatePlacementModule =>
      '${EnvConfig.baseUrl}/api/placement/admin/modules';
  static String adminUpdatePlacementModule(String id) =>
      '${EnvConfig.baseUrl}/api/placement/admin/modules/$id';
  static String adminDeletePlacementModule(String id) =>
      '${EnvConfig.baseUrl}/api/placement/admin/modules/$id';
  static String get adminPlacementStats =>
      '${EnvConfig.baseUrl}/api/placement/admin/stats';

  // Student routes
  static String get studentPlacementModules =>
      '${EnvConfig.baseUrl}/api/placement/modules';
  static String studentPlacementModuleQuestions(String moduleId) =>
      '${EnvConfig.baseUrl}/api/placement/modules/$moduleId/questions';
  static String get studentPlacementProgress =>
      '${EnvConfig.baseUrl}/api/placement/progress';
  static String get studentUpdateModuleProgress =>
      '${EnvConfig.baseUrl}/api/placement/progress/module';
  static String get studentSubmitAnswer =>
      '${EnvConfig.baseUrl}/api/placement/submit-answer';
  static String get studentCreateMockInterview =>
      '${EnvConfig.baseUrl}/api/placement/mock-interview';
  static String get studentMockInterviews =>
      '${EnvConfig.baseUrl}/api/placement/mock-interviews';

  // ==================== JOBS ====================
  // Admin routes
  static String get adminJobsAll => '${EnvConfig.baseUrl}/api/jobs/admin/all';
  static String get adminCreateJob => '${EnvConfig.baseUrl}/api/jobs';
  static String adminUpdateJob(String id) =>
      '${EnvConfig.baseUrl}/api/jobs/$id';
  static String adminDeleteJob(String id) =>
      '${EnvConfig.baseUrl}/api/jobs/$id';
  static String adminUpdateJobStatus(String id) =>
      '${EnvConfig.baseUrl}/api/jobs/$id/status';

  // Public routes
  static String get jobs => '${EnvConfig.baseUrl}/api/jobs';
  static String jobById(String id) => '${EnvConfig.baseUrl}/api/jobs/$id';

  // Student routes
  static String studentApplyJob(String id) =>
      '${EnvConfig.baseUrl}/api/jobs/$id/apply';

  // ==================== OFFERS ===================
  // Admin routes
  static String get adminOffersStats =>
      '${EnvConfig.baseUrl}/api/offers/admin/stats';
  static String get adminOffersCourses =>
      '${EnvConfig.baseUrl}/api/offers/admin/courses';
  static String get adminOffersTegaExams =>
      '${EnvConfig.baseUrl}/api/offers/admin/tega-exams';
  static String get adminOffersInstitutes =>
      '${EnvConfig.baseUrl}/api/offers/admin/institutes';
  static String get adminOffers => '${EnvConfig.baseUrl}/api/offers/admin';
  static String adminOfferById(String id) =>
      '${EnvConfig.baseUrl}/api/offers/admin/$id';
  static String get adminCreateOffer => '${EnvConfig.baseUrl}/api/offers/admin';
  static String adminUpdateOffer(String id) =>
      '${EnvConfig.baseUrl}/api/offers/admin/$id';
  static String adminDeleteOffer(String id) =>
      '${EnvConfig.baseUrl}/api/offers/admin/$id';
  static String adminToggleOffer(String id) =>
      '${EnvConfig.baseUrl}/api/offers/admin/$id/toggle';

  // Public routes
  static String offersByInstitute(String instituteName) =>
      '${EnvConfig.baseUrl}/api/offers/institute/$instituteName';
  static String offersByInstituteCourse(
    String instituteName,
    String courseId,
  ) =>
      '${EnvConfig.baseUrl}/api/offers/institute/$instituteName/course/$courseId';
  static String offersByInstituteTegaExam(String instituteName) =>
      '${EnvConfig.baseUrl}/api/offers/institute/$instituteName/tega-exam';

  // ==================== RESUME ====================
  static String get resume => '${EnvConfig.baseUrl}/api/resume';
  static String get resumeTemplates =>
      '${EnvConfig.baseUrl}/api/resume/templates';
  static String resumeDownload(String templateName) =>
      '${EnvConfig.baseUrl}/api/resume/download/$templateName';
  static String get resumeUpload => '${EnvConfig.baseUrl}/api/resume/upload';

  // ==================== CERTIFICATES ====================
  static String get certificateGenerate =>
      '${EnvConfig.baseUrl}/api/certificates/generate';
  static String get studentCertificates =>
      '${EnvConfig.baseUrl}/api/certificates/my-certificates';
  static String certificateById(String certificateId) =>
      '${EnvConfig.baseUrl}/api/certificates/$certificateId';
  static String certificateDownload(String certificateId) =>
      '${EnvConfig.baseUrl}/api/certificates/$certificateId/download';
  static String certificateCourseCompletion(String courseId) =>
      '${EnvConfig.baseUrl}/api/certificates/course/$courseId/completion';
  static String certificateVerify(String verificationCode) =>
      '${EnvConfig.baseUrl}/api/certificates/verify/$verificationCode';
  static String get certificateSample =>
      '${EnvConfig.baseUrl}/api/certificates/sample/preview';

  // ==================== AI ASSISTANT ====================
  static String get aiAssistantChat =>
      '${EnvConfig.baseUrl}/api/ai-assistant/chat';
  static String get aiAssistantStatus =>
      '${EnvConfig.baseUrl}/api/ai-assistant/status';
  static String get aiAssistantConversations =>
      '${EnvConfig.baseUrl}/api/ai-assistant/conversations';
  static String aiAssistantDeleteConversation(String id) =>
      '${EnvConfig.baseUrl}/api/ai-assistant/conversations/$id';

  // ==================== CONTACT ====================
  static String get contactSubmit => '${EnvConfig.baseUrl}/api/contact/submit';
  static String get adminContactSubmissions =>
      '${EnvConfig.baseUrl}/api/contact/admin/submissions';
  static String get adminContactStats =>
      '${EnvConfig.baseUrl}/api/contact/admin/submissions/stats';
  static String adminContactSubmissionById(String id) =>
      '${EnvConfig.baseUrl}/api/contact/admin/submissions/$id';
  static String adminUpdateContactSubmission(String id) =>
      '${EnvConfig.baseUrl}/api/contact/admin/submissions/$id';
  static String adminDeleteContactSubmission(String id) =>
      '${EnvConfig.baseUrl}/api/contact/admin/submissions/$id';

  // ==================== ADMIN DASHBOARD ====================
  static String get adminDashboard =>
      '${EnvConfig.baseUrl}/api/admin/dashboard';
  static String get adminPrincipals =>
      '${EnvConfig.baseUrl}/api/admin/principals';
  static String adminPrincipalById(String id) =>
      '${EnvConfig.baseUrl}/api/admin/principals/$id';
  static String get adminRegisterPrincipal =>
      '${EnvConfig.baseUrl}/api/admin/register-principal';
  static String get adminStudents => '${EnvConfig.baseUrl}/api/admin/students';
  static String adminStudentById(String id) =>
      '${EnvConfig.baseUrl}/api/admin/students/$id';
  static String get adminCreateStudent =>
      '${EnvConfig.baseUrl}/api/admin/create-student';
  static String get adminBulkImportStudents =>
      '${EnvConfig.baseUrl}/api/admin/students/bulk-import';
  static String get adminNotifications =>
      '${EnvConfig.baseUrl}/api/admin/notifications';
  static String adminNotificationById(String id) =>
      '${EnvConfig.baseUrl}/api/admin/notifications/$id';
  static String get adminPayments => '${EnvConfig.baseUrl}/api/admin/payments';
  static String get adminCourses =>
      '${EnvConfig.baseUrl}/api/real-time-courses/admin';
  static String adminCourseById(String id) =>
      '${EnvConfig.baseUrl}/api/real-time-courses/$id';
  static String get adminUPISettings =>
      '${EnvConfig.baseUrl}/api/admin/upi-settings';

  // ==================== ADMIN EXAM RESULTS ====================
  static String get adminExamResults =>
      '${EnvConfig.baseUrl}/api/admin/exam-results';
  static String get adminPublishExamResults =>
      '${EnvConfig.baseUrl}/api/admin/exam-results/publish';
  static String get adminUnpublishExamResults =>
      '${EnvConfig.baseUrl}/api/admin/exam-results/unpublish';
  static String adminStudentResultDetails(String attemptId) =>
      '${EnvConfig.baseUrl}/api/admin/exam-results/student/$attemptId';
  static String get adminPublishAllResultsForDate =>
      '${EnvConfig.baseUrl}/api/admin/exam-results/publish-all-date';

  // ==================== HEALTH & TEST ====================
  static String get health => '${EnvConfig.baseUrl}/api/health';
  static String get test => '${EnvConfig.baseUrl}/api/test';

  // ==================== VIDEO ACCESS ====================
  static String videoAccessUrl(String courseId, String lectureId) =>
      '${EnvConfig.baseUrl}/api/video-access/$courseId/$lectureId/url';
  static String videoAccessSignedUrl(String courseId, String lectureId) =>
      '${EnvConfig.baseUrl}/api/video-access/$courseId/$lectureId/signed-url';
  static String videoAccessStatus(String courseId, String lectureId) =>
      '${EnvConfig.baseUrl}/api/video-access/$courseId/$lectureId/status';

  // ==================== VIDEO DELIVERY ====================
  static String videoDeliverySignedUrl(String courseId, String lectureId) =>
      '${EnvConfig.baseUrl}/api/video-delivery/$courseId/$lectureId/signed-url';
  static String videoDeliveryBatchSignedUrls(String courseId) =>
      '${EnvConfig.baseUrl}/api/video-delivery/$courseId/batch-signed-urls';
  static String get videoDeliveryClearCache =>
      '${EnvConfig.baseUrl}/api/video-delivery/clear-cache';

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
