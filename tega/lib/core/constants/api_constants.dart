import '../config/env_config.dart';

/// Production-ready API endpoints for TEGA Flutter app
///
/// This class contains all API endpoints organized by feature modules.
/// All endpoints are validated against the actual backend implementation.
class ApiEndpoints {
  // ==================== AUTHENTICATION ====================
  static String get register => '${EnvConfig.baseUrl}/api/api/auth/register';
  static String get login => '${EnvConfig.baseUrl}/api/api/auth/login';
  static String get logout => '${EnvConfig.baseUrl}/api/api/auth/logout';
  static String get verifyAuth => '${EnvConfig.baseUrl}/api/api/auth/verify';
  static String get refreshToken => '${EnvConfig.baseUrl}/api/api/auth/refresh';
  static String get csrfToken => '${EnvConfig.baseUrl}/api/api/auth/csrf-token';
  static String get forgotPassword =>
      '${EnvConfig.baseUrl}/api/api/auth/forgot-password';
  static String get verifyOTP => '${EnvConfig.baseUrl}/api/api/auth/verify-otp';
  static String get resetPassword =>
      '${EnvConfig.baseUrl}/api/api/auth/reset-password';
  static String get changePassword =>
      '${EnvConfig.baseUrl}/api/api/auth/change-password';
  static String get sendRegistrationOTP =>
      '${EnvConfig.baseUrl}/api/api/auth/register/send-otp';
  static String get verifyRegistrationOTP =>
      '${EnvConfig.baseUrl}/api/api/auth/register/verify-otp';
  static String get checkEmail =>
      '${EnvConfig.baseUrl}/api/api/auth/check-email';
  static String get authTest => '${EnvConfig.baseUrl}/api/api/auth/test';

  // ==================== STUDENT DASHBOARD & PROFILE ====================
  static String get studentDashboard =>
      '${EnvConfig.baseUrl}/api/api/student/dashboard';
  static String get studentSidebarCounts =>
      '${EnvConfig.baseUrl}/api/api/student/sidebar-counts';
  static String get studentProfile => '${EnvConfig.baseUrl}/student/profile';
  static String get studentNotifications =>
      '${EnvConfig.baseUrl}/api/api/student/notifications';
  static String get studentMarkNotificationsRead =>
      '${EnvConfig.baseUrl}/api/api/student/notifications/mark-read';
  static String get studentUploadPhoto =>
      '${EnvConfig.baseUrl}/api/api/student/profile/photo';
  static String get studentRemovePhoto =>
      '${EnvConfig.baseUrl}/api/api/student/profile/photo';

  // ==================== PRINCIPAL PORTAL ====================
  static String get principalLogin =>
      '${EnvConfig.baseUrl}/api/api/principal/login';
  static String get principalForgotPassword =>
      '${EnvConfig.baseUrl}/api/api/principal/forgot-password';
  static String get principalResetPassword =>
      '${EnvConfig.baseUrl}/api/api/principal/reset-password';
  static String get principalDashboard =>
      '${EnvConfig.baseUrl}/api/api/principal/dashboard';
  static String get principalStudents =>
      '${EnvConfig.baseUrl}/api/api/principal/students';

  // ==================== REAL-TIME COURSES ====================
  // Public routes
  static String get realTimeCourses =>
      '${EnvConfig.baseUrl}/api/api/real-time-courses';
  static String realTimeCourseById(String id) =>
      '${EnvConfig.baseUrl}/api/api/real-time-courses/$id';
  static String realTimeCourseContent(String id) =>
      '${EnvConfig.baseUrl}/api/api/real-time-courses/$id/content';

  // Student routes (protected)
  static String realTimeCourseEnrollmentStatus(String id) =>
      '${EnvConfig.baseUrl}/api/api/real-time-courses/$id/enrollment-status';
  static String realTimeCourseEnroll(String id) =>
      '${EnvConfig.baseUrl}/api/api/real-time-courses/$id/enroll';
  static String realTimeCourseLectureProgress(
    String courseId,
    String lectureId,
  ) =>
      '${EnvConfig.baseUrl}/api/api/real-time-courses/$courseId/lectures/$lectureId/progress';
  static String realTimeCourseLectureDuration(
    String courseId,
    String lectureId,
  ) =>
      '${EnvConfig.baseUrl}/api/api/real-time-courses/$courseId/lectures/$lectureId/duration';
  static String realTimeCourseQuizSubmit(String courseId, String lectureId) =>
      '${EnvConfig.baseUrl}/api/api/real-time-courses/$courseId/lectures/$lectureId/quiz';
  static String realTimeCourseHeartbeat(String id) =>
      '${EnvConfig.baseUrl}/api/api/real-time-courses/$id/heartbeat';
  static String realTimeCourseProgress(String id) =>
      '${EnvConfig.baseUrl}/api/api/real-time-courses/$id/progress';

  // Admin routes
  static String get adminRealTimeCourses =>
      '${EnvConfig.baseUrl}/api/api/real-time-courses/admin';
  static String get adminRealTimeCoursesAll =>
      '${EnvConfig.baseUrl}/api/api/real-time-courses/admin/all';
  static String get adminCreateRealTimeCourse =>
      '${EnvConfig.baseUrl}/api/api/real-time-courses';
  static String adminUpdateRealTimeCourse(String id) =>
      '${EnvConfig.baseUrl}/api/api/real-time-courses/$id';
  static String adminDeleteRealTimeCourse(String id) =>
      '${EnvConfig.baseUrl}/api/api/real-time-courses/$id';
  static String adminPublishRealTimeCourse(String id) =>
      '${EnvConfig.baseUrl}/api/api/real-time-courses/$id/publish';
  static String adminRealTimeCourseAnalytics(String id) =>
      '${EnvConfig.baseUrl}/api/api/real-time-courses/$id/analytics';

  // ==================== ENROLLMENTS ====================
  static String get studentEnrollments =>
      '${EnvConfig.baseUrl}/api/api/enrollments/student/enrollments';
  static String enrollmentCheck(String courseId) =>
      '${EnvConfig.baseUrl}/api/api/enrollments/check/$courseId';
  static String enrollmentCheckPost(String courseId) =>
      '${EnvConfig.baseUrl}/api/api/enrollments/check/$courseId';
  static String enrollInCourse(String courseId) =>
      '${EnvConfig.baseUrl}/api/api/enrollments/$courseId/enroll';
  static String enrollmentCheckAlt(String courseId) =>
      '${EnvConfig.baseUrl}/api/api/enrollments/$courseId/check';
  static String enrollmentLectureAccess(String courseId, String lectureId) =>
      '${EnvConfig.baseUrl}/api/api/enrollments/$courseId/lectures/$lectureId/access';
  static String unenrollFromCourse(String courseId) =>
      '${EnvConfig.baseUrl}/api/api/enrollments/$courseId/unenroll';
  static String get enrollments => '${EnvConfig.baseUrl}/enrollments';
  static String get completedEnrollments =>
      '${EnvConfig.baseUrl}/api/api/enrollments/completed';

  // ==================== PAYMENTS ====================
  // Public routes
  static String get paymentCourses =>
      '${EnvConfig.baseUrl}/api/api/payments/courses';
  static String get paymentPricing =>
      '${EnvConfig.baseUrl}/api/api/payments/pricing';

  // Protected routes
  static String get paymentCreateOrder =>
      '${EnvConfig.baseUrl}/api/api/payments/create-order';
  static String get paymentProcessDummy =>
      '${EnvConfig.baseUrl}/api/api/payments/process-dummy';
  static String get paymentVerify => '${EnvConfig.baseUrl}/payments/verify';
  static String get paymentUPIVerify =>
      '${EnvConfig.baseUrl}/api/api/payments/upi/verify';
  static String paymentUPIStatus(String transactionId) =>
      '${EnvConfig.baseUrl}/api/api/payments/upi/status/$transactionId';
  static String get paymentHistory => '${EnvConfig.baseUrl}/payments/history';
  static String paymentCourseAccess(String courseId) =>
      '${EnvConfig.baseUrl}/api/api/payments/access/$courseId';
  static String get paymentPaidCourses =>
      '${EnvConfig.baseUrl}/api/api/payments/paid-courses';
  static String paymentOfferPrice(String studentId, [String? feature]) =>
      '${EnvConfig.baseUrl}/api/api/payments/offer-price/$studentId${feature != null ? '/$feature' : ''}';
  static String paymentReceipt(String transactionId) =>
      '${EnvConfig.baseUrl}/api/api/payments/receipt/$transactionId';
  static String get paymentRefund =>
      '${EnvConfig.baseUrl}/api/api/payments/refund';

  // Admin routes
  static String get adminPaymentStats =>
      '${EnvConfig.baseUrl}/api/api/payments/stats';
  static String get adminPaymentsAll =>
      '${EnvConfig.baseUrl}/api/api/payments/admin/all';
  static String get adminPaymentStatsAdmin =>
      '${EnvConfig.baseUrl}/api/api/payments/admin/stats';
  static String get adminPaymentCourses =>
      '${EnvConfig.baseUrl}/api/api/payments/admin/courses';
  static String get adminPaymentPricing =>
      '${EnvConfig.baseUrl}/api/api/payments/admin/pricing';

  // ==================== RAZORPAY PAYMENT ====================
  static String get razorpayCreateOrder =>
      '${EnvConfig.baseUrl}/api/api/razorpay/create-order';
  static String get razorpayVerifyPayment =>
      '${EnvConfig.baseUrl}/api/api/razorpay/verify-payment';
  static String razorpayOrderStatus(String orderId) =>
      '${EnvConfig.baseUrl}/api/api/razorpay/status/$orderId';
  static String get razorpayPaymentHistory =>
      '${EnvConfig.baseUrl}/api/api/razorpay/history';
  static String get razorpayWebhook =>
      '${EnvConfig.baseUrl}/api/api/razorpay/webhook';

  // ==================== TEGA EXAM PAYMENTS ====================
  static String get tegaExamPaymentCreateOrder =>
      '${EnvConfig.baseUrl}/api/api/tega-exam-payments/create-order';
  static String get tegaExamPaymentProcessDummy =>
      '${EnvConfig.baseUrl}/api/api/tega-exam-payments/process-dummy';
  static String tegaExamPaymentCheck(String examId) =>
      '${EnvConfig.baseUrl}/api/api/tega-exam-payments/check/$examId';
  static String get tegaExamPaymentHistory =>
      '${EnvConfig.baseUrl}/api/api/tega-exam-payments/history';

  // ==================== EXAMS ====================
  // Admin routes
  static String get adminExamsAll =>
      '${EnvConfig.baseUrl}/api/api/exams/admin/all';
  static String get adminCreateExam =>
      '${EnvConfig.baseUrl}/api/api/exams/admin/create';
  static String adminUpdateExam(String examId) =>
      '${EnvConfig.baseUrl}/api/api/exams/admin/$examId/update';
  static String adminDeleteExam(String examId) =>
      '${EnvConfig.baseUrl}/api/api/exams/admin/$examId/delete';
  static String adminExamRegistrations(String examId) =>
      '${EnvConfig.baseUrl}/api/api/exams/admin/$examId/registrations';
  static String adminExamAttempts(String examId) =>
      '${EnvConfig.baseUrl}/api/api/exams/admin/$examId/attempts';
  static String adminApproveRetake(String examId, String studentId) =>
      '${EnvConfig.baseUrl}/api/api/exams/admin/$examId/$studentId/approve-retake';
  static String get adminMarkCompletedInactive =>
      '${EnvConfig.baseUrl}/api/api/exams/admin/mark-completed-inactive';
  static String get adminReactivateIncorrectlyInactive =>
      '${EnvConfig.baseUrl}/api/api/exams/admin/reactivate-incorrectly-inactive';

  // Student routes
  static String studentAvailableExams(String studentId) =>
      '${EnvConfig.baseUrl}/api/api/exams/available/$studentId';
  static String get studentExamResults =>
      '${EnvConfig.baseUrl}/api/api/exams/my-results';
  static String get examPaymentAttempt =>
      '${EnvConfig.baseUrl}/api/api/exams/payment-attempt';
  static String examPaymentAttempts(String examId) =>
      '${EnvConfig.baseUrl}/api/api/exams/$examId/payment-attempts';
  static String studentRegisterExam(String examId) =>
      '${EnvConfig.baseUrl}/api/api/exams/$examId/register';
  static String studentStartExam(String examId) =>
      '${EnvConfig.baseUrl}/api/api/exams/$examId/start';
  static String studentSaveAnswer(String examId) =>
      '${EnvConfig.baseUrl}/api/api/exams/$examId/save-answer';
  static String studentSubmitExam(String examId) =>
      '${EnvConfig.baseUrl}/api/api/exams/$examId/submit';
  static String studentExamQuestions(String examId) =>
      '${EnvConfig.baseUrl}/api/api/exams/$examId/questions';
  static String studentExamResultsById(String examId) =>
      '${EnvConfig.baseUrl}/api/api/exams/$examId/results';
  static String studentExamResultById(String examId) =>
      '${EnvConfig.baseUrl}/api/api/exams/$examId/result';

  // ==================== QUESTION PAPERS ====================
  // Admin routes
  static String get adminQuestionPapersAll =>
      '${EnvConfig.baseUrl}/api/api/question-papers/admin/all';
  static String adminQuestionPapersByCourse(String courseId) =>
      '${EnvConfig.baseUrl}/api/api/question-papers/admin/course/$courseId';
  static String get adminQuestionPaperUpload =>
      '${EnvConfig.baseUrl}/api/api/question-papers/admin/upload';
  static String adminQuestionPaperDelete(String id) =>
      '${EnvConfig.baseUrl}/api/api/question-papers/admin/$id';
  static String get adminQuestionPaperTemplate =>
      '${EnvConfig.baseUrl}/api/api/question-papers/admin/template';
  static String adminQuestionPaperDetails(String id) =>
      '${EnvConfig.baseUrl}/api/api/question-papers/admin/$id';

  // ==================== COMPANY QUESTIONS ====================
  // Admin routes - PDF Upload & Processing
  static String get adminCompanyQuestionsUploadPDF =>
      '${EnvConfig.baseUrl}/api/api/company-questions/admin/upload-pdf';
  static String get adminCompanyQuestionsSave =>
      '${EnvConfig.baseUrl}/api/api/company-questions/admin/save-questions';

  // Admin routes - CRUD Operations
  static String get adminCompanyQuestionsCreate =>
      '${EnvConfig.baseUrl}/api/api/company-questions/admin/questions';
  static String get adminCompanyQuestionsAll =>
      '${EnvConfig.baseUrl}/api/api/company-questions/admin/questions';
  static String adminCompanyQuestionUpdate(String id) =>
      '${EnvConfig.baseUrl}/api/api/company-questions/admin/questions/$id';
  static String adminCompanyQuestionDelete(String id) =>
      '${EnvConfig.baseUrl}/api/api/company-questions/admin/questions/$id';

  // Admin routes - Company List
  static String get adminCompanyList =>
      '${EnvConfig.baseUrl}/api/api/company-questions/admin/companies';

  // Student routes - Company Questions
  static String get companyQuestionsList =>
      '${EnvConfig.baseUrl}/api/api/company-questions/companies';
  static String companyQuestions(String companyName) =>
      '${EnvConfig.baseUrl}/api/api/company-questions/companies/$companyName/questions';

  // Student routes - Quiz Operations
  static String get companyQuizStart =>
      '${EnvConfig.baseUrl}/api/api/company-questions/quiz/start';
  static String get companyQuizSubmitAnswer =>
      '${EnvConfig.baseUrl}/api/api/company-questions/quiz/submit-answer';
  static String get companyQuizSubmit =>
      '${EnvConfig.baseUrl}/api/api/company-questions/quiz/submit';

  // Student routes - Progress & Leaderboard
  static String companyProgress(String companyName) =>
      '${EnvConfig.baseUrl}/api/api/company-questions/progress/$companyName';
  static String companyLeaderboard(String companyName) =>
      '${EnvConfig.baseUrl}/api/api/company-questions/leaderboard/$companyName';

  // ==================== PLACEMENT ====================
  // Admin routes - Questions
  static String get adminPlacementQuestions =>
      '${EnvConfig.baseUrl}/api/api/placement/admin/questions';
  static String adminPlacementQuestionById(String id) =>
      '${EnvConfig.baseUrl}/api/api/placement/admin/questions/$id';
  static String get adminCreatePlacementQuestion =>
      '${EnvConfig.baseUrl}/api/api/placement/admin/questions';
  static String adminUpdatePlacementQuestion(String id) =>
      '${EnvConfig.baseUrl}/api/api/placement/admin/questions/$id';
  static String adminDeletePlacementQuestion(String id) =>
      '${EnvConfig.baseUrl}/api/api/placement/admin/questions/$id';
  static String get adminBulkUploadQuestions =>
      '${EnvConfig.baseUrl}/api/api/placement/admin/questions/bulk';

  // Admin routes - Modules
  static String get adminPlacementModules =>
      '${EnvConfig.baseUrl}/api/api/placement/admin/modules';
  static String adminPlacementModuleById(String id) =>
      '${EnvConfig.baseUrl}/api/api/placement/admin/modules/$id';
  static String get adminCreatePlacementModule =>
      '${EnvConfig.baseUrl}/api/api/placement/admin/modules';
  static String adminUpdatePlacementModule(String id) =>
      '${EnvConfig.baseUrl}/api/api/placement/admin/modules/$id';
  static String adminDeletePlacementModule(String id) =>
      '${EnvConfig.baseUrl}/api/api/placement/admin/modules/$id';

  // Admin routes - Statistics
  static String get adminPlacementStats =>
      '${EnvConfig.baseUrl}/api/api/placement/admin/stats';

  // Student routes - Modules
  static String get studentPlacementModules =>
      '${EnvConfig.baseUrl}/api/api/placement/modules';
  static String studentPlacementModuleQuestions(String moduleId) =>
      '${EnvConfig.baseUrl}/api/api/placement/modules/$moduleId/questions';

  // Student routes - Progress
  static String get studentPlacementProgress =>
      '${EnvConfig.baseUrl}/api/api/placement/progress';
  static String get studentUpdateModuleProgress =>
      '${EnvConfig.baseUrl}/api/api/placement/progress/module';

  // Student routes - Answers & Interviews
  static String get studentSubmitAnswer =>
      '${EnvConfig.baseUrl}/api/api/placement/submit-answer';
  static String get studentCreateMockInterview =>
      '${EnvConfig.baseUrl}/api/api/placement/mock-interview';
  static String get studentMockInterviews =>
      '${EnvConfig.baseUrl}/api/api/placement/mock-interviews';

  // ==================== COMPANY QUESTIONS ====================
  static String get companyList =>
      '${EnvConfig.baseUrl}/api/api/company-questions/companies';
  static String companyQuestionsV2(String companyName) =>
      '${EnvConfig.baseUrl}/api/api/company-questions/companies/$companyName/questions';

  // ==================== JOBS ====================
  // Admin routes
  static String get adminJobsAll =>
      '${EnvConfig.baseUrl}/api/api/jobs/admin/all';
  static String get adminCreateJob => '${EnvConfig.baseUrl}/api/api/jobs';
  static String adminUpdateJob(String id) =>
      '${EnvConfig.baseUrl}/api/api/jobs/$id';
  static String adminDeleteJob(String id) =>
      '${EnvConfig.baseUrl}/api/api/jobs/$id';
  static String adminUpdateJobStatus(String id) =>
      '${EnvConfig.baseUrl}/api/api/jobs/$id/status';

  // Public routes
  static String get jobs => '${EnvConfig.baseUrl}/api/api/jobs';
  static String jobById(String id) => '${EnvConfig.baseUrl}/api/api/jobs/$id';

  // Student routes
  static String studentApplyJob(String id) =>
      '${EnvConfig.baseUrl}/api/api/jobs/$id/apply';

  // ==================== OFFERS ====================
  // Admin routes - Statistics & Resources
  static String get adminOffersStats =>
      '${EnvConfig.baseUrl}/api/api/offers/admin/stats';
  static String get adminOffersCourses =>
      '${EnvConfig.baseUrl}/api/api/offers/admin/courses';
  static String get adminOffersTegaExams =>
      '${EnvConfig.baseUrl}/api/api/offers/admin/tega-exams';
  static String get adminOffersInstitutes =>
      '${EnvConfig.baseUrl}/api/api/offers/admin/institutes';

  // Admin routes - CRUD Operations
  static String get adminOffers =>
      '${EnvConfig.baseUrl}/api/api/offers/admin/all';
  static String adminOfferById(String id) =>
      '${EnvConfig.baseUrl}/api/api/offers/admin/$id';
  static String get adminCreateOffer =>
      '${EnvConfig.baseUrl}/api/api/offers/admin';
  static String adminUpdateOffer(String id) =>
      '${EnvConfig.baseUrl}/api/api/offers/admin/$id';
  static String adminDeleteOffer(String id) =>
      '${EnvConfig.baseUrl}/api/api/offers/admin/$id';
  static String adminToggleOffer(String id) =>
      '${EnvConfig.baseUrl}/api/api/offers/admin/$id/toggle';

  // Public routes
  static String offersByInstitute(String instituteName) =>
      '${EnvConfig.baseUrl}/api/api/offers/institute/$instituteName';
  static String offersByInstituteCourse(
    String instituteName,
    String courseId,
  ) =>
      '${EnvConfig.baseUrl}/api/api/offers/institute/$instituteName/course/$courseId';
  static String offersByInstituteTegaExam(String instituteName) =>
      '${EnvConfig.baseUrl}/api/api/offers/institute/$instituteName/tega-exam';

  // ==================== RESUME ====================
  static String get resume => '${EnvConfig.baseUrl}/api/api/resume';
  static String get resumeTemplates =>
      '${EnvConfig.baseUrl}/api/api/resume/templates';
  static String resumeDownload(String templateName) =>
      '${EnvConfig.baseUrl}/api/api/resume/download/$templateName';
  static String get resumeUpload =>
      '${EnvConfig.baseUrl}/api/api/resume/upload';

  // ==================== CERTIFICATES ====================
  static String get certificateGenerate =>
      '${EnvConfig.baseUrl}/api/api/certificates/generate';
  static String get studentCertificates =>
      '${EnvConfig.baseUrl}/api/api/certificates/my-certificates';
  static String certificateById(String certificateId) =>
      '${EnvConfig.baseUrl}/api/api/certificates/$certificateId';
  static String certificateDownload(String certificateId) =>
      '${EnvConfig.baseUrl}/api/api/certificates/$certificateId/download';
  static String certificateCourseCompletion(String courseId) =>
      '${EnvConfig.baseUrl}/api/api/certificates/course/$courseId/completion';
  static String certificateVerify(String verificationCode) =>
      '${EnvConfig.baseUrl}/api/api/certificates/verify/$verificationCode';
  static String get certificateSample =>
      '${EnvConfig.baseUrl}/api/api/certificates/sample/preview';

  // ==================== AI ASSISTANT ====================
  static String get aiAssistantChat =>
      '${EnvConfig.baseUrl}/api/api/ai-assistant/chat';
  static String get aiAssistantStatus =>
      '${EnvConfig.baseUrl}/api/api/ai-assistant/status';
  static String get aiAssistantDebug =>
      '${EnvConfig.baseUrl}/api/api/ai-assistant/debug';
  static String get aiAssistantConversations =>
      '${EnvConfig.baseUrl}/api/api/ai-assistant/conversations';
  static String aiAssistantConversationById(String id) =>
      '${EnvConfig.baseUrl}/api/api/ai-assistant/conversations/$id';
  static String aiAssistantDeleteConversation(String id) =>
      '${EnvConfig.baseUrl}/api/api/ai-assistant/conversations/$id';

  // ==================== CHATBOT ====================
  static String get chatbotMessage =>
      '${EnvConfig.baseUrl}/api/api/chatbot/message';
  static String get chatbotStatus =>
      '${EnvConfig.baseUrl}/api/api/chatbot/status';
  static String get chatbotQuickReplies =>
      '${EnvConfig.baseUrl}/api/api/chatbot/quick-replies';

  // ==================== CONTACT ====================
  static String get contactSubmit =>
      '${EnvConfig.baseUrl}/api/api/contact/submit';
  static String get adminContactSubmissions =>
      '${EnvConfig.baseUrl}/api/api/contact/admin/submissions';
  static String get adminContactStats =>
      '${EnvConfig.baseUrl}/api/api/contact/admin/submissions/stats';
  static String adminContactSubmissionById(String id) =>
      '${EnvConfig.baseUrl}/api/api/contact/admin/submissions/$id';
  static String adminUpdateContactSubmission(String id) =>
      '${EnvConfig.baseUrl}/api/api/contact/admin/submissions/$id';
  static String adminDeleteContactSubmission(String id) =>
      '${EnvConfig.baseUrl}/api/api/contact/admin/submissions/$id';

  // ==================== NOTIFICATIONS ====================
  // Admin notifications
  static String get adminNotificationsAll =>
      '${EnvConfig.baseUrl}/api/api/notifications/admin';
  static String get adminPaymentNotifications =>
      '${EnvConfig.baseUrl}/api/api/notifications/admin/payments';
  static String adminNotificationMarkRead(String id) =>
      '${EnvConfig.baseUrl}/api/api/notifications/admin/$id/read';
  static String get adminNotificationMarkAllRead =>
      '${EnvConfig.baseUrl}/api/api/notifications/admin/mark-all-read';

  // User/Student notifications
  static String get userNotifications =>
      '${EnvConfig.baseUrl}/api/api/notifications/user';
  static String userNotificationMarkRead(String id) =>
      '${EnvConfig.baseUrl}/api/api/notifications/user/$id/read';
  static String userNotificationDelete(String id) =>
      '${EnvConfig.baseUrl}/api/api/notifications/user/$id';
  static String get userNotificationCreate =>
      '${EnvConfig.baseUrl}/api/api/notifications/user';

  // ==================== ADMIN DASHBOARD ====================
  static String get adminDashboard =>
      '${EnvConfig.baseUrl}/api/api/admin/dashboard';

  // Admin - Principals Management
  static String get adminPrincipals =>
      '${EnvConfig.baseUrl}/api/api/admin/principals';
  static String adminPrincipalById(String id) =>
      '${EnvConfig.baseUrl}/api/api/admin/principals/$id';
  static String get adminRegisterPrincipal =>
      '${EnvConfig.baseUrl}/api/api/admin/register-principal';
  static String get adminBulkImportPrincipals =>
      '${EnvConfig.baseUrl}/api/api/admin/principals/bulk-import';
  static String adminPrincipalTest(String id) =>
      '${EnvConfig.baseUrl}/api/api/admin/principals/test/$id';

  // Admin - Students Management
  static String get adminStudents =>
      '${EnvConfig.baseUrl}/api/api/admin/students';
  static String adminStudentsByCollege(String collegeName) =>
      '${EnvConfig.baseUrl}/api/api/admin/students/college/$collegeName';
  static String adminStudentById(String id) =>
      '${EnvConfig.baseUrl}/api/api/admin/students/$id';
  static String get adminCreateStudent =>
      '${EnvConfig.baseUrl}/api/api/admin/create-student';
  static String get adminBulkImportStudents =>
      '${EnvConfig.baseUrl}/api/api/admin/students/bulk-import';
  static String get adminBulkImport =>
      '${EnvConfig.baseUrl}/api/api/admin/bulk-import';

  // Admin - Users Management (generic)
  static String adminUserById(String userId) =>
      '${EnvConfig.baseUrl}/api/api/admin/users/$userId';

  // Admin - Notifications & Payments
  static String get adminNotifications =>
      '${EnvConfig.baseUrl}/api/api/admin/notifications';
  static String adminNotificationById(String id) =>
      '${EnvConfig.baseUrl}/api/api/admin/notifications/$id';
  static String get adminPaymentNotificationsList =>
      '${EnvConfig.baseUrl}/api/api/admin/payment-notifications';
  static String get adminPayments =>
      '${EnvConfig.baseUrl}/api/api/admin/payments';

  // Admin - Courses Management
  static String get adminCourses =>
      '${EnvConfig.baseUrl}/api/api/admin/courses';
  static String adminCourseById(String id) =>
      '${EnvConfig.baseUrl}/api/api/admin/courses/$id';

  // Admin - UPI Settings
  static String get adminUPISettings =>
      '${EnvConfig.baseUrl}/api/api/admin/upi-settings';
  static String get adminUPISettingsUpdate =>
      '${EnvConfig.baseUrl}/api/api/admin/upi-settings';

  // ==================== ADMIN EXAM RESULTS ====================
  static String get adminExamResults =>
      '${EnvConfig.baseUrl}/api/api/admin/exam-results/results';
  static String get adminPublishExamResults =>
      '${EnvConfig.baseUrl}/api/api/admin/exam-results/publish';
  static String get adminUnpublishExamResults =>
      '${EnvConfig.baseUrl}/api/api/admin/exam-results/unpublish';
  static String adminStudentResultDetails(String attemptId) =>
      '${EnvConfig.baseUrl}/api/api/admin/exam-results/result/$attemptId';
  static String get adminPublishAllResultsForDate =>
      '${EnvConfig.baseUrl}/api/api/admin/exam-results/publish-all-date';

  // ==================== R2 CLOUD STORAGE ====================
  // Admin routes - Video uploads
  static String get r2GenerateVideoUploadUrl =>
      '${EnvConfig.baseUrl}/api/api/r2/generate-video-upload-url';
  static String get r2ConfirmVideoUpload =>
      '${EnvConfig.baseUrl}/api/api/r2/confirm-video-upload';

  // Admin routes - Document uploads
  static String get r2GenerateDocumentUploadUrl =>
      '${EnvConfig.baseUrl}/api/api/r2/generate-document-upload-url';
  static String get r2ConfirmDocumentUpload =>
      '${EnvConfig.baseUrl}/api/api/r2/confirm-document-upload';
  static String get r2UploadMaterial =>
      '${EnvConfig.baseUrl}/api/api/r2/upload-material';

  // Admin routes - Material management
  static String r2DeleteMaterial(String materialId) =>
      '${EnvConfig.baseUrl}/api/api/r2/material/$materialId';

  // Public/Student routes - Material access
  static String r2MaterialsByCourse(String courseId) =>
      '${EnvConfig.baseUrl}/api/api/r2/materials/course/$courseId';
  static String r2MaterialsByLecture(String lectureId) =>
      '${EnvConfig.baseUrl}/api/api/r2/materials/lecture/$lectureId';
  static String r2MaterialDownload(String materialId) =>
      '${EnvConfig.baseUrl}/api/api/r2/material/$materialId/download';

  // ==================== IMAGE UPLOADS ====================
  static String get imageUpload => '${EnvConfig.baseUrl}/api/api/images/upload';
  static String get imageUploadMultiple =>
      '${EnvConfig.baseUrl}/api/api/images/upload-multiple';
  static String imageDelete(String filename) =>
      '${EnvConfig.baseUrl}/api/api/images/delete/$filename';

  // ==================== VIDEO ACCESS ====================
  static String videoAccessUrl(String courseId, String lectureId) =>
      '${EnvConfig.baseUrl}/api/api/video-access/$courseId/$lectureId/url';
  static String videoAccessSignedUrl(String courseId, String lectureId) =>
      '${EnvConfig.baseUrl}/api/api/video-access/$courseId/$lectureId/signed-url';
  static String videoAccessStatus(String courseId, String lectureId) =>
      '${EnvConfig.baseUrl}/api/api/video-access/$courseId/$lectureId/status';

  // ==================== VIDEO DELIVERY (SCALABLE) ====================
  static String videoDeliverySignedUrl(String courseId, String lectureId) =>
      '${EnvConfig.baseUrl}/api/api/video-delivery/$courseId/$lectureId/signed-url';
  static String videoDeliveryBatchSignedUrls(String courseId) =>
      '${EnvConfig.baseUrl}/api/api/video-delivery/$courseId/batch-signed-urls';
  static String get videoDeliveryClearCache =>
      '${EnvConfig.baseUrl}/api/api/video-delivery/clear-cache';

  // ==================== ANNOUNCEMENTS ====================
  // Principal routes for announcements
  static String get principalAnnouncements =>
      '${EnvConfig.baseUrl}/api/api/principal/announcements';
  static String principalAnnouncementById(String id) =>
      '${EnvConfig.baseUrl}/api/api/principal/announcements/$id';
  static String get principalCreateAnnouncement =>
      '${EnvConfig.baseUrl}/api/api/principal/announcements';
  static String principalUpdateAnnouncement(String id) =>
      '${EnvConfig.baseUrl}/api/api/principal/announcements/$id';
  static String principalDeleteAnnouncement(String id) =>
      '${EnvConfig.baseUrl}/api/api/principal/announcements/$id';

  // ==================== QUIZ ====================
  // Admin routes
  static String get adminQuizParseExcel =>
      '${EnvConfig.baseUrl}/api/api/admin/quiz/parse-excel';
  static String get adminQuizUpload =>
      '${EnvConfig.baseUrl}/api/api/admin/quiz/upload';
  static String adminQuizById(String quizId) =>
      '${EnvConfig.baseUrl}/api/api/admin/quiz/$quizId';
  static String adminQuizAnalytics(String quizId) =>
      '${EnvConfig.baseUrl}/api/api/admin/quiz/$quizId/analytics';

  // Student routes
  static String studentQuizStatus(String quizId) =>
      '${EnvConfig.baseUrl}/api/api/student/quiz/$quizId/status';
  static String studentQuizBestAttempt(String quizId) =>
      '${EnvConfig.baseUrl}/api/api/student/quiz/$quizId/best-attempt';
  static String studentQuizAttempts(String quizId) =>
      '${EnvConfig.baseUrl}/api/api/student/quiz/$quizId/attempts';
  static String get studentQuizSubmit =>
      '${EnvConfig.baseUrl}/api/api/student/quiz/submit';
  static String studentQuizById(String quizId) =>
      '${EnvConfig.baseUrl}/api/api/student/quiz/$quizId';

  // ==================== CODE EXECUTION ====================
  static String get codeRun => '${EnvConfig.baseUrl}/api/api/code/run';
  static String get codeHistory => '${EnvConfig.baseUrl}/api/api/code/history';
  static String codeSubmission(String id) =>
      '${EnvConfig.baseUrl}/api/api/code/submission/$id';
  static String codeDeleteHistory(String id) =>
      '${EnvConfig.baseUrl}/api/api/code/history/$id';
  static String get codeStats => '${EnvConfig.baseUrl}/api/api/code/stats';
  static String get codeLanguages =>
      '${EnvConfig.baseUrl}/api/api/code/languages';
  static String get codeAuthTest =>
      '${EnvConfig.baseUrl}/api/api/code/auth-test';

  // ==================== CODE SNIPPETS ====================
  static String get codeSnippetsPublic =>
      '${EnvConfig.baseUrl}/api/api/code-snippets/public';
  static String get codeSnippets =>
      '${EnvConfig.baseUrl}/api/api/code-snippets';
  static String get codeSnippetsStats =>
      '${EnvConfig.baseUrl}/api/api/code-snippets/stats';
  static String codeSnippetById(String id) =>
      '${EnvConfig.baseUrl}/api/api/code-snippets/$id';
  static String codeSnippetFavorite(String id) =>
      '${EnvConfig.baseUrl}/api/api/code-snippets/$id/favorite';

  // ==================== PDF FEEDBACK ====================
  static String get pdfFeedbackTestAuth =>
      '${EnvConfig.baseUrl}/api/api/pdf-feedback/test-auth';
  static String get pdfFeedbackTestSimple =>
      '${EnvConfig.baseUrl}/api/api/pdf-feedback/test-simple';
  static String pdfFeedbackDebugAttempt(String attemptId) =>
      '${EnvConfig.baseUrl}/api/api/pdf-feedback/debug-attempt/$attemptId';
  static String pdfFeedbackExam(String attemptId) =>
      '${EnvConfig.baseUrl}/api/api/pdf-feedback/exam/$attemptId';
  static String pdfFeedbackExamV2(String attemptId) =>
      '${EnvConfig.baseUrl}/api/api/pdf-feedback/exam-v2/$attemptId';

  // ==================== MOCK INTERVIEWS ====================
  static String get mockInterviewStart =>
      '${EnvConfig.baseUrl}/api/api/interviews/start';
  static String get mockInterviewSubmitAnswer =>
      '${EnvConfig.baseUrl}/api/api/interviews/submit-answer';
  static String get mockInterviewSubmitCode =>
      '${EnvConfig.baseUrl}/api/api/interviews/submit-code';
  static String get mockInterviewComplete =>
      '${EnvConfig.baseUrl}/api/api/interviews/complete';
  static String mockInterviewStats(String userId) =>
      '${EnvConfig.baseUrl}/api/api/interviews/stats/$userId';
  static String get mockInterviewLeaderboard =>
      '${EnvConfig.baseUrl}/api/api/interviews/leaderboard';

  // ==================== STUDENT ANNOUNCEMENTS ====================
  static String get studentAnnouncements =>
      '${EnvConfig.baseUrl}/api/api/student/announcements';
  static String studentAnnouncementById(String id) =>
      '${EnvConfig.baseUrl}/api/api/student/announcements/$id';

  // ==================== STUDENT PROFILE DEBUG ====================
  static String get studentProfileDebug =>
      '${EnvConfig.baseUrl}/api/api/student/profile/debug';

  // ==================== EXAM ROUTES (Additional) ====================
  static String get studentExamsAll =>
      '${EnvConfig.baseUrl}/api/api/exams/student/all';
  static String examCheckAccess(String examId) =>
      '${EnvConfig.baseUrl}/api/api/exams/$examId/check-access';
  static String examRegistrations(String examId) =>
      '${EnvConfig.baseUrl}/api/api/exams/$examId/registrations';
  static String examById(String examId) =>
      '${EnvConfig.baseUrl}/api/api/exams/$examId';

  // ==================== PAYMENT ROUTES (Additional) ====================
  static String get paymentTegaExams =>
      '${EnvConfig.baseUrl}/api/api/payments/tega-exams';
  static String paymentCourseOffer(String studentId, String courseId) =>
      '${EnvConfig.baseUrl}/api/api/payments/course-offer/$studentId/$courseId';
  static String paymentTegaExamOffer(String studentId, String examId) =>
      '${EnvConfig.baseUrl}/api/api/payments/tega-exam-offer/$studentId/$examId';
  static String paymentExamPaidSlots(String examId) =>
      '${EnvConfig.baseUrl}/api/api/payments/exam/$examId/paid-slots';
  static String paymentSlotCheck(String examId, String slotId) =>
      '${EnvConfig.baseUrl}/api/api/payments/exam/$examId/slot/$slotId/check';
  static String get paymentCheckTegaExamPayment =>
      '${EnvConfig.baseUrl}/api/api/payments/check-tega-exam-payment';

  // ==================== PRINCIPAL ROUTES (Additional) ====================
  static String get principalPlacementReadiness =>
      '${EnvConfig.baseUrl}/api/api/principal/placement-readiness';
  static String get principalCourseEngagement =>
      '${EnvConfig.baseUrl}/api/api/principal/course-engagement';
  static String get principalAccountUpdate =>
      '${EnvConfig.baseUrl}/api/api/principal/account';
  static String get principalCollegeUpdate =>
      '${EnvConfig.baseUrl}/api/api/principal/college';
  static String get principalStudentsExport =>
      '${EnvConfig.baseUrl}/api/api/principal/students/export';
  static String get principalChangePassword =>
      '${EnvConfig.baseUrl}/api/api/principal/change-password';

  // ==================== ADMIN ROUTES (Additional) ====================
  static String adminPrincipalUpdate(String id) =>
      '${EnvConfig.baseUrl}/api/api/admin/principals/$id';
  static String adminPrincipalDelete(String id) =>
      '${EnvConfig.baseUrl}/api/api/admin/principals/$id';
  static String adminUserUpdate(String userId) =>
      '${EnvConfig.baseUrl}/api/api/admin/users/$userId';
  static String adminUserDelete(String userId) =>
      '${EnvConfig.baseUrl}/api/api/admin/users/$userId';

  // ==================== HEALTH & TEST ====================
  static String get health => '${EnvConfig.baseUrl}/api/api/health';
  static String get test => '${EnvConfig.baseUrl}/api/api/test';

  // ==================== STATIC FILE UPLOADS ====================
  static String uploadsPath(String filename) =>
      '${EnvConfig.baseUrl}/api/api/uploads/$filename';
  static String uploadsQuestionImages(String filename) =>
      '${EnvConfig.baseUrl}/api/api/uploads/question-images/$filename';
  static String uploadsResumes(String filename) =>
      '${EnvConfig.baseUrl}/api/api/uploads/resumes/$filename';
  static String uploadsPdfs(String filename) =>
      '${EnvConfig.baseUrl}/api/api/uploads/pdfs/$filename';
  static String uploadsExcel(String filename) =>
      '${EnvConfig.baseUrl}/api/api/uploads/excel/$filename';

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

  /// Build pagination URL
  static String buildPaginatedUrl(
    String baseUrl, {
    int page = 1,
    int limit = 10,
    Map<String, dynamic>? additionalParams,
  }) {
    final params = {
      'page': page,
      'limit': limit,
      if (additionalParams != null) ...additionalParams,
    };
    return buildUrlWithParams(baseUrl, params);
  }

  /// Build search URL
  static String buildSearchUrl(
    String baseUrl,
    String searchQuery, {
    Map<String, dynamic>? additionalParams,
  }) {
    final params = {
      'search': searchQuery,
      if (additionalParams != null) ...additionalParams,
    };
    return buildUrlWithParams(baseUrl, params);
  }
}
