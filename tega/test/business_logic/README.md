# Business Logic Tests

This directory contains comprehensive tests for the core business logic of the TEGA application. These tests validate that business rules are correctly implemented and enforced.

## Test Coverage

### 1. Course Enrollment Logic (15 tests)
Tests the business rules for course enrollment:
- **Free Course Enrollment**: Auto-enrollment for free courses, marking as paid
- **Paid Course Enrollment**: Payment requirements, enrollment after payment
- **Duplicate Prevention**: Preventing duplicate enrollments, idempotent behavior
- **Enrollment Status**: Active status, progress initialization, date tracking
- **Progress Initialization**: Module/lecture counting, progress structure

### 2. Payment Processing Logic (20 tests)
Tests payment-related business rules:
- **Order Creation**: Validation requirements, exam-only orders, offer inclusion
- **Already Have Access**: Duplicate payment prevention, access checking
- **Payment Verification**: Signature validation, enrollment creation
- **Offer Application**: Percentage/fixed discounts, price limits
- **Payment Status**: Status transitions, failure handling, expiry dates
- **Amount Calculation**: Rupee to paise conversion, zero amounts

### 3. Exam Registration Logic (20 tests)
Tests exam registration business rules:
- **Payment Requirements**: Paid vs free exams, course-based access
- **Course-Based Exams**: Course payment checking, effective pricing
- **Standalone Exams**: Exam payment requirements, payment attempts
- **Slot Availability**: Active slots, capacity checking, time windows
- **Registration Validation**: Duplicate prevention, slot selection, status
- **Exam Start**: Registration requirements, slot validation, active status

### 4. Access Control Logic (18 tests)
Tests access control business rules:
- **Course Access**: Enrollment checking, multiple sources, auto-enrollment
- **Lecture Access**: Preview access, first lecture free, enrollment requirements
- **Exam Access**: Free exams, registration, payment status, course payment
- **Preview Content**: Free preview access, no enrollment needed
- **Access Expiry**: Date checking, lifetime access, expiry handling

### 5. Progress Tracking Logic (18 tests)
Tests progress tracking business rules:
- **Progress Calculation**: Percentage calculation, zero/100% handling
- **Module Completion**: All lectures complete, completion counting
- **Lecture Completion**: View duration, threshold checking, progress percentage
- **Course Completion**: 100% completion, remaining progress
- **Progress Updates**: Lecture completion, module completion, 100% cap

### 6. Offer and Discount Logic (10 tests)
Tests offer and discount business rules:
- **Offer Eligibility**: Active status, expiry checking, institute/course matching
- **Discount Calculation**: Percentage/fixed discounts, price limits, caps
- **Package Offers**: Savings calculation, course enrollment, expiry dates
- **Offer Application**: Best offer selection, validation, minimum purchase

## Business Rules Validated

### Enrollment Rules
- Free courses (price = 0) auto-enroll and are marked as paid
- Paid courses require payment before enrollment
- Duplicate enrollments are prevented (idempotent)
- New enrollments start with 0% progress
- Progress tracking is initialized with module/lecture counts

### Payment Rules
- Orders require courseId OR examId (not both)
- Duplicate payments are prevented if user already has access
- Payment verification requires orderId, paymentId, and signature
- Successful payments create enrollments with expiry dates
- Discounts cannot result in negative prices

### Exam Rules
- Paid exams require payment (course or exam payment)
- Course-based exams check course payment status
- Standalone exams require exam-specific payment
- Slots must be active, not full, and within registration window
- One registration per student per exam

### Access Rules
- Active enrollment grants course access
- Both Enrollment and UserCourse records are checked
- Free courses auto-enroll on access
- Access expires based on expiry date
- Preview content is always free
- First lecture is always free

### Progress Rules
- Progress = average of module and lecture progress
- Module complete when all lectures complete
- Lecture complete at 90% view duration
- Course complete at 100% progress
- Progress cannot exceed 100%

### Offer Rules
- Offers must be active and within validity period
- Best available offer is applied
- Discounts are capped at maximum
- Package purchases enroll in all included courses
- Duplicate package purchases are prevented

## Running Business Logic Tests

```bash
# Run all business logic tests
flutter test test/business_logic/

# Run specific business logic test
flutter test test/business_logic/course_enrollment_logic_test.dart

# Run with coverage
flutter test test/business_logic/ --coverage
```

## Test Structure

Each test file follows this structure:
1. **Group by Feature**: Tests grouped by business feature
2. **Group by Rule**: Sub-groups for specific business rules
3. **Test Cases**: Individual tests for each rule scenario
4. **Business Rule Comments**: Each test documents the business rule it validates

## Importance

These tests ensure that:
- Business rules are correctly implemented
- Edge cases are handled properly
- Calculations are accurate
- Access control is enforced
- Payment logic is secure
- Progress tracking is reliable

These tests are critical for production readiness as they validate the core business logic that drives the application's functionality.

