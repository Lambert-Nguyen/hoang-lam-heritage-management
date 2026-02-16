import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// App localization support - Full i18n implementation
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('vi'), // Vietnamese (primary)
    Locale('en'), // English
  ];

  // Check if current locale is Vietnamese
  bool get isVietnamese => locale.languageCode == 'vi';

  // Translations map
  static final Map<String, Map<String, String>> _translations = {
    'vi': _viTranslations,
    'en': _enTranslations,
  };

  String translate(String key) {
    return _translations[locale.languageCode]?[key] ??
        _translations['vi']?[key] ??
        key;
  }

  // ===== COMMON =====
  String get appName => translate('app_name');
  String get home => translate('home');
  String get bookings => translate('bookings');
  String get finance => translate('finance');
  String get settings => translate('settings');
  String get login => translate('login');
  String get logout => translate('logout');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get confirm => translate('confirm');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get add => translate('add');
  String get search => translate('search');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get retry => translate('retry');
  String get noData => translate('no_data');
  String get offline => translate('offline');
  String get close => translate('close');
  String get continueBtn => translate('continue');
  String get please => translate('please');
  String get areYouSure => translate('are_you_sure');
  String get actionCannotBeUndone => translate('action_cannot_be_undone');
  String get errorOccurred => translate('error_occurred');
  String get errorTryAgain => translate('error_try_again');
  String get featureComingSoon => translate('feature_coming_soon');
  String get update => translate('update');
  String get create => translate('create');
  String get viewAll => translate('view_all');
  String get all => translate('all');
  String get filter => translate('filter');
  String get status => translate('status');
  String get advancedFilter => translate('advanced_filter');
  String get bookingSource => translate('booking_source');
  String get clearFilter => translate('clear_filter');
  String get total => translate('total');
  String get active => translate('active');
  String get inactive => translate('inactive');
  String get enable => translate('enable');
  String get later => translate('later');
  String get open => translate('open');
  String get copied => translate('copied');
  String get reset => translate('reset');
  String get info => translate('info');
  String get name => translate('name');
  String get version => translate('version');

  // ===== ROOM STATUS =====
  String get available => translate('available');
  String get occupied => translate('occupied');
  String get cleaning => translate('cleaning');
  String get maintenance => translate('maintenance');
  String get blocked => translate('blocked');

  // ===== AUTH =====
  String get loginSubtitle => translate('login_subtitle');
  String get usernameLabel => translate('username_label');
  String get usernameHint => translate('username_hint');
  String get usernameRequired => translate('username_required');
  String get passwordLabel => translate('password_label');
  String get passwordRequired => translate('password_required');
  String get passwordMinLength => translate('password_min_length');
  String get loginButton => translate('login_button');
  String get forgotPassword => translate('forgot_password');
  String get contactAdminResetPassword => translate('contact_admin_reset_password');
  String get enableBiometricTitle => translate('enable_biometric_title');
  String get enableBiometricMessage => translate('enable_biometric_message');
  String get biometricEnabled => translate('biometric_enabled');
  String get biometricAuthFailed => translate('biometric_auth_failed');
  String get authenticating => translate('authenticating');
  String get loginWith => translate('login_with');
  String get changePassword => translate('change_password');
  String get newPasswordMinLength => translate('new_password_min_length');
  String get passwordChangeSuccess => translate('password_change_success');
  String get passwordChangeFailed => translate('password_change_failed');
  String get currentPassword => translate('current_password');
  String get newPassword => translate('new_password');
  String get confirmNewPassword => translate('confirm_new_password');
  String get pleaseEnterCurrentPassword => translate('please_enter_current_password');
  String get pleaseEnterNewPassword => translate('please_enter_new_password');
  String get pleaseConfirmNewPassword => translate('please_confirm_new_password');
  String get newPasswordMustBeDifferent => translate('new_password_must_be_different');
  String get passwordsDoNotMatch => translate('passwords_do_not_match');
  String get apartmentManagement => translate('apartment_management');

  // ===== DASHBOARD =====
  String get notifications => translate('notifications');
  String get account => translate('account');
  String get roomStatus => translate('room_status');
  String get upcomingCheckout => translate('upcoming_checkout');
  String get upcomingCheckin => translate('upcoming_checkin');
  String get availableRooms => translate('available_rooms');
  String get roomsAvailable => translate('rooms_available');
  String get todayCheckIns => translate('today_check_ins');
  String get todayCheckOuts => translate('today_check_outs');
  String get todayRevenue => translate('today_revenue');
  String get occupancyRate => translate('occupancy_rate');
  String get checkoutToday => translate('checkout_today');
  String get checkinToday => translate('checkin_today');
  String get dashboardLoadError => translate('dashboard_load_error');
  String get newBooking => translate('new_booking');
  String get noRooms => translate('no_rooms');
  String get roomLoadError => translate('room_load_error');
  String get noCheckoutToday => translate('no_checkout_today');
  String get noCheckinToday => translate('no_checkin_today');
  String get guest => translate('guest');

  // ===== BOOKING =====
  String get checkIn => translate('check_in');
  String get checkOut => translate('check_out');
  String get guestName => translate('guest_name');
  String get guestPhone => translate('guest_phone');
  String get roomNumber => translate('room_number');
  String get nights => translate('nights');
  String get totalAmount => translate('total_amount');
  String get deposit => translate('deposit');
  String get balance => translate('balance');
  String get bookingList => translate('booking_list');
  String get dataLoadError => translate('data_load_error');
  String get searchGuestRoom => translate('search_guest_room');
  String get noBookings => translate('no_bookings');
  String get noBookingsForFilter => translate('no_bookings_for_filter');
  String get editBooking => translate('edit_booking');
  String get roomRequired => translate('room_required');
  String get pleaseSelectRoom => translate('please_select_room');
  String get guestRequired => translate('guest_required');
  String get pleaseSelectCreateGuest => translate('please_select_create_guest');
  String get bookingDates => translate('booking_dates');
  String get numberOfNights => translate('number_of_nights');
  String get createBooking => translate('create_booking');
  String get bookingDetails => translate('booking_details');
  String get goBack => translate('go_back');
  String get guestInfo => translate('guest_info');
  String get guestCount => translate('guest_count');
  String get people => translate('people');
  String get timeLabel => translate('time_label');
  String get expectedCheckin => translate('expected_checkin');
  String get expectedCheckout => translate('expected_checkout');
  String get actualCheckin => translate('actual_checkin');
  String get actualCheckout => translate('actual_checkout');
  String get payment => translate('payment');
  String get ratePerNight => translate('rate_per_night');
  String get depositPaid => translate('deposit_paid');
  String get balanceDue => translate('balance_due');
  String get paymentMethod => translate('payment_method');
  String get bookingInfo => translate('booking_info');
  String get source => translate('source');
  String get bookingDate => translate('booking_date');
  String get specialRequests => translate('special_requests');
  String get internalNotes => translate('internal_notes');
  String get selectBooking => translate('select_booking');
  String get bookingListLoadError => translate('booking_list_load_error');
  String get bookRoom => translate('book_room');

  // ===== EARLY/LATE FEES =====
  String get earlyCheckIn => translate('early_check_in');
  String get lateCheckOut => translate('late_check_out');
  String get earlyCheckInFee => translate('early_check_in_fee');
  String get lateCheckOutFee => translate('late_check_out_fee');
  String get quickSelect => translate('quick_select');
  String get numberOfHours => translate('number_of_hours');
  String get hours => translate('hours');
  String get feeAmount => translate('fee_amount');
  String get optionalNotes => translate('optional_notes');
  String get createFolioItem => translate('create_folio_item');
  String get trackInFinancials => translate('track_in_financials');
  String get maxHours24 => translate('max_hours_24');
  String get invalidValue => translate('invalid_value');
  String get required => translate('required');
  String get recordEarlyCheckIn => translate('record_early_check_in');
  String get recordLateCheckOut => translate('record_late_check_out');
  String get earlyCheckInRecorded => translate('early_check_in_recorded');
  String get lateCheckOutRecorded => translate('late_check_out_recorded');
  String get feesAndCharges => translate('fees_and_charges');

  // ===== ROOM =====
  String get roomManagement => translate('room_management');
  String get hideInactiveRooms => translate('hide_inactive_rooms');
  String get showInactiveRooms => translate('show_inactive_rooms');
  String get searchRooms => translate('search_rooms');
  String get roomNotFound => translate('room_not_found');
  String get noRoomsYet => translate('no_rooms_yet');
  String get addFirstRoom => translate('add_first_room');
  String get floor => translate('floor');
  String get addRoom => translate('add_room');
  String get deactivate => translate('deactivate');
  String get activate => translate('activate');
  String get roomDeactivated => translate('room_deactivated');
  String get roomActivated => translate('room_activated');
  String get deleteRoom => translate('delete_room');
  String get roomDeleted => translate('room_deleted');
  String get editRoom => translate('edit_room');
  String get addNewRoom => translate('add_new_room');
  String get roomNumberLabel => translate('room_number_label');
  String get pleaseEnterRoomNumber => translate('please_enter_room_number');
  String get roomNameOptional => translate('room_name_optional');
  String get exampleRoomName => translate('example_room_name');
  String get roomType => translate('room_type');
  String get pleaseSelectRoomType => translate('please_select_room_type');
  String get cannotLoadRoomTypes => translate('cannot_load_room_types');
  String get amenities => translate('amenities');
  String get airConditioning => translate('air_conditioning');
  String get safe => translate('safe');
  String get bathtub => translate('bathtub');
  String get hairDryer => translate('hair_dryer');
  String get workDesk => translate('work_desk');
  String get balcony => translate('balcony');
  String get roomNotes => translate('room_notes');
  String get roomIsActive => translate('room_is_active');
  String get roomCanBeBooked => translate('room_can_be_booked');
  String get roomDisabled => translate('room_disabled');
  String get roomUpdated => translate('room_updated');
  String get roomAdded => translate('room_added');
  String get confirmDeleteRoom => translate('confirm_delete_room');
  String get changeStatus => translate('change_status');
  String get roomInfo => translate('room_info');
  String get undefined => translate('undefined');
  String get hasGuests => translate('has_guests');
  String get viewBookingDetails => translate('view_booking_details');
  String get history => translate('history');
  String get noHistory => translate('no_history');

  // ===== GUEST =====
  String get guests => translate('guests');
  String get addGuest => translate('add_guest');
  String get searchGuests => translate('search_guests');
  String get guestNotFound => translate('guest_not_found');
  String get noGuestsYet => translate('no_guests_yet');
  String get tryDifferentSearch => translate('try_different_search');
  String get pressToAddGuest => translate('press_to_add_guest');
  String get editGuest => translate('edit_guest');
  String get contactInfo => translate('contact_info');
  String get phoneNumber => translate('phone_number');
  String get address => translate('address');
  String get identityDocument => translate('identity_document');
  String get documentType => translate('document_type');
  String get documentNumber => translate('document_number');
  String get issuedBy => translate('issued_by');
  String get issueDate => translate('issue_date');
  String get personalInfo => translate('personal_info');
  String get nationality => translate('nationality');
  String get gender => translate('gender');
  String get dateOfBirth => translate('date_of_birth');
  String get age => translate('age');
  String get yearsOld => translate('years_old');
  String get call => translate('call');
  String get removeVip => translate('remove_vip');
  String get markVip => translate('mark_vip');
  String get markedAsVip => translate('marked_as_vip');
  String get vipRemoved => translate('vip_removed');
  String get editInfo => translate('edit_info');
  String get deleteGuest => translate('delete_guest');
  String get confirmDelete => translate('confirm_delete');
  String get confirmDeleteGuest => translate('confirm_delete_guest');
  String get guestDeleted => translate('guest_deleted');
  String get editGuestTitle => translate('edit_guest_title');
  String get requiredInfo => translate('required_info');
  String get fullName => translate('full_name');
  String get pleaseEnterFullName => translate('please_enter_full_name');
  String get fullNameMinLength => translate('full_name_min_length');
  String get pleaseEnterPhone => translate('please_enter_phone');
  String get phoneMustBe10 => translate('phone_must_be_10');
  String get phoneMustStartWith0 => translate('phone_must_start_with_0');
  String get invalidEmail => translate('invalid_email');
  String get notSpecified => translate('not_specified');
  String get city => translate('city');
  String get preferencesHint => translate('preferences_hint');
  String get saveChanges => translate('save_changes');
  String get guestInfoUpdated => translate('guest_info_updated');
  String get newGuestAdded => translate('new_guest_added');
  String get selectFromList => translate('select_from_list');

  // ===== FINANCE =====
  String get income => translate('income');
  String get expense => translate('expense');
  String get profit => translate('profit');
  String get today => translate('today');
  String get thisMonth => translate('this_month');
  String get reports => translate('reports');
  String get month => translate('month');

  // ===== SETTINGS =====
  String get security => translate('security');
  String get enabled => translate('enabled');
  String get fasterLoginBiometric => translate('faster_login_biometric');
  String get biometricLoginEnabled => translate('biometric_login_enabled');
  String get biometricLoginDisabled => translate('biometric_login_disabled');
  String get propertyManagement => translate('property_management');
  String get addEditDeleteRooms => translate('add_edit_delete_rooms');
  String get priceManagement => translate('price_management');
  String get ratePlansPromotions => translate('rate_plans_promotions');
  String get generalSettings => translate('general_settings');
  String get theme => translate('theme');
  String get light => translate('light');
  String get dark => translate('dark');
  String get systemDefault => translate('system_default');
  String get language => translate('language');
  String get vietnamese => translate('vietnamese');
  String get textSize => translate('text_size');
  String get small => translate('small');
  String get normal => translate('normal');
  String get large => translate('large');
  String get extraLarge => translate('extra_large');
  String get notificationsSettings => translate('notifications_settings');
  String get roomCleaning => translate('room_cleaning');
  String get allOff => translate('all_off');
  String get management => translate('management');
  String get nightAudit => translate('night_audit');
  String get checkDailyFigures => translate('check_daily_figures');
  String get residenceDeclaration => translate('residence_declaration');
  String get exportGuestListPolice => translate('export_guest_list_police');
  String get financialCategories => translate('financial_categories');
  String get accountManagement => translate('account_management');
  String get data => translate('data');
  String get syncData => translate('sync_data');
  String get lastUpdateJustNow => translate('last_update_just_now');
  String get backup => translate('backup');
  String get support => translate('support');
  String get userGuide => translate('user_guide');
  String get aboutApp => translate('about_app');
  String get user => translate('user');
  String get staff => translate('staff');
  String get selectTheme => translate('select_theme');
  String get autoPhoneSettings => translate('auto_phone_settings');
  String get selectLanguage => translate('select_language');
  String get notificationSettings => translate('notification_settings');
  String get checkinReminder => translate('checkin_reminder');
  String get notifyCheckinToday => translate('notify_checkin_today');
  String get checkoutReminder => translate('checkout_reminder');
  String get notifyCheckoutToday => translate('notify_checkout_today');
  String get cleaningReminder => translate('cleaning_reminder');
  String get notifyRoomNeedsCleaning => translate('notify_room_needs_cleaning');
  String get pushNotifications => translate('push_notifications');
  String get receivePushNotifications => translate('receive_push_notifications');
  String get localReminders => translate('local_reminders');
  String get tapToRetry => translate('tap_to_retry');
  String get confirmLogout => translate('confirm_logout');
  String get confirmLogoutMessage => translate('confirm_logout_message');

  // ===== HOUSEKEEPING =====
  String get housekeepingTasks => translate('housekeeping_tasks');
  String get myTasks => translate('my_tasks');
  String get noTasks => translate('no_tasks');
  String get noTasksScheduledToday => translate('no_tasks_scheduled_today');
  String get noTasksCreated => translate('no_tasks_created');
  String get noTasksAssigned => translate('no_tasks_assigned');
  String get pending => translate('pending');
  String get inProgress => translate('in_progress');
  String get completed => translate('completed');
  String get createNewTask => translate('create_new_task');
  String get urgent => translate('urgent');
  String get noUrgentRequests => translate('no_urgent_requests');
  String get noUrgentMaintenanceRequests => translate('no_urgent_maintenance_requests');
  String get noMaintenanceRequests => translate('no_maintenance_requests');
  String get noMaintenanceRequestsCreated => translate('no_maintenance_requests_created');
  String get noYourRequests => translate('no_your_requests');
  String get noAssignedMaintenanceRequests => translate('no_assigned_maintenance_requests');
  String get assigned => translate('assigned');
  String get onHold => translate('on_hold');
  String get completedCancelled => translate('completed_cancelled');
  String get createRequest => translate('create_request');
  String get editRequest => translate('edit_request');
  String get createMaintenanceRequest => translate('create_maintenance_request');
  String get room => translate('room');
  String get cannotLoadRoomList => translate('cannot_load_room_list');
  String get title => translate('title');
  String get describeIssueBriefly => translate('describe_issue_briefly');
  String get pleaseEnterTitle => translate('please_enter_title');
  String get category => translate('category');
  String get priorityLevel => translate('priority_level');
  String get detailedDescription => translate('detailed_description');
  String get describeIssueInDetail => translate('describe_issue_in_detail');
  String get pleaseEnterDescription => translate('please_enter_description');
  String get estimatedCostOptional => translate('estimated_cost_optional');
  String get requestUpdated => translate('request_updated');
  String get newMaintenanceRequestCreated => translate('new_maintenance_request_created');
  String get selectRoom => translate('select_room');
  String get hold => translate('hold');
  String get resume => translate('resume');
  String get requestInfo => translate('request_info');
  String get assignee => translate('assignee');
  String get notAssigned => translate('not_assigned');
  String get reporter => translate('reporter');
  String get description => translate('description');
  String get resolutionResult => translate('resolution_result');
  String get createdAt => translate('created_at');
  String get completedAt => translate('completed_at');
  String get updatedAt => translate('updated_at');
  String get assign => translate('assign');
  String get maintenanceRequestCompleted => translate('maintenance_request_completed');
  String get requestOnHold => translate('request_on_hold');
  String get continueRequest => translate('continue_request');
  String get continueRequestConfirmation => translate('continue_request_confirmation');
  String get requestContinued => translate('request_continued');
  String get cancelRequest => translate('cancel_request');
  String get cancelRequestConfirmation => translate('cancel_request_confirmation');
  String get no => translate('no');
  String get requestCancelled => translate('request_cancelled');
  String get completeRequest => translate('complete_request');
  String get enterResolutionNotes => translate('enter_resolution_notes');
  String get describeWorkDone => translate('describe_work_done');
  String get holdRequest => translate('hold_request');
  String get enterHoldReason => translate('enter_hold_reason');
  String get reason => translate('reason');
  String get assignmentInDevelopment => translate('assignment_in_development');
  String get completeRequestConfirmation => translate('complete_request_confirmation');
  String get taskInfo => translate('task_info');
  String get taskType => translate('task_type');
  String get scheduledDate => translate('scheduled_date');
  String get bookingCode => translate('booking_code');
  String get creator => translate('creator');
  String get notes => translate('notes');
  String get taskAssigned => translate('task_assigned');
  String get taskCompleted => translate('task_completed');
  String get verifyTask => translate('verify_task');
  String get verifyTaskConfirmation => translate('verify_task_confirmation');
  String get taskVerified => translate('task_verified');
  String get deleteTask => translate('delete_task');
  String get deleteTaskConfirmation => translate('delete_task_confirmation');
  String get taskDeleted => translate('task_deleted');
  String get editTask => translate('edit_task');
  String get createTask => translate('create_task');
  String get enterNotesOptional => translate('enter_notes_optional');
  String get taskUpdated => translate('task_updated');
  String get newTaskCreated => translate('new_task_created');
  String get verify => translate('verify');

  // ===== NIGHT AUDIT =====
  String get nightAuditTitle => translate('night_audit_title');
  String get historyLabel => translate('history_label');
  String get selectDate => translate('select_date');
  String get auditLoadError => translate('audit_load_error');
  String get performedBy => translate('performed_by');
  String get notCompleted => translate('not_completed');
  String get occupancy => translate('occupancy');
  String get roomStatistics => translate('room_statistics');
  String get totalRooms => translate('total_rooms');
  String get beingCleaned => translate('being_cleaned');
  String get bookingStatistics => translate('booking_statistics');
  String get newBookings => translate('new_bookings');
  String get noShow => translate('no_show');
  String get financialOverview => translate('financial_overview');

  // ===== PRICING =====
  String get editRatePlan => translate('edit_rate_plan');
  String get addRatePlan => translate('add_rate_plan');
  String get deleteRatePlan => translate('delete_rate_plan');
  String get basicInfo => translate('basic_info');
  String get ratePlanName => translate('rate_plan_name');
  String get ratePlanHint => translate('rate_plan_hint');
  String get pleaseEnterRatePlanName => translate('please_enter_rate_plan_name');
  String get englishNameOptional => translate('english_name_optional');
  String get baseRatePerNight => translate('base_rate_per_night');
  String get vnd => translate('vnd');
  String get pleaseEnterRate => translate('please_enter_rate');
  String get rateMustBePositive => translate('rate_must_be_positive');
  String get stayRequirements => translate('stay_requirements');
  String get minNights => translate('min_nights');
  String get maxNights => translate('max_nights');
  String get noLimit => translate('no_limit');
  String get advanceBookingOptional => translate('advance_booking_optional');
  String get advanceBookingHint => translate('advance_booking_hint');
  String get cancellationPolicy => translate('cancellation_policy');
  String get validityPeriod => translate('validity_period');
  String get fromDate => translate('from_date');
  String get toDate => translate('to_date');
  String get includesBreakfast => translate('includes_breakfast');
  String get ratePlanIncludesFreeBreakfast => translate('rate_plan_includes_free_breakfast');
  String get isActive => translate('is_active');
  String get showApplyRatePlan => translate('show_apply_rate_plan');
  String get descriptionOptional => translate('description_optional');
  String get ratePlanNotes => translate('rate_plan_notes');
  String get createRatePlan => translate('create_rate_plan');
  String get ratePlanUpdated => translate('rate_plan_updated');
  String get ratePlanCreated => translate('rate_plan_created');
  String get deleteRatePlanConfirm => translate('delete_rate_plan_confirm');
  String get confirmDeleteRatePlan => translate('confirm_delete_rate_plan');
  String get ratePlanDeleted => translate('rate_plan_deleted');
  String get editDateRate => translate('edit_date_rate');
  String get addDateRate => translate('add_date_rate');
  String get weekend => translate('weekend');
  String get holiday => translate('holiday');
  String get lunarNewYear => translate('lunar_new_year');
  String get lowSeason => translate('low_season');
  String get promotion => translate('promotion');
  String get specialEvent => translate('special_event');
  String get createForMultipleDays => translate('create_for_multiple_days');
  String get applyForDateRange => translate('apply_for_date_range');
  String get dateRange => translate('date_range');
  String get applyDate => translate('apply_date');
  String get rateAdjustmentReason => translate('rate_adjustment_reason');
  String get rateReasonHint => translate('rate_reason_hint');
  String get restrictionsOptional => translate('restrictions_optional');
  String get closeForArrival => translate('close_for_arrival');
  String get noCheckinAllowed => translate('no_checkin_allowed');
  String get closeForDeparture => translate('close_for_departure');
  String get noCheckoutAllowed => translate('no_checkout_allowed');
  String get minNightsOptional => translate('min_nights_optional');
  String get minNightsRequired => translate('min_nights_required');
  String get createRatesMultipleDays => translate('create_rates_multiple_days');
  String get pleaseSelectEndDate => translate('please_select_end_date');
  String get dateRateUpdated => translate('date_rate_updated');
  String get createdRatesForDays => translate('created_rates_for_days');
  String get dateRateCreated => translate('date_rate_created');
  String get deleteDateRateConfirm => translate('delete_date_rate_confirm');
  String get confirmDeleteDateRate => translate('confirm_delete_date_rate');
  String get dateRateDeleted => translate('date_rate_deleted');
  String get allRoomTypes => translate('all_room_types');
  String get filterByRoomType => translate('filter_by_room_type');
  String get selectRoomType => translate('select_room_type');
  String get addRatePlanFlexiblePricing => translate('add_rate_plan_flexible_pricing');
  String get addSpecialRates => translate('add_special_rates');
  String get noArrivals => translate('no_arrivals');
  String get noDepartures => translate('no_departures');
  String get ratePlans => translate('rate_plans');
  String get dailyRates => translate('daily_rates');

  // ===== DECLARATION =====
  String get exportSuccess => translate('export_success');
  String get residenceDeclarationTitle => translate('residence_declaration_title');
  String get exportGuestListDescription => translate('export_guest_list_description');
  String get listIncludesGuestsInRange => translate('list_includes_guests_in_range');
  String get todayLabel => translate('today_label');
  String get yesterday => translate('yesterday');
  String get fileFormat => translate('file_format');
  String get exporting => translate('exporting');
  String get exportList => translate('export_list');
  String get cannotOpenFile => translate('cannot_open_file');
  String get cannotShareFile => translate('cannot_share_file');
  String get popular => translate('popular');
  String get hasFormat => translate('has_format');
  String get fileExported => translate('file_exported');

  // ===== MINIBAR =====
  String get minibarManagement => translate('minibar_management');
  String get addProduct => translate('add_product');
  String get searchProducts => translate('search_products');
  String get editProduct => translate('edit_product');
  String get deleteProduct => translate('delete_product');
  String get pleaseEnterProductName => translate('please_enter_product_name');
  String get enterOrSelectCategory => translate('enter_or_select_category');
  String get productAdded => translate('product_added');
  String get confirmDeleteItem => translate('confirm_delete_item');
  String get productDeleted => translate('product_deleted');
  String get inventoryManagement => translate('inventory_management');
  String get noMatchingProducts => translate('no_matching_products');
  String get pleaseSelectBookingFirst => translate('please_select_booking_first');

  // ===== FOLIO =====
  String get hideCancelledItems => translate('hide_cancelled_items');
  String get showCancelledItems => translate('show_cancelled_items');
  String get addCharge => translate('add_charge');
  String get cancelCharge => translate('cancel_charge');
  String get confirmCancelCharge => translate('confirm_cancel_charge');
  String get cancelReason => translate('cancel_reason');
  String get enterCancelReason => translate('enter_cancel_reason');
  String get pleaseEnterCancelReason => translate('please_enter_cancel_reason');
  String get chargeCancelledSuccess => translate('charge_cancelled_success');
  String get cannotCancelCharge => translate('cannot_cancel_charge');
  String get confirmCancel => translate('confirm_cancel');

  // ===== REPORTS =====
  String get totalRevenue => translate('total_revenue');
  String get roomsLabel => translate('rooms_label');
  String get totalAvailableRoomNights => translate('total_available_room_nights');
  String get totalSoldRoomNights => translate('total_sold_room_nights');
  String get roomRevenue => translate('room_revenue');
  String get totalExpense => translate('total_expense');
  String get totalBookings => translate('total_bookings');
  String get bookingsLabel => translate('bookings_label');
  String get totalGuests => translate('total_guests');
  String get guestsLabel => translate('guests_label');

  // ===== ROOM INSPECTION =====
  String get roomInspection => translate('room_inspection');
  String get statistics => translate('statistics');
  String get inspectionTemplate => translate('inspection_template');
  String get requiresAction => translate('requires_action');
  String get createInspection => translate('create_inspection');
  String get inspectionDetails => translate('inspection_details');
  String get start => translate('start');
  String get continueLabel => translate('continue_label');
  String get conductInspection => translate('conduct_inspection');
  String get createNewInspection => translate('create_new_inspection');
  String get createTemplate => translate('create_template');
  String get noTemplates => translate('no_templates');
  String get createFirstTemplate => translate('create_first_template');

  // ===== GROUP BOOKING =====
  String get groupBooking => translate('group_booking');
  String get confirmedStatus => translate('confirmed_status');
  String get checkedInStatus => translate('checked_in_status');
  String get checkedOutStatus => translate('checked_out_status');
  String get groupBookingDetails => translate('group_booking_details');
  String get editGroupBooking => translate('edit_group_booking');
  String get createGroupBooking => translate('create_group_booking');

  // ===== PHASE 5: NOTIFICATIONS & MESSAGING =====
  String get markAllRead => translate('mark_all_read');
  String get noNotifications => translate('no_notifications');
  String get noNotificationsDescription => translate('no_notifications_description');
  String get errorLoadingData => translate('error_loading_data');
  String get sendMessage => translate('send_message');
  String get channel => translate('channel');
  String get noMessagingTemplates => translate('no_templates_messaging');
  String get writeCustomMessage => translate('write_custom_message');
  String get writeCustomMessageDescription => translate('write_custom_message_description');
  String get messagePreview => translate('message_preview');
  String get recipient => translate('recipient');
  String get subject => translate('subject');
  String get messageContent => translate('message_content');
  String get send => translate('send');
  String get messageSentSuccess => translate('message_sent_success');
  String get messageSentPending => translate('message_sent_pending');
  String get messageSendFailed => translate('message_send_failed');
  String get noMessages => translate('no_messages');
  String get resendMessage => translate('resend_message');
  String get resendMessageConfirm => translate('resend_message_confirm');
  String get messageHistory => translate('message_history');

  // ===== PHASE C: EXTRACTED HARDCODED STRINGS =====
  // Room Status Dialog
  String get updateStatus => translate('update_status');
  String get currentStatusLabel => translate('current_status_label');
  String get selectNewStatus => translate('select_new_status');
  String get currentLabel => translate('current_label');
  String get cannotUpdateRoomStatus => translate('cannot_update_room_status');
  String get notesOptional => translate('notes_optional');
  String get enterNotes => translate('enter_notes');

  // Add Charge Dialog
  String get chargeType => translate('charge_type');
  String get descriptionRequired => translate('description_required');
  String get enterChargeDescription => translate('enter_charge_description');
  String get quantityRequired => translate('quantity_required');
  String get quantityMinOne => translate('quantity_min_one');
  String get unitPriceRequired => translate('unit_price_required');
  String get unitPricePositive => translate('unit_price_positive');
  String get dateLabel => translate('date_label');
  String get totalSum => translate('total_sum');
  String get chargeAddedSuccess => translate('charge_added_success');
  String get cannotAddCharge => translate('cannot_add_charge');

  // Record Deposit Dialog
  String get recordLabel => translate('record_label');
  String get additionalNotesHint => translate('additional_notes_hint');

  // Pricing sections
  String get optionsSection => translate('options_section');
  String get reasonLabel => translate('reason_label');

  // Lost & Found
  String get itemNameLabel => translate('item_name_label');
  String get itemNameHint => translate('item_name_hint');
  String get pleaseEnterName => translate('please_enter_name');
  String get foundDateLabel => translate('found_date_label');
  String get locationSection => translate('location_section');
  String get foundLocationLabel => translate('found_location_label');
  String get foundLocationHint => translate('found_location_hint');
  String get pleaseEnterValue => translate('please_enter_value');
  String get storageLocationLabel => translate('storage_location_label');
  String get storageLocationHint => translate('storage_location_hint');
  String get contactSection => translate('contact_section');
  String get guestContacted => translate('guest_contacted');
  String get contactNotes => translate('contact_notes');
  String get additionalInfo => translate('additional_info');
  String get estimatedValueVnd => translate('estimated_value_vnd');
  String get addNew => translate('add_new');
  String get itemCreated => translate('item_created');
  String get itemUpdated => translate('item_updated');
  String get storeInStorage => translate('store_in_storage');
  String get itemClaimed => translate('item_claimed');
  String get disposeItem => translate('dispose_item');
  String get storedSuccess => translate('stored_success');
  String get claimedSuccess => translate('claimed_success');
  String get disposedSuccess => translate('disposed_success');

  // Group Booking
  String get depositVnd => translate('deposit_vnd');
  String get discountPercent => translate('discount_percent');
  String get depositPaidLabel => translate('deposit_paid_label');
  String get bookingCreated => translate('booking_created');
  String get pleaseAssignRoomsFirst => translate('please_assign_rooms_first');
  String get checkedInSuccess => translate('checked_in_success');
  String get roomAssignment => translate('room_assignment');
  String get roomIdList => translate('room_id_list');
  String get invalidRoomList => translate('invalid_room_list');
  String get roomsAssigned => translate('rooms_assigned');

  // Financial Category
  String get categoryNameRequired => translate('category_name_required');
  String get categoryNameHint => translate('category_name_hint');
  String get pleaseEnterCategoryName => translate('please_enter_category_name');
  String get englishName => translate('english_name');
  String get iconLabel => translate('icon_label');
  String get colorLabel => translate('color_label');

  // Room Inspection
  String get issueNotes => translate('issue_notes');
  String get describeIssueHint => translate('describe_issue_hint');
  String get generalNotes => translate('general_notes');
  String get actionRequiredLabel => translate('action_required_label');
  String get describeActionHint => translate('describe_action_hint');
  String get inspectionCreated => translate('inspection_created');

  // Inspection Template
  String get templateNameRequired => translate('template_name_required');
  String get templateNameHint => translate('template_name_hint');
  String get pleaseEnterTemplateName => translate('please_enter_template_name');
  String get inspectionType => translate('inspection_type');
  String get sortOrderHint => translate('sort_order_hint');
  String get defaultTemplate => translate('default_template');
  String get useAsDefaultTemplate => translate('use_as_default_template');
  String get checklistItemsCount => translate('checklist_items_count');
  String get templateCreated => translate('template_created');
  String get editInDevelopment => translate('edit_in_development');
  String get templateCopied => translate('template_copied');
  String get addChecklistItem => translate('add_checklist_item');
  String get itemNameRequired => translate('item_name_required');
  String get bedroom => translate('bedroom');
  String get bathroom => translate('bathroom');
  String get electronics => translate('electronics');
  String get safetyLabel => translate('safety_label');
  String get otherCategory => translate('other_category');
  String get pleaseAddChecklistItem => translate('please_add_checklist_item');

  // Night Audit
  String get statsRecalculated => translate('stats_recalculated');
  String get closeAudit => translate('close_audit');
  String get closeAuditConfirmation => translate('close_audit_confirmation');
  String get auditClosed => translate('audit_closed');

  // Maintenance
  String get assignRepair => translate('assign_repair');
  String get selfAssign => translate('self_assign');
  String get staffLoadError => translate('staff_load_error');
  String get noStaffAvailable => translate('no_staff_available');

  // Minibar
  String get onSale => translate('on_sale');
  String get notForSale => translate('not_for_sale');
  String get chargeMarkedSuccess => translate('charge_marked_success');
  String get paymentSuccess => translate('payment_success');

  // Reports
  String get saveFileError => translate('save_file_error');
  String get noDataInRange => translate('no_data_in_range');
  String get noExpensesInRange => translate('no_expenses_in_range');

  // Settings
  String get backupInDevelopment => translate('backup_in_development');
  String get searchStaffHint => translate('search_staff_hint');

  // Guest
  String get staysLabel => translate('stays_label');

  // Router errors
  String get roomInfoNotFound => translate('room_info_not_found');
  String get bookingInfoNotFound => translate('booking_info_not_found');
  String get taskInfoNotFound => translate('task_info_not_found');
  String get maintenanceNotFound => translate('maintenance_not_found');
  String get lostItemNotFound => translate('lost_item_not_found');
  String get ratePlanNotFound => translate('rate_plan_not_found');
  String get dateRateNotFound => translate('date_rate_not_found');
  String get pageNotFound => translate('page_not_found');
  String get goHome => translate('go_home');

  // ===== PHASE C2: ADDITIONAL EXTRACTED STRINGS =====
  // Common / Shared
  String get contactLabel => translate('contact_label');
  String get contactPerson => translate('contact_person');
  String get assignedRooms => translate('assigned_rooms');
  String get paid => translate('paid');
  String get unpaid => translate('unpaid');
  String get amount => translate('amount');
  String get selectStaff => translate('select_staff');

  // Time
  String get justNow => translate('just_now');
  String get minutesAgo => translate('minutes_ago');
  String get hoursAgo => translate('hours_ago');
  String get daysAgo => translate('days_ago');
  String get lastMonth => translate('last_month');
  String get thisYear => translate('this_year');
  String get sevenDays => translate('seven_days');
  String get thirtyDays => translate('thirty_days');
  String get ninetyDays => translate('ninety_days');
  String get last7Days => translate('last_7_days');
  String get last30Days => translate('last_30_days');
  String get claimedDate => translate('claimed_date');

  // Finance / Payment
  String get depositAmount => translate('deposit_amount');
  String get cash => translate('cash');
  String get bankTransfer => translate('bank_transfer');
  String get recordDeposit => translate('record_deposit');
  String get costPrice => translate('cost_price');
  String get sellingPriceRequired => translate('selling_price_required');
  String get profitMargin => translate('profit_margin');
  String get roomCharges => translate('room_charges');
  String get additionalCharges => translate('additional_charges');
  String get totalCharges => translate('total_charges');
  String get remainingBalance => translate('remaining_balance');
  String get guestOwes => translate('guest_owes');
  String get outstandingBalance => translate('outstanding_balance');
  String get noDeposit => translate('no_deposit');
  String get depositShort => translate('deposit_short');
  String get depositPaidStatus => translate('deposit_paid_status');
  String get requiredAmount => translate('required_amount');
  String get amountShort => translate('amount_short');
  String get recordDepositBtn => translate('record_deposit_btn');
  String get noPendingDeposits => translate('no_pending_deposits');
  String get currencyType => translate('currency_type');
  String get exchangeRate => translate('exchange_rate');
  String get confirmPayment => translate('confirm_payment');
  String get vndPerNight => translate('vnd_per_night');
  String get referenceCode => translate('reference_code');
  String get methodLabel => translate('method_label');

  // Financial Category
  String get noIncomeCategories => translate('no_income_categories');
  String get noExpenseCategories => translate('no_expense_categories');
  String get categoryHidden => translate('category_hidden');
  String get categoryShown => translate('category_shown');
  String get viewFinancialCategories => translate('view_financial_categories');

  // Group Booking
  String get groupInfo => translate('group_info');
  String get groupNameRequired => translate('group_name_required');
  String get numberOfRooms => translate('number_of_rooms');
  String get numberOfGuests => translate('number_of_guests');

  // Minibar
  String get noProducts => translate('no_products');
  String get clearCart => translate('clear_cart');
  String get confirmClearCart => translate('confirm_clear_cart');
  String get productUpdatedSuccess => translate('product_updated_success');
  String get confirmDeleteProduct => translate('confirm_delete_product');

  // Night Audit
  String get occupancyPercent => translate('occupancy_percent');

  // Reports
  String get exportReport => translate('export_report');
  String get averageOccupancy => translate('average_occupancy');
  String get totalSpending => translate('total_spending');

  // Staff
  String get hotelOwner => translate('hotel_owner');
  String get managerRole => translate('manager_role');
  String get housekeepingRole => translate('housekeeping_role');
  String get viewStaffList => translate('view_staff_list');

  // Guest
  String get bookingHistory => translate('booking_history');
  String get timesCount => translate('times_count');
  String get createNewGuest => translate('create_new_guest');
  String get findGuest => translate('find_guest');
  String get min2Characters => translate('min_2_characters');

  // Booking
  String get selectBookingSource => translate('select_booking_source');

  // Folio
  String get noCharges => translate('no_charges');
  String get itemsCount => translate('items_count');
  String get voided => translate('voided');
  String get byLabel => translate('by_label');
  String get paidShort => translate('paid_short');

  // Notification
  String get markedNotificationsRead => translate('marked_notifications_read');

  // Settings
  String get appDescription => translate('app_description');
  String get developedBy => translate('developed_by');
  String get copyrightNotice => translate('copyright_notice');

  // Declaration
  String get dd10FormDescription => translate('dd10_form_description');
  String get na17FormDescription => translate('na17_form_description');
  String get formType => translate('form_type');

  // Room Inspection Detail
  String get inspectionInfo => translate('inspection_info');
  String get roomIdRequired => translate('room_id_required');
  String get inspectionDateLabel => translate('inspection_date_label');
  String get inspectionTemplateOptional => translate('inspection_template_optional');
  String get noDefaultTemplate => translate('no_default_template');
  String get confirmDeleteTemplate => translate('confirm_delete_template');
  String get templateDeleted => translate('template_deleted');
  String get importantLabel => translate('important_label');
  String get inspectionChecklist => translate('inspection_checklist');
  String get copyTemplate => translate('copy_template');
  String get inspectionResult => translate('inspection_result');
  String get scoreLabel => translate('score_label');
  String get passedLabel => translate('passed_label');
  String get issuesCount => translate('issues_count');
  String get criticalCount => translate('critical_count');
  String get noChecklistItems => translate('no_checklist_items');
  String get imagesLabel => translate('images_label');
  String get actionsRequired => translate('actions_required');
  String get viewImage => translate('view_image');
  String get expectedDate => translate('expected_date');
  String get inspector => translate('inspector');

  // ===== PHASE C3: REMAINING HARDCODED STRINGS =====

  // Common/Actions
  String get undo => translate('undo');
  String get shareBtn => translate('share_btn');
  String get completeAction => translate('complete_action');
  String get resendBtn => translate('resend_btn');
  String get emailLabel => translate('email_label');
  String get phoneLabel => translate('phone_label');
  String get unknownError => translate('unknown_error');
  String get confirmDeleteTitle => translate('confirm_delete_title');
  String get confirmCancelLabel => translate('confirm_cancel_label');
  String get errorWithDetails => translate('error_with_details');

  // Booking Statuses (for badges)
  String get statusPending => translate('status_pending');
  String get statusConfirmed => translate('status_confirmed');
  String get statusCheckedIn => translate('status_checked_in');
  String get statusCheckedOut => translate('status_checked_out');
  String get statusCancelled => translate('status_cancelled');
  String get statusNoShow => translate('status_no_show');

  // Financial
  String get deleteCategory => translate('delete_category');
  String get categoryDeletedMsg => translate('category_deleted_msg');
  String get expenseLabel => translate('expense_label');
  String get profitLabel => translate('profit_label');
  String get discountLabel => translate('discount_label');
  String get transactionsLabel => translate('transactions_label');
  String get totalAmountVnd => translate('total_amount_vnd');

  // Group Booking
  String get stayPeriod => translate('stay_period');
  String get additionalInfoSection => translate('additional_info_section');
  String get exampleGroupName => translate('example_group_name');
  String get noGroupBookings => translate('no_group_bookings');
  String get roomsCountSuffix => translate('rooms_count_suffix');
  String get guestsCountSuffix => translate('guests_count_suffix');
  String get roomsNeeded => translate('rooms_needed');
  String get checkInDateLabel => translate('check_in_date_label');
  String get checkOutDateLabel => translate('check_out_date_label');
  String get groupUpdated => translate('group_updated');
  String get groupCreated => translate('group_created');
  String get contactPersonRequired => translate('contact_person_required');
  String get phoneRequired => translate('phone_required');
  String get assignRooms => translate('assign_rooms');
  String get cancelGroup => translate('cancel_group');
  String get confirmGroup => translate('confirm_group');
  String get checkInGroup => translate('check_in_group');
  String get checkOutGroup => translate('check_out_group');

  // Night Audit
  String get recalculate => translate('recalculate');
  String get recalculateError => translate('recalculate_error');
  String get closeAuditBtn => translate('close_audit_btn');
  String get noAuditsYet => translate('no_audits_yet');

  // Minibar
  String get minibarPos => translate('minibar_pos');
  String get noProductsInCategory => translate('no_products_in_category');
  String get noSalesYet => translate('no_sales_yet');
  String get salesHistoryHere => translate('sales_history_here');
  String get markAsCharged => translate('mark_as_charged');
  String get paymentSuccessful => translate('payment_successful');
  String get confirmPaymentTitle => translate('confirm_payment_title');
  String get productDeletedMsg => translate('product_deleted_msg');

  // Reports
  String get occupancyLabel => translate('occupancy_label');
  String get noExpensesLabel => translate('no_expenses_label');

  // Room Inspection Stats
  String get inspectionStatistics => translate('inspection_statistics');
  String get totalInspections => translate('total_inspections');
  String get completedInspections => translate('completed_inspections');
  String get needsAttention => translate('needs_attention');
  String get averageScore => translate('average_score');
  String get issuesDetected => translate('issues_detected');
  String get criticalLabel => translate('critical_label');
  String get failedLabel => translate('failed_label');
  String get inspectionCompleted => translate('inspection_completed');
  String get uncheckedCriticalItems => translate('unchecked_critical_items');

  // Lost & Found
  String get filterByCategoryLabel => translate('filter_by_category_label');
  String get statisticsLabel => translate('statistics_label');
  String get totalCountLabel => translate('total_count_label');
  String get unclaimedValue => translate('unclaimed_value');
  String get byStatusLabel => translate('by_status_label');

  // Settings Help
  String get helpRoomManagement => translate('help_room_management');
  String get helpRoomManagementDesc => translate('help_room_management_desc');
  String get helpBookings => translate('help_bookings');
  String get helpBookingsDesc => translate('help_bookings_desc');
  String get helpHousekeeping => translate('help_housekeeping');
  String get helpHousekeepingDesc => translate('help_housekeeping_desc');
  String get helpFinance => translate('help_finance');
  String get helpFinanceDesc => translate('help_finance_desc');
  String get helpNightAudit => translate('help_night_audit');
  String get helpNightAuditDesc => translate('help_night_audit_desc');
  String get english => translate('english');
  String get pushNotificationsLabel => translate('push_notifications_label');

  // Pricing
  String get minNightsStayLabel => translate('min_nights_stay_label');
  String get includesBreakfastLabel => translate('includes_breakfast_label');
  String get noArrivalsLabel => translate('no_arrivals_label');
  String get noDeparturesLabel => translate('no_departures_label');
  String get scheduleConflictWarning => translate('schedule_conflict_warning');
  String get fromDateRequired => translate('from_date_required');
  String get toDateRequired => translate('to_date_required');
  String get selectDateRequired => translate('select_date_required');

  // Staff
  String get ownerManagerFilter => translate('owner_manager_filter');
  String get staffMember => translate('staff_member');
  String get usernameField => translate('username_field');
  String get phoneField => translate('phone_field');
  String get copiedValueMsg => translate('copied_value_msg');

  // Declaration
  String get hasFormatMultiSheet => translate('has_format_multi_sheet');
  String get textFormatPopular => translate('text_format_popular');

  // Folio
  String get folio => translate('folio');
  String get cancelChargeTitle => translate('cancel_charge_title');

  // Booking Source
  String get walkIn => translate('walk_in');
  String get phoneSource => translate('phone_source');
  String get rankLabel => translate('rank_label');

  // Housekeeping Checklist Items
  String get changeBedSheets => translate('change_bed_sheets');
  String get vacuum => translate('vacuum');
  String get mopFloor => translate('mop_floor');
  String get restockSupplies => translate('restock_supplies');
  String get checkMinibar => translate('check_minibar');
  String get changeTowels => translate('change_towels');
  String get emptyTrash => translate('empty_trash');
  String get restockWater => translate('restock_water');
  String get deepCleanBathroom => translate('deep_clean_bathroom');
  String get washCurtains => translate('wash_curtains');
  String get cleanAC => translate('clean_ac');
  String get cleanFridge => translate('clean_fridge');
  String get checkFurniture => translate('check_furniture');
  String get checkCleanliness => translate('check_cleanliness');
  String get checkEquipment => translate('check_equipment');
  String get checkSupplies => translate('check_supplies');
  String get checkSafety => translate('check_safety');
  String get checkForIssues => translate('check_for_issues');
  String get performRepair => translate('perform_repair');
  String get reinspect => translate('reinspect');
  String get enterTaskNotes => translate('enter_task_notes');

  // ===== PHASE C4: COMPREHENSIVE L10N COVERAGE =====

  // Night Audit Details
  String get totalIncome => translate('total_income');
  String get netProfit => translate('net_profit');
  String get otherRevenue => translate('other_revenue');
  String get roomsOccupied => translate('rooms_occupied');
  String get roomsCleaning => translate('rooms_cleaning');
  String get roomsMaintenance => translate('rooms_maintenance');
  String get noShows => translate('no_shows');
  String get cancellationsLabel => translate('cancellations_label');
  String get pendingPayments => translate('pending_payments');
  String get paymentDetails => translate('payment_details');
  String get otherPayment => translate('other_payment');
  String get notesLabel => translate('notes_label');
  String get closingAudit => translate('closing_audit');
  String get auditHistory => translate('audit_history');
  String get loadHistoryError => translate('load_history_error');
  String get closeAuditError => translate('close_audit_error');
  String get revenueShort => translate('revenue_short');
  String get profitShort => translate('profit_short');
  String get statusLabel => translate('status_label');
  String get roomLabel => translate('room_label');
  String get occupancyFilled => translate('occupancy_filled');
  String get closeButton => translate('close_button');

  // Report Screen
  String get reportLoadError => translate('report_load_error');
  String get noDataInPeriod => translate('no_data_in_period');
  String get last90Days => translate('last_90_days');
  String get revenueLabel => translate('revenue_label');
  String get expensesLabel => translate('expenses_label');
  String get mainKPIs => translate('main_kpis');
  String get detailsLabel => translate('details_label');
  String get totalExpenses => translate('total_expenses');
  String get noExpensesInPeriod => translate('no_expenses_in_period');

  // Staff Management
  String get noSearchResults => translate('no_search_results');
  String get staffRole => translate('staff_role');
  String get housekeepingShort => translate('housekeeping_short');
  String get permissionsLabel => translate('permissions_label');
  String get noPermissionsAssigned => translate('no_permissions_assigned');
  String get permViewAllData => translate('perm_view_all_data');
  String get permManageFinance => translate('perm_manage_finance');
  String get permManageBookings => translate('perm_manage_bookings');
  String get permManageStaff => translate('perm_manage_staff');
  String get permEditRoomPrices => translate('perm_edit_room_prices');
  String get permNightAudit => translate('perm_night_audit');
  String get permReportsStats => translate('perm_reports_stats');
  String get permViewBookings => translate('perm_view_bookings');
  String get permUpdateRoomStatus => translate('perm_update_room_status');
  String get permViewRoomList => translate('perm_view_room_list');
  String get permUpdateCleaning => translate('perm_update_cleaning');
  String get permReportMaintenance => translate('perm_report_maintenance');
  String get copyTooltip => translate('copy_tooltip');
  String get staying => translate('staying');

  // Declaration Export
  String get dateRangeLabel => translate('date_range_label');
  String get fileExportedSuccess => translate('file_exported_success');
  String get bookingsMarkedAsDeclared => translate('bookings_marked_as_declared');
  String get openFileBtn => translate('open_file_btn');
  String get shareFileBtn => translate('share_file_btn');
  String get fileFormatLabel => translate('file_format_label');
  String get last7DaysLabel => translate('last_7_days_label');
  String get last30DaysLabel => translate('last_30_days_label');
  String get declarationFormDescriptions => translate('declaration_form_descriptions');

  // Group Booking Detail
  String get phone => translate('phone');
  String get email => translate('email');
  String get checkInDate => translate('check_in_date');
  String get checkOutDate => translate('check_out_date');
  String get paymentLabel => translate('payment_label');
  String get discountAmount => translate('discount_amount');
  String get yesLabel => translate('yes_label');
  String get notYetLabel => translate('not_yet_label');
  String get notesSection => translate('notes_section');
  String get confirmGroupBooking => translate('confirm_group_booking');
  String get confirmedMsg => translate('confirmed_msg');
  String get confirmGroupCheckIn => translate('confirm_group_check_in');
  String get confirmGroupCheckOut => translate('confirm_group_check_out');
  String get checkedOutSuccess => translate('checked_out_success');
  String get cancelledMsg => translate('cancelled_msg');
  String get roomIdListHint => translate('room_id_list_hint');

  // Minibar Common
  String get product => translate('product');
  String get quantity => translate('quantity');
  String get unitPrice => translate('unit_price');
  String get charged => translate('charged');
  String get notCharged => translate('not_charged');
  String get saleDetails => translate('sale_details');
  String get emptyCart => translate('empty_cart');
  String get checkoutBtn => translate('checkout_btn');
  String get clearAll => translate('clear_all');
  String get discontinued => translate('discontinued');
  String get cartTitle => translate('cart_title');
  String get productAddedSuccess => translate('product_added_success');
  String get invalid => translate('invalid');
  String get activeStatusLabel => translate('active_status_label');
  String get costAmount => translate('cost_amount');
  String get activateLabel => translate('activate_label');

  // Housekeeping Widgets
  String get unassigned => translate('unassigned');
  String get completeBtn => translate('complete_btn');
  String get filterMaintenanceRequests => translate('filter_maintenance_requests');
  String get clearFilters => translate('clear_filters');
  String get applyBtn => translate('apply_btn');
  String get filterTasks => translate('filter_tasks');
  String get taskTypeLabel => translate('task_type_label');
  String get tomorrow => translate('tomorrow');

  // Guest Widgets
  String get searchGuestHint => translate('search_guest_hint');
  String get idNumber => translate('id_number');

  // Common Widgets
  String get offlineSyncMessage => translate('offline_sync_message');
  String get incomeExpenseChart => translate('income_expense_chart');
  String get incomeLabel => translate('income_label');
  String get expenseShort => translate('expense_short');

  // Room Folio
  String get voidCharge => translate('void_charge');
  String get confirmVoidCharge => translate('confirm_void_charge');
  String get chargeAmount => translate('charge_amount');
  String get voidReasonRequired => translate('void_reason_required');
  String get enterVoidReason => translate('enter_void_reason');
  String get pleaseEnterVoidReason => translate('please_enter_void_reason');
  String get chargeVoidedSuccess => translate('charge_voided_success');
  String get cannotVoidCharge => translate('cannot_void_charge');
  String get confirmVoid => translate('confirm_void');

  // Inspection Template Details
  String get defaultBadge => translate('default_badge');
  String get duplicateBtn => translate('duplicate_btn');
  String get critical => translate('critical');
  String get templateDuplicated => translate('template_duplicated');
  String get roomTypeIdOptional => translate('room_type_id_optional');
  String get roomTypeIdHint => translate('room_type_id_hint');
  String get amenitiesCategory => translate('amenities_category');
  String get electronicsCategory => translate('electronics_category');
  String get bedClean => translate('bed_clean');
  String get bedSheetReplaced => translate('bed_sheet_replaced');
  String get pillowsBlanketClean => translate('pillows_blanket_clean');
  String get toiletClean => translate('toilet_clean');
  String get towelsComplete => translate('towels_complete');
  String get toiletriesComplete => translate('toiletries_complete');
  String get acWorking => translate('ac_working');
  String get tvWorking => translate('tv_working');
  String get fridgeWorking => translate('fridge_working');
  String get createNewInspectionTemplate => translate('create_new_inspection_template');

  // Room Inspection Detail
  String get bookingCodeLabel => translate('booking_code_label');
  String get actionRequiredSection => translate('action_required_section');
  String get viewPhoto => translate('view_photo');
  String get completedLabel => translate('completed_label');

  // Booking Source Selector
  String get selectBookingSourceHint => translate('select_booking_source_hint');

  // ===== PHASE C5: ADDITIONAL L10N KEYS =====
  String get totalRoomNightsAvailable => translate('total_room_nights_available');
  String get totalRoomNightsSold => translate('total_room_nights_sold');
  String get noExpensesInDateRange => translate('no_expenses_in_date_range');
  String get roleHousekeepingLabel => translate('role_housekeeping_label');
  String get roomsSuffix => translate('rooms_suffix');
  String get nightsSuffix => translate('nights_suffix');
  String get guestsSuffix => translate('guests_suffix');
  String get transactionsSuffix => translate('transactions_suffix');
  String get avgShort => translate('avg_short');

  // Phase C6 - Remaining screen l10n keys
  // Declaration Export
  String get excelFormatDesc => translate('excel_format_desc');
  String get csvFormatDesc => translate('csv_format_desc');

  // Minibar Inventory
  String get salesHistoryHint => translate('sales_history_hint');
  String get guestLabel => translate('guest_label');
  String get totalPrice => translate('total_price');

  // Minibar POS
  String get searchProductHint => translate('search_product_hint');
  String get selectBookingFirst => translate('select_booking_first');
  String get clearCartTitle => translate('clear_cart_title');
  String get clearCartConfirm => translate('clear_cart_confirm');
  String get confirmCheckout => translate('confirm_checkout');
  String get guestNameLabel => translate('guest_name_label');
  String get totalLabel => translate('total_label');
  String get checkoutSuccess => translate('checkout_success');

  // Minibar Item Form
  String get sellingPrice => translate('selling_price');
  String get requiredField => translate('required_field');
  String get activeLabel => translate('active_label');
  String get activeSelling => translate('active_selling');
  String get inactiveSelling => translate('inactive_selling');
  String get updateLabel => translate('update_label');
  String get productAddedMsg => translate('product_added_msg');
  String get confirmDeleteProductMsg => translate('confirm_delete_product_msg');
  String get productDeletedSuccess => translate('product_deleted_success');

  // Group Booking Detail
  String get roomCountLabel => translate('room_count_label');
  String get guestCountLabel => translate('guest_count_label');
  String get depositLabel => translate('deposit_label');
  String get paidStatus => translate('paid_status');
  String get assignRoomsLabel => translate('assign_rooms_label');
  String get roomIdListLabel => translate('room_id_list_label');
  String get roomsAssignedSuccess => translate('rooms_assigned_success');
  String get assignRoomsFirstMsg => translate('assign_rooms_first_msg');
  String get checkedInMsg => translate('checked_in_msg');
  String get checkedOutMsg => translate('checked_out_msg');
  String get cancelledStatus => translate('cancelled_status');

  // Room Inspection Detail
  String get scheduledDateLabel => translate('scheduled_date_label');
  String get inspectorLabel => translate('inspector_label');
  String get inspectionResults => translate('inspection_results');
  String get passLabel => translate('pass_label');
  String get issuesLabel => translate('issues_label');
  String get criticalIssuesLabel => translate('critical_issues_label');
  String get checklistLabel => translate('checklist_label');

  // Inspection Template
  String get editLabel => translate('edit_label');
  String get duplicateLabel => translate('duplicate_label');
  String get templateCreatedSuccess => translate('template_created_success');
  String get editFeatureInProgress => translate('edit_feature_in_progress');
  String get templateDeletedSuccess => translate('template_deleted_success');
  String get createNewTemplateTitle => translate('create_new_template_title');
  String get templateNameLabel => translate('template_name_label');
  String get inspectionTypeLabel => translate('inspection_type_label');
  String get defaultTemplateLabel => translate('default_template_label');
  String get defaultTemplateHint => translate('default_template_hint');
  String get checklistCount => translate('checklist_count');
  String get addLabel => translate('add_label');
  String get createTemplateBtn => translate('create_template_btn');
  String get addChecklistItemTitle => translate('add_checklist_item_title');
  String get categoryLabel => translate('category_label');
  String get bedroomCategory => translate('bedroom_category');
  String get bathroomCategory => translate('bathroom_category');
  String get safetyCategory => translate('safety_category');
  String get pleaseAddAtLeastOne => translate('please_add_at_least_one');
  String get itemsSuffix => translate('items_suffix');

  // ===== PHASE C7: HARDCODED VIETNAMESE STRING EXTRACTION =====

  // Date Rate Override Form
  String get tetHoliday => translate('tet_holiday');
  String get christmas => translate('christmas');
  String get summerSeason => translate('summer_season');
  String get priceSection => translate('price_section');
  String get priceForThisDate => translate('price_for_this_date');
  String get vndSuffix => translate('vnd_suffix');
  String get pleaseEnterPrice => translate('please_enter_price');
  String get priceMustBePositive => translate('price_must_be_positive');
  String get createPriceMultipleDays => translate('create_price_multiple_days');
  String get createDateRate => translate('create_date_rate');
  String get pleaseSelectDate => translate('please_select_date');
  String get dateRateCreatedForDays => translate('date_rate_created_for_days');
  String get deleteDateRateTitle => translate('delete_date_rate_title');
  String get selectDatePlaceholder => translate('select_date_placeholder');

  // Complete Task Dialog
  String get cleanBathroom => translate('clean_bathroom');
  String get generalCleaning => translate('general_cleaning');
  String get cleanGlass => translate('clean_glass');
  String get completeTaskTitle => translate('complete_task_title');
  String get completeAllItemsWarning => translate('complete_all_items_warning');

  // Financial Category Screen
  String get cannotDeleteCategoryMsg => translate('cannot_delete_category_msg');
  String get confirmDeleteCategoryMsg => translate('confirm_delete_category_msg');
  String get activeInUseCount => translate('active_in_use_count');
  String get hiddenCount => translate('hidden_count');
  String get editCategory => translate('edit_category');
  String get addIncomeCategoryTitle => translate('add_income_category_title');
  String get addExpenseCategoryTitle => translate('add_expense_category_title');
  String get categoryUpdatedMsg => translate('category_updated_msg');
  String get categoryCreatedMsg => translate('category_created_msg');
  String get incomeShort => translate('income_short');
  String get previewLabel => translate('preview_label');
  String get categoryNamePlaceholder => translate('category_name_placeholder');
  String get exampleElectricity => translate('example_electricity');
  String get exampleElectricityEn => translate('example_electricity_en');

  // Room Inspection Form Screen
  String get enterRoomIdHint => translate('enter_room_id_hint');
  String get pleaseEnterRoomId => translate('please_enter_room_id');
  String get noDefaultTemplateDesc => translate('no_default_template_desc');
  String get checklistItemsSuffix => translate('checklist_items_suffix');
  String get creatingText => translate('creating_text');
  String get createInspectionBtn => translate('create_inspection_btn');
  String get inspectionNotFound => translate('inspection_not_found');
  String get completeBtnLabel => translate('complete_btn_label');
  String get progressCount => translate('progress_count');
  String get importantBadge => translate('important_badge');
  String get passBtn => translate('pass_btn');
  String get failBtn => translate('fail_btn');
  String get enterNotesHint => translate('enter_notes_hint');
  String get actionRequiredIfAny => translate('action_required_if_any');
  String get describeActionRequired => translate('describe_action_required');
  String get pleaseSelectRoomMsg => translate('please_select_room_msg');
  String get inspectionCreatedSuccess => translate('inspection_created_success');

  // PHASE C7 Batch 2: Group Booking, Inspection List, Pricing
  String get checkInDateRequired => translate('check_in_date_required');
  String get checkOutDateRequired => translate('check_out_date_required');
  String get nightsCountDisplay => translate('nights_count_display');
  String get noPendingInspections => translate('no_pending_inspections');
  String get noCompletedInspections => translate('no_completed_inspections');
  String get noActionRequiredInspections => translate('no_action_required_inspections');
  String get noInspectionsYet => translate('no_inspections_yet');
  String get pendingInspectionsLabel => translate('pending_inspections_label');
  String get totalIssues => translate('total_issues');
  String get roomWithNumber => translate('room_with_number');
  String get scoreValueDisplay => translate('score_value_display');
  String get noRatePlansYet => translate('no_rate_plans_yet');
  String get pausedStatus => translate('paused_status');
  String get minNightsStayDisplay => translate('min_nights_stay_display');
  String get fromDateDisplay => translate('from_date_display');
  String get toDateDisplay => translate('to_date_display');
  String get noDailyRatesYet => translate('no_daily_rates_yet');

  // PHASE C7 Batch 3: Lost & Found strings
  String get lostAndFound => translate('lost_and_found');
  String get noClaimedItems => translate('no_claimed_items');
  String get noUnclaimedItems => translate('no_unclaimed_items');
  String get noLostFoundItems => translate('no_lost_found_items');
  String get confirmGuestClaimed => translate('confirm_guest_claimed');
  String get disposeReasonTitle => translate('dispose_reason_title');
  String get disposeReasonHint => translate('dispose_reason_hint');

  // PHASE C7 Batch 3: Widget/screen strings
  String get enterAmountHint => translate('enter_amount_hint');
  String get pleaseEnterAmount => translate('please_enter_amount');
  String get invalidAmount => translate('invalid_amount');
  String get cardPayment => translate('card_payment');
  String get otherLabel => translate('other_label');
  String get otherOta => translate('other_ota');
  String get errorLoadingStaffList => translate('error_loading_staff_list');
  String get assignToSelf => translate('assign_to_self');
  String get depositLabelAmount => translate('deposit_label_amount');
  String get overlapWarningTitle => translate('overlap_warning_title');
  String get overlapWarningMessage => translate('overlap_warning_message');
  String get roomNumberHint => translate('room_number_hint');
  String get paidAbbreviation => translate('paid_abbreviation');
  String get phoneValidationLength => translate('phone_validation_length');
  String get phoneValidationStartWithZero => translate('phone_validation_start_with_zero');
  String get productTab => translate('product_tab');

  // ===== ENUM DISPLAY NAMES & ERROR MESSAGES (Batch 5) =====
  String get bookingStatusPending => translate('booking_status_pending');
  String get bookingStatusConfirmed => translate('booking_status_confirmed');
  String get bookingStatusCheckedIn => translate('booking_status_checked_in');
  String get bookingStatusCheckedOut => translate('booking_status_checked_out');
  String get bookingStatusCancelled => translate('booking_status_cancelled');
  String get bookingStatusNoShow => translate('booking_status_no_show');
  String get bookingSourceWalkIn => translate('booking_source_walk_in');
  String get bookingSourcePhone => translate('booking_source_phone');
  String get bookingSourceOtherOta => translate('booking_source_other_ota');
  String get bookingSourceOther => translate('booking_source_other');
  String get paymentMethodCash => translate('payment_method_cash');
  String get paymentMethodBankTransfer => translate('payment_method_bank_transfer');
  String get paymentMethodCard => translate('payment_method_card');
  String get paymentMethodOtaCollect => translate('payment_method_ota_collect');
  String get paymentMethodOther => translate('payment_method_other');
  String get bookingTypeOvernight => translate('booking_type_overnight');
  String get bookingTypeHourly => translate('booking_type_hourly');
  String get roomStatusAvailable => translate('room_status_available');
  String get roomStatusOccupied => translate('room_status_occupied');
  String get roomStatusCleaning => translate('room_status_cleaning');
  String get roomStatusMaintenance => translate('room_status_maintenance');
  String get roomStatusBlocked => translate('room_status_blocked');
  String get paymentTypeDeposit => translate('payment_type_deposit');
  String get paymentTypeRoomCharge => translate('payment_type_room_charge');
  String get paymentTypeExtraCharge => translate('payment_type_extra_charge');
  String get paymentTypeRefund => translate('payment_type_refund');
  String get paymentTypeAdjustment => translate('payment_type_adjustment');
  String get paymentStatusPending => translate('payment_status_pending');
  String get paymentStatusCompleted => translate('payment_status_completed');
  String get paymentStatusFailed => translate('payment_status_failed');
  String get paymentStatusRefunded => translate('payment_status_refunded');
  String get paymentStatusCancelled => translate('payment_status_cancelled');
  String get folioTypeRoom => translate('folio_type_room');
  String get folioTypeMinibar => translate('folio_type_minibar');
  String get folioTypeLaundry => translate('folio_type_laundry');
  String get folioTypeFood => translate('folio_type_food');
  String get folioTypeService => translate('folio_type_service');
  String get folioTypeExtraBed => translate('folio_type_extra_bed');
  String get folioTypeEarlyCheckin => translate('folio_type_early_checkin');
  String get folioTypeLateCheckout => translate('folio_type_late_checkout');
  String get folioTypeDamage => translate('folio_type_damage');
  String get folioTypeOther => translate('folio_type_other');
  String get month1 => translate('month_1');
  String get month2 => translate('month_2');
  String get month3 => translate('month_3');
  String get month4 => translate('month_4');
  String get month5 => translate('month_5');
  String get month6 => translate('month_6');
  String get month7 => translate('month_7');
  String get month8 => translate('month_8');
  String get month9 => translate('month_9');
  String get month10 => translate('month_10');
  String get month11 => translate('month_11');
  String get month12 => translate('month_12');
  String get idTypeCccd => translate('id_type_cccd');
  String get idTypePassport => translate('id_type_passport');
  String get idTypeCmnd => translate('id_type_cmnd');
  String get idTypeDrivingLicense => translate('id_type_driving_license');
  String get idTypeOther => translate('id_type_other');
  String get idTypeCccdFull => translate('id_type_cccd_full');
  String get idTypePassportFull => translate('id_type_passport_full');
  String get idTypeCmndFull => translate('id_type_cmnd_full');
  String get idTypeDrivingLicenseFull => translate('id_type_driving_license_full');
  String get idTypeOtherFull => translate('id_type_other_full');
  String get genderMale => translate('gender_male');
  String get genderFemale => translate('gender_female');
  String get genderOther => translate('gender_other');
  String get passportTypeRegular => translate('passport_type_regular');
  String get passportTypeOfficial => translate('passport_type_official');
  String get passportTypeDiplomatic => translate('passport_type_diplomatic');
  String get passportTypeOther => translate('passport_type_other');
  String get visaTypeVisa => translate('visa_type_visa');
  String get visaTypeTemporaryResidence => translate('visa_type_temporary_residence');
  String get visaTypeVisaExemptionCert => translate('visa_type_visa_exemption_cert');
  String get visaTypeAbtc => translate('visa_type_abtc');
  String get visaTypeVisaExempt => translate('visa_type_visa_exempt');
  String get nationalityVietnam => translate('nationality_vietnam');
  String get nationalityChina => translate('nationality_china');
  String get nationalitySouthKorea => translate('nationality_south_korea');
  String get nationalityJapan => translate('nationality_japan');
  String get nationalityUsa => translate('nationality_usa');
  String get nationalityFrance => translate('nationality_france');
  String get nationalityUk => translate('nationality_uk');
  String get nationalityAustralia => translate('nationality_australia');
  String get nationalityGermany => translate('nationality_germany');
  String get nationalityRussia => translate('nationality_russia');
  String get nationalityThailand => translate('nationality_thailand');
  String get nationalitySingapore => translate('nationality_singapore');
  String get nationalityMalaysia => translate('nationality_malaysia');
  String get nationalityTaiwan => translate('nationality_taiwan');
  String get nationalityHongKong => translate('nationality_hong_kong');
  String get nationalityOther => translate('nationality_other');
  String get taskTypeCheckoutClean => translate('task_type_checkout_clean');
  String get taskTypeStayoverClean => translate('task_type_stayover_clean');
  String get taskTypeDeepClean => translate('task_type_deep_clean');
  String get taskTypeMaintenance => translate('task_type_maintenance');
  String get taskTypeInspection => translate('task_type_inspection');
  String get housekeepingStatusPending => translate('housekeeping_status_pending');
  String get housekeepingStatusInProgress => translate('housekeeping_status_in_progress');
  String get housekeepingStatusCompleted => translate('housekeeping_status_completed');
  String get housekeepingStatusVerified => translate('housekeeping_status_verified');
  String get priorityLow => translate('priority_low');
  String get priorityMedium => translate('priority_medium');
  String get priorityHigh => translate('priority_high');
  String get priorityUrgent => translate('priority_urgent');
  String get maintenanceStatusPending => translate('maintenance_status_pending');
  String get maintenanceStatusAssigned => translate('maintenance_status_assigned');
  String get maintenanceStatusInProgress => translate('maintenance_status_in_progress');
  String get maintenanceStatusPaused => translate('maintenance_status_paused');
  String get maintenanceStatusCompleted => translate('maintenance_status_completed');
  String get maintenanceStatusCancelled => translate('maintenance_status_cancelled');
  String get maintCatElectrical => translate('maint_cat_electrical');
  String get maintCatPlumbing => translate('maint_cat_plumbing');
  String get maintCatHvac => translate('maint_cat_hvac');
  String get maintCatFurniture => translate('maint_cat_furniture');
  String get maintCatAppliance => translate('maint_cat_appliance');
  String get maintCatStructural => translate('maint_cat_structural');
  String get maintCatSafety => translate('maint_cat_safety');
  String get maintCatOther => translate('maint_cat_other');
  String get inspectionStatusPending => translate('inspection_status_pending');
  String get inspectionStatusInProgress => translate('inspection_status_in_progress');
  String get inspectionStatusCompleted => translate('inspection_status_completed');
  String get inspectionStatusActionRequired => translate('inspection_status_action_required');
  String get inspectionTypeCheckout => translate('inspection_type_checkout');
  String get inspectionTypeCheckin => translate('inspection_type_checkin');
  String get inspectionTypeRoutine => translate('inspection_type_routine');
  String get inspectionTypeMaintenance => translate('inspection_type_maintenance');
  String get inspectionTypeDeepClean => translate('inspection_type_deep_clean');
  String get inspectionCatBedroom => translate('inspection_cat_bedroom');
  String get inspectionCatBathroom => translate('inspection_cat_bathroom');
  String get inspectionCatAmenities => translate('inspection_cat_amenities');
  String get inspectionCatElectronics => translate('inspection_cat_electronics');
  String get inspectionCatSafety => translate('inspection_cat_safety');
  String get inspectionCatGeneral => translate('inspection_cat_general');
  String get lostFoundStatusFound => translate('lost_found_status_found');
  String get lostFoundStatusStored => translate('lost_found_status_stored');
  String get lostFoundStatusClaimed => translate('lost_found_status_claimed');
  String get lostFoundStatusDonated => translate('lost_found_status_donated');
  String get lostFoundStatusDisposed => translate('lost_found_status_disposed');
  String get lostFoundCatElectronics => translate('lost_found_cat_electronics');
  String get lostFoundCatClothing => translate('lost_found_cat_clothing');
  String get lostFoundCatJewelry => translate('lost_found_cat_jewelry');
  String get lostFoundCatDocuments => translate('lost_found_cat_documents');
  String get lostFoundCatMoney => translate('lost_found_cat_money');
  String get lostFoundCatBags => translate('lost_found_cat_bags');
  String get lostFoundCatPersonal => translate('lost_found_cat_personal');
  String get lostFoundCatOther => translate('lost_found_cat_other');
  String get cancelPolicyFree => translate('cancel_policy_free');
  String get cancelPolicyFlexible => translate('cancel_policy_flexible');
  String get cancelPolicyModerate => translate('cancel_policy_moderate');
  String get cancelPolicyStrict => translate('cancel_policy_strict');
  String get cancelPolicyNonRefundable => translate('cancel_policy_non_refundable');
  String get userRoleOwner => translate('user_role_owner');
  String get userRoleManager => translate('user_role_manager');
  String get userRoleStaff => translate('user_role_staff');
  String get userRoleHousekeeping => translate('user_role_housekeeping');
  String get nightAuditStatusDraft => translate('night_audit_status_draft');
  String get nightAuditStatusCompleted => translate('night_audit_status_completed');
  String get nightAuditStatusClosed => translate('night_audit_status_closed');
  String get notificationTypeNewBooking => translate('notification_type_new_booking');
  String get notificationTypeBookingConfirmed => translate('notification_type_booking_confirmed');
  String get notificationTypeBookingCancelled => translate('notification_type_booking_cancelled');
  String get notificationTypeCheckinReminder => translate('notification_type_checkin_reminder');
  String get notificationTypeCheckoutReminder => translate('notification_type_checkout_reminder');
  String get notificationTypeCheckedIn => translate('notification_type_checked_in');
  String get notificationTypeCheckedOut => translate('notification_type_checked_out');
  String get notificationTypeGeneral => translate('notification_type_general');
  String get messageStatusDraft => translate('message_status_draft');
  String get messageStatusSending => translate('message_status_sending');
  String get messageStatusSent => translate('message_status_sent');
  String get messageStatusDelivered => translate('message_status_delivered');
  String get messageStatusFailed => translate('message_status_failed');
  String get msgTemplateBookingConfirm => translate('msg_template_booking_confirm');
  String get msgTemplatePreArrival => translate('msg_template_pre_arrival');
  String get msgTemplateCheckoutReminder => translate('msg_template_checkout_reminder');
  String get msgTemplateReviewRequest => translate('msg_template_review_request');
  String get msgTemplateCustom => translate('msg_template_custom');
  String get reportGroupDaily => translate('report_group_daily');
  String get reportGroupWeekly => translate('report_group_weekly');
  String get reportGroupMonthly => translate('report_group_monthly');
  String get reportTypeOccupancy => translate('report_type_occupancy');
  String get reportTypeRevenue => translate('report_type_revenue');
  String get reportTypeExpense => translate('report_type_expense');
  String get reportTypeKpi => translate('report_type_kpi');
  String get reportTypeChannel => translate('report_type_channel');
  String get reportTypeGuest => translate('report_type_guest');
  String get comparisonPreviousPeriod => translate('comparison_previous_period');
  String get comparisonPreviousYear => translate('comparison_previous_year');
  String get comparisonCustom => translate('comparison_custom');
  String get demographicsNationality => translate('demographics_nationality');
  String get demographicsSource => translate('demographics_source');
  String get demographicsRoomType => translate('demographics_room_type');
  String get declarationDd10 => translate('declaration_dd10');
  String get declarationNa17 => translate('declaration_na17');
  String get declarationAll => translate('declaration_all');
  String get declarationDd10Desc => translate('declaration_dd10_desc');
  String get declarationNa17Desc => translate('declaration_na17_desc');
  String get declarationAllDesc => translate('declaration_all_desc');
  String get groupStatusPending => translate('group_status_pending');
  String get groupStatusConfirmed => translate('group_status_confirmed');
  String get groupStatusCheckedIn => translate('group_status_checked_in');
  String get groupStatusCheckedOut => translate('group_status_checked_out');
  String get groupStatusCancelled => translate('group_status_cancelled');
  String get minibarCharged => translate('minibar_charged');
  String get minibarUncharged => translate('minibar_uncharged');
  String get guestNumber => translate('guest_number');
  String get reportMetricOccupancy => translate('report_metric_occupancy');
  String get reportMetricBookings => translate('report_metric_bookings');
  String get reportMetricGuests => translate('report_metric_guests');
  String get monthLabel => translate('month_label');
  String get entryTypeIncome => translate('entry_type_income');
  String get entryTypeExpense => translate('entry_type_expense');
  String get searchMinChars => translate('search_min_chars');
  String get guestAddedSuccess => translate('guest_added_success');
  String get guestUpdatedSuccess => translate('guest_updated_success');
  String get errorNoNetwork => translate('error_no_network');
  String get errorPhoneRegistered => translate('error_phone_registered');
  String get errorIdRegistered => translate('error_id_registered');
  String get errorPhoneDigits => translate('error_phone_digits');
  String get errorCannotDeleteGuest => translate('error_cannot_delete_guest');
  String get errorGuestNotFound => translate('error_guest_not_found');
  String get errorGeneric => translate('error_generic');
  String get errorWrongCredentials => translate('error_wrong_credentials');
  String get errorFolioLoad => translate('error_folio_load');
  String get errorChargeAdd => translate('error_charge_add');
  String get errorChargeVoid => translate('error_charge_void');
  String get errorNoBookingSelected => translate('error_no_booking_selected');
  String get errorEmptyCart => translate('error_empty_cart');
  String get errorRoomExists => translate('error_room_exists');
  String get errorCannotDeleteRoom => translate('error_cannot_delete_room');
  String get errorReportExport => translate('error_report_export');
  String get biometricAuthenticateLogin => translate('biometric_authenticate_login');
  String get biometricFingerprint => translate('biometric_fingerprint');
  String get biometricIris => translate('biometric_iris');
  String get biometricGeneric => translate('biometric_generic');
  String get dateToday => translate('date_today');
  String get dateTomorrow => translate('date_tomorrow');
  String get dateYesterday => translate('date_yesterday');
  String get dateInDays => translate('date_in_days');
  String get dateDaysAgo => translate('date_days_ago');
  String get daySunday => translate('day_sunday');
  String get dayMonday => translate('day_monday');
  String get dayTuesday => translate('day_tuesday');
  String get dayWednesday => translate('day_wednesday');
  String get dayThursday => translate('day_thursday');
  String get dayFriday => translate('day_friday');
  String get daySaturday => translate('day_saturday');
  String get errorBookingConflict => translate('error_booking_conflict');
  String get errorCache => translate('error_cache');
  String get errorOffline => translate('error_offline');
  String get errorConnectionTimeout => translate('error_connection_timeout');
  String get errorNoConnection => translate('error_no_connection');
  String get errorRequestCancelled => translate('error_request_cancelled');
  String get errorUnknown => translate('error_unknown');
  String get errorInvalidData => translate('error_invalid_data');
  String get errorSessionExpired => translate('error_session_expired');
  String get errorNoPermission => translate('error_no_permission');
  String get errorNotFound => translate('error_not_found');
  String get errorConflict => translate('error_conflict');
  String get errorServer => translate('error_server');

}

// Vietnamese translations
const Map<String, String> _viTranslations = {
  // ===== COMMON =====
  'app_name': 'Hoàng Lâm Heritage Suites',
  'home': 'Trang chủ',
  'bookings': 'Đặt phòng',
  'finance': 'Tài chính',
  'settings': 'Cài đặt',
  'login': 'Đăng nhập',
  'logout': 'Đăng xuất',
  'cancel': 'Hủy',
  'save': 'Lưu',
  'confirm': 'Xác nhận',
  'delete': 'Xóa',
  'edit': 'Sửa',
  'add': 'Thêm',
  'search': 'Tìm kiếm',
  'loading': 'Đang tải...',
  'error': 'Lỗi',
  'success': 'Thành công',
  'retry': 'Thử lại',
  'no_data': 'Không có dữ liệu',
  'feature_coming_soon': 'Tính năng sắp ra mắt',
  'offline': 'Đang offline',
  'close': 'Đóng',
  'continue': 'Tiếp tục',
  'please': 'Vui lòng',
  'are_you_sure': 'Bạn có chắc',
  'action_cannot_be_undone': 'Hành động này không thể hoàn tác.',
  'error_occurred': 'Đã xảy ra lỗi',
  'error_try_again': 'Đã xảy ra lỗi. Vui lòng thử lại.',
  'update': 'Cập nhật',
  'create': 'Tạo',
  'view_all': 'Xem tất cả',
  'all': 'Tất cả',
  'filter': 'Lọc',
  'status': 'Trạng thái',
  'advanced_filter': 'Bộ lọc nâng cao',
  'booking_source': 'Nguồn đặt phòng',
  'clear_filter': 'Xóa bộ lọc',
  'total': 'Tổng',
  'active': 'Hoạt động',
  'inactive': 'Vô hiệu',
  'enable': 'Kích hoạt',
  'later': 'Để sau',
  'open': 'Mở',
  'copied': 'Đã sao chép',
  'reset': 'Đặt lại',
  'info': 'Thông tin',
  'name': 'Tên',
  'version': 'Phiên bản',

  // ===== ROOM STATUS =====
  'available': 'Trống',
  'occupied': 'Có khách',
  'cleaning': 'Đang dọn',
  'maintenance': 'Bảo trì',
  'blocked': 'Khóa',

  // ===== AUTH =====
  'login_subtitle': 'Đăng nhập để quản lý',
  'username_label': 'Tên đăng nhập',
  'username_hint': 'Nhập tên đăng nhập',
  'username_required': 'Vui lòng nhập tên đăng nhập',
  'password_label': 'Mật khẩu',
  'password_required': 'Vui lòng nhập mật khẩu',
  'password_min_length': 'Mật khẩu phải có ít nhất 6 ký tự',
  'login_button': 'Đăng nhập',
  'forgot_password': 'Quên mật khẩu?',
  'contact_admin_reset_password': 'Vui lòng liên hệ quản trị viên để đặt lại mật khẩu',
  'enable_biometric_title': 'Kích hoạt đăng nhập sinh trắc học',
  'enable_biometric_message': 'Bạn có muốn sử dụng vân tay hoặc Face ID để đăng nhập nhanh hơn trong lần tới?',
  'biometric_enabled': 'Đã kích hoạt đăng nhập sinh trắc học',
  'biometric_auth_failed': 'Xác thực sinh trắc học thất bại',
  'authenticating': 'Đang xác thực...',
  'login_with': 'Đăng nhập bằng',
  'change_password': 'Đổi mật khẩu',
  'new_password_min_length': 'Mật khẩu mới phải có ít nhất 6 ký tự',
  'password_change_success': 'Mật khẩu đã được thay đổi thành công',
  'password_change_failed': 'Không thể thay đổi mật khẩu. Vui lòng kiểm tra lại.',
  'current_password': 'Mật khẩu hiện tại',
  'new_password': 'Mật khẩu mới',
  'confirm_new_password': 'Xác nhận mật khẩu mới',
  'please_enter_current_password': 'Vui lòng nhập mật khẩu hiện tại',
  'please_enter_new_password': 'Vui lòng nhập mật khẩu mới',
  'please_confirm_new_password': 'Vui lòng xác nhận mật khẩu mới',
  'new_password_must_be_different': 'Mật khẩu mới phải khác mật khẩu hiện tại',
  'passwords_do_not_match': 'Mật khẩu xác nhận không khớp',
  'apartment_management': 'Quản lý căn hộ',

  // ===== DASHBOARD =====
  'notifications': 'Thông báo',
  'account': 'Tài khoản',
  'room_status': 'Trạng thái phòng',
  'upcoming_checkout': 'Sắp check-out',
  'upcoming_checkin': 'Sắp check-in',
  'available_rooms': 'Phòng trống',
  'rooms_available': 'Phòng trống',
  'today_check_ins': 'Check-in hôm nay',
  'today_check_outs': 'Check-out hôm nay',
  'today_revenue': 'Doanh thu hôm nay',
  'occupancy_rate': 'Tỷ lệ lấp đầy',
  'checkout_today': 'Check-out hôm nay',
  'checkin_today': 'Check-in hôm nay',
  'dashboard_load_error': 'Không thể tải dữ liệu dashboard',
  'new_booking': 'Đặt phòng mới',
  'no_rooms': 'Chưa có phòng nào',
  'room_load_error': 'Lỗi tải dữ liệu phòng',
  'no_checkout_today': 'Không có check-out hôm nay',
  'no_checkin_today': 'Không có check-in hôm nay',
  'guest': 'Khách',

  // ===== BOOKING =====
  'check_in': 'Nhận phòng',
  'check_out': 'Trả phòng',
  'guest_name': 'Tên khách',
  'guest_phone': 'Số điện thoại',
  'room_number': 'Số phòng',
  'nights': 'đêm',
  'total_amount': 'Tổng tiền',
  'deposit': 'Đặt cọc',
  'balance': 'Còn lại',
  'booking_list': 'Danh sách đặt phòng',
  'data_load_error': 'Lỗi tải dữ liệu',
  'search_guest_room': 'Tìm theo tên khách, số phòng...',
  'no_bookings': 'Không có đặt phòng',
  'no_bookings_for_filter': 'Chưa có đặt phòng nào cho bộ lọc này',
  'edit_booking': 'Sửa đặt phòng',
  'room_required': 'Phòng *',
  'please_select_room': 'Vui lòng chọn phòng',
  'guest_required': 'Khách hàng *',
  'please_select_create_guest': 'Vui lòng chọn hoặc tạo khách hàng',
  'booking_dates': 'Ngày đặt phòng',
  'number_of_nights': 'Số đêm',
  'create_booking': 'Tạo đặt phòng',
  'booking_details': 'Chi tiết đặt phòng',
  'go_back': 'Quay lại',
  'guest_info': 'Thông tin khách',
  'guest_count': 'Số khách',
  'people': 'người',
  'time_label': 'Thời gian',
  'expected_checkin': 'Check-in dự kiến',
  'expected_checkout': 'Check-out dự kiến',
  'actual_checkin': 'Check-in thực tế',
  'actual_checkout': 'Check-out thực tế',
  'payment': 'Thanh toán',
  'rate_per_night': 'Giá/đêm',
  'deposit_paid': 'Đã đặt cọc',
  'balance_due': 'Còn lại',
  'payment_method': 'Phương thức',
  'booking_info': 'Thông tin đặt phòng',
  'source': 'Nguồn',
  'booking_date': 'Ngày đặt',
  'special_requests': 'Yêu cầu đặc biệt',
  'internal_notes': 'Ghi chú nội bộ',
  'select_booking': 'Chọn đặt phòng',
  'booking_list_load_error': 'Lỗi tải danh sách đặt phòng',
  'book_room': 'Đặt phòng',

  // ===== EARLY/LATE FEES =====
  'early_check_in': 'Nhận sớm',
  'late_check_out': 'Trả muộn',
  'early_check_in_fee': 'Phí nhận sớm',
  'late_check_out_fee': 'Phí trả muộn',
  'quick_select': 'Chọn nhanh',
  'number_of_hours': 'Số giờ',
  'hours': 'giờ',
  'fee_amount': 'Số tiền phí',
  'optional_notes': 'Ghi chú (không bắt buộc)',
  'create_folio_item': 'Tạo mục trong folio',
  'track_in_financials': 'Theo dõi trong tài chính',
  'max_hours_24': 'Tối đa 24 giờ',
  'invalid_value': 'Giá trị không hợp lệ',
  'required': 'Bắt buộc',
  'record_early_check_in': 'Ghi nhận nhận sớm',
  'record_late_check_out': 'Ghi nhận trả muộn',
  'early_check_in_recorded': 'Đã ghi nhận phí nhận sớm',
  'late_check_out_recorded': 'Đã ghi nhận phí trả muộn',
  'fees_and_charges': 'Phí & Phụ thu',

  // ===== ROOM =====
  'room_management': 'Quản lý phòng',
  'hide_inactive_rooms': 'Ẩn phòng vô hiệu',
  'show_inactive_rooms': 'Hiện phòng vô hiệu',
  'search_rooms': 'Tìm kiếm phòng...',
  'room_not_found': 'Không tìm thấy phòng',
  'no_rooms_yet': 'Chưa có phòng nào',
  'add_first_room': 'Thêm phòng đầu tiên',
  'floor': 'Tầng',
  'add_room': 'Thêm phòng',
  'deactivate': 'Vô hiệu hóa',
  'activate': 'Kích hoạt',
  'room_deactivated': 'Đã vô hiệu hóa phòng',
  'room_activated': 'Đã kích hoạt phòng',
  'delete_room': 'Xóa phòng?',
  'room_deleted': 'Đã xóa phòng',
  'edit_room': 'Sửa phòng',
  'add_new_room': 'Thêm phòng mới',
  'room_number_label': 'Số phòng *',
  'please_enter_room_number': 'Vui lòng nhập số phòng',
  'room_name_optional': 'Tên phòng (tùy chọn)',
  'example_room_name': 'Ví dụ: Phòng Hướng Biển',
  'room_type': 'Loại phòng *',
  'please_select_room_type': 'Vui lòng chọn loại phòng',
  'cannot_load_room_types': 'Không thể tải loại phòng',
  'amenities': 'Tiện nghi',
  'air_conditioning': 'Điều hòa',
  'safe': 'Két sắt',
  'bathtub': 'Bồn tắm',
  'hair_dryer': 'Máy sấy tóc',
  'work_desk': 'Bàn làm việc',
  'balcony': 'Ban công',
  'room_notes': 'Ghi chú về phòng...',
  'room_is_active': 'Phòng đang hoạt động',
  'room_can_be_booked': 'Phòng có thể được đặt',
  'room_disabled': 'Phòng bị vô hiệu hóa',
  'room_updated': 'Đã cập nhật phòng',
  'room_added': 'Đã thêm phòng',
  'confirm_delete_room': 'Bạn có chắc muốn xóa phòng',
  'change_status': 'Đổi trạng thái',
  'room_info': 'Thông tin phòng',
  'undefined': 'Chưa xác định',
  'has_guests': 'Đang có khách',
  'view_booking_details': 'Xem chi tiết đặt phòng',
  'history': 'Lịch sử',
  'no_history': 'Chưa có lịch sử',

  // ===== GUEST =====
  'guests': 'Khách hàng',
  'add_guest': 'Thêm khách hàng',
  'search_guests': 'Tìm kiếm khách hàng...',
  'guest_not_found': 'Không tìm thấy khách hàng',
  'no_guests_yet': 'Chưa có khách hàng nào',
  'try_different_search': 'Thử tìm kiếm với từ khóa khác',
  'press_to_add_guest': 'Nhấn + để thêm khách hàng mới',
  'edit_guest': 'Chỉnh sửa',
  'contact_info': 'Thông tin liên hệ',
  'phone_number': 'Số điện thoại',
  'address': 'Địa chỉ',
  'identity_document': 'Giấy tờ tùy thân',
  'document_type': 'Loại giấy tờ',
  'document_number': 'Số giấy tờ',
  'issued_by': 'Nơi cấp',
  'issue_date': 'Ngày cấp',
  'personal_info': 'Thông tin cá nhân',
  'nationality': 'Quốc tịch',
  'gender': 'Giới tính',
  'date_of_birth': 'Ngày sinh',
  'age': 'Tuổi',
  'years_old': 'tuổi',
  'call': 'Gọi điện',
  'remove_vip': 'Bỏ VIP',
  'mark_vip': 'Đánh dấu VIP',
  'marked_as_vip': 'đã được đánh dấu VIP',
  'vip_removed': 'đã bỏ đánh dấu VIP',
  'edit_info': 'Chỉnh sửa thông tin',
  'delete_guest': 'Xóa khách hàng',
  'confirm_delete': 'Xác nhận xóa',
  'confirm_delete_guest': 'Bạn có chắc chắn muốn xóa khách hàng',
  'guest_deleted': 'Đã xóa khách hàng',
  'edit_guest_title': 'Chỉnh sửa khách hàng',
  'required_info': 'Thông tin bắt buộc',
  'full_name': 'Họ và tên',
  'please_enter_full_name': 'Vui lòng nhập họ và tên',
  'full_name_min_length': 'Họ và tên phải có ít nhất 2 ký tự',
  'please_enter_phone': 'Vui lòng nhập số điện thoại',
  'phone_must_be_10': 'Số điện thoại phải có 10-11 số',
  'phone_must_start_with_0': 'Số điện thoại phải bắt đầu bằng 0',
  'invalid_email': 'Email không hợp lệ',
  'not_specified': 'Không xác định',
  'city': 'Thành phố',
  'preferences_hint': 'Sở thích, yêu cầu đặc biệt...',
  'save_changes': 'Lưu thay đổi',
  'guest_info_updated': 'Đã cập nhật thông tin khách hàng',
  'new_guest_added': 'Đã thêm khách hàng mới',
  'select_from_list': 'Chọn từ danh sách',

  // ===== FINANCE =====
  'income': 'Thu nhập',
  'expense': 'Chi phí',
  'profit': 'Lợi nhuận',
  'today': 'Hôm nay',
  'this_month': 'Tháng này',
  'reports': 'Báo cáo',
  'month': 'Tháng',

  // ===== SETTINGS =====
  'security': 'Bảo mật',
  'enabled': 'Đã bật',
  'faster_login_biometric': 'Đăng nhập nhanh hơn với sinh trắc học',
  'biometric_login_enabled': 'Đã bật đăng nhập sinh trắc học',
  'biometric_login_disabled': 'Đã tắt đăng nhập sinh trắc học',
  'property_management': 'Quản lý căn hộ',
  'add_edit_delete_rooms': 'Thêm, sửa, xóa phòng',
  'price_management': 'Quản lý giá',
  'rate_plans_promotions': 'Gói giá, giá theo ngày, khuyến mãi',
  'general_settings': 'Cài đặt chung',
  'theme': 'Giao diện',
  'light': 'Sáng',
  'dark': 'Tối',
  'system_default': 'Theo hệ thống',
  'language': 'Ngôn ngữ',
  'vietnamese': 'Tiếng Việt',
  'text_size': 'Cỡ chữ',
  'small': 'Nhỏ',
  'normal': 'Bình thường',
  'large': 'Lớn',
  'extra_large': 'Rất lớn',
  'notifications_settings': 'Thông báo',
  'room_cleaning': 'Dọn phòng',
  'all_off': 'Tắt tất cả',
  'management': 'Quản lý',
  'night_audit': 'Chốt ca đêm',
  'check_daily_figures': 'Kiểm tra số liệu cuối ngày',
  'residence_declaration': 'Khai báo lưu trú',
  'export_guest_list_police': 'Xuất danh sách khách cho công an',
  'financial_categories': 'Danh mục thu chi',
  'account_management': 'Quản lý tài khoản',
  'data': 'Dữ liệu',
  'sync_data': 'Đồng bộ dữ liệu',
  'last_update_just_now': 'Cập nhật lần cuối: Vừa xong',
  'backup': 'Sao lưu',
  'support': 'Hỗ trợ',
  'user_guide': 'Hướng dẫn sử dụng',
  'about_app': 'Thông tin ứng dụng',
  'user': 'Người dùng',
  'staff': 'Nhân viên',
  'select_theme': 'Chọn giao diện',
  'auto_phone_settings': 'Tự động theo cài đặt điện thoại',
  'select_language': 'Chọn ngôn ngữ',
  'notification_settings': 'Cài đặt thông báo',
  'push_notifications': 'Thông báo đẩy',
  'receive_push_notifications': 'Nhận thông báo đẩy từ máy chủ',
  'local_reminders': 'Nhắc nhở cục bộ',
  'tap_to_retry': 'Nhấn để thử lại',
  'checkin_reminder': 'Nhắc nhở check-in',
  'notify_checkin_today': 'Thông báo khi có khách check-in hôm nay',
  'checkout_reminder': 'Nhắc nhở check-out',
  'notify_checkout_today': 'Thông báo khi có khách check-out hôm nay',
  'cleaning_reminder': 'Nhắc nhở dọn phòng',
  'notify_room_needs_cleaning': 'Thông báo khi có phòng cần dọn dẹp',
  'confirm_logout': 'Xác nhận đăng xuất?',
  'confirm_logout_message': 'Bạn có chắc muốn đăng xuất khỏi ứng dụng?',

  // ===== HOUSEKEEPING =====
  'housekeeping_tasks': 'Công việc Housekeeping',
  'my_tasks': 'Của tôi',
  'no_tasks': 'Không có công việc',
  'no_tasks_scheduled_today': 'Không có công việc nào được lên lịch cho hôm nay',
  'no_tasks_created': 'Chưa có công việc nào được tạo',
  'no_tasks_assigned': 'Bạn chưa được phân công công việc nào',
  'pending': 'Chờ xử lý',
  'in_progress': 'Đang làm',
  'completed': 'Hoàn thành',
  'create_new_task': 'Tạo công việc mới',
  'urgent': 'Khẩn cấp',
  'no_urgent_requests': 'Không có yêu cầu khẩn cấp',
  'no_urgent_maintenance_requests': 'Hiện tại không có yêu cầu bảo trì khẩn cấp nào',
  'no_maintenance_requests': 'Không có yêu cầu bảo trì',
  'no_maintenance_requests_created': 'Chưa có yêu cầu bảo trì nào được tạo',
  'no_your_requests': 'Không có yêu cầu của bạn',
  'no_assigned_maintenance_requests': 'Bạn chưa được phân công yêu cầu bảo trì nào',
  'assigned': 'Đã phân công',
  'on_hold': 'Tạm hoãn',
  'completed_cancelled': 'Hoàn thành/Hủy',
  'create_request': 'Tạo yêu cầu',
  'edit_request': 'Sửa yêu cầu',
  'create_maintenance_request': 'Tạo yêu cầu bảo trì',
  'room': 'Phòng',
  'cannot_load_room_list': 'Không thể tải danh sách phòng',
  'title': 'Tiêu đề',
  'describe_issue_briefly': 'Mô tả ngắn gọn vấn đề',
  'please_enter_title': 'Vui lòng nhập tiêu đề',
  'category': 'Danh mục',
  'priority_level': 'Mức ưu tiên',
  'detailed_description': 'Mô tả chi tiết',
  'describe_issue_in_detail': 'Mô tả chi tiết vấn đề cần xử lý...',
  'please_enter_description': 'Vui lòng nhập mô tả',
  'estimated_cost_optional': 'Chi phí ước tính (tùy chọn)',
  'request_updated': 'Đã cập nhật yêu cầu',
  'new_maintenance_request_created': 'Đã tạo yêu cầu bảo trì mới',
  'select_room': 'Chọn phòng',
  'hold': 'Tạm hoãn',
  'resume': 'Tiếp tục',
  'request_info': 'Thông tin yêu cầu',
  'assignee': 'Người thực hiện',
  'not_assigned': 'Chưa được phân công',
  'reporter': 'Người báo cáo',
  'description': 'Mô tả',
  'resolution_result': 'Kết quả xử lý',
  'created_at': 'Tạo lúc',
  'completed_at': 'Hoàn thành lúc',
  'updated_at': 'Cập nhật lúc',
  'assign': 'Phân công',
  'maintenance_request_completed': 'Đã hoàn thành yêu cầu bảo trì',
  'request_on_hold': 'Đã tạm hoãn yêu cầu',
  'continue_request': 'Tiếp tục yêu cầu',
  'continue_request_confirmation': 'Bạn có muốn tiếp tục xử lý yêu cầu này?',
  'request_continued': 'Đã tiếp tục yêu cầu',
  'cancel_request': 'Hủy yêu cầu',
  'cancel_request_confirmation': 'Bạn có chắc muốn hủy yêu cầu bảo trì này?',
  'no': 'Không',
  'request_cancelled': 'Đã hủy yêu cầu',
  'complete_request': 'Hoàn thành yêu cầu',
  'enter_resolution_notes': 'Nhập ghi chú về kết quả xử lý (tùy chọn):',
  'describe_work_done': 'Mô tả công việc đã thực hiện...',
  'hold_request': 'Tạm hoãn yêu cầu',
  'enter_hold_reason': 'Nhập lý do tạm hoãn (tùy chọn):',
  'reason': 'Lý do...',
  'assignment_in_development': 'Chức năng phân công đang phát triển',
  'complete_request_confirmation': 'Bạn có chắc đã hoàn thành yêu cầu bảo trì này?',
  'task_info': 'Thông tin công việc',
  'task_type': 'Loại công việc',
  'scheduled_date': 'Ngày dự kiến',
  'booking_code': 'Mã đặt phòng',
  'creator': 'Người tạo',
  'notes': 'Ghi chú',
  'task_assigned': 'Đã phân công công việc',
  'task_completed': 'Đã hoàn thành công việc',
  'verify_task': 'Xác nhận công việc',
  'verify_task_confirmation': 'Bạn có chắc muốn xác nhận công việc này đã hoàn thành tốt?',
  'task_verified': 'Đã xác nhận công việc',
  'delete_task': 'Xóa công việc',
  'delete_task_confirmation': 'Bạn có chắc muốn xóa công việc này?',
  'task_deleted': 'Đã xóa công việc',
  'edit_task': 'Sửa công việc',
  'create_task': 'Tạo công việc',
  'enter_notes_optional': 'Nhập ghi chú (tùy chọn)',
  'task_updated': 'Đã cập nhật công việc',
  'new_task_created': 'Đã tạo công việc mới',
  'verify': 'Xác nhận',

  // ===== NIGHT AUDIT =====
  'night_audit_title': 'Kiểm toán cuối ngày',
  'history_label': 'Lịch sử',
  'select_date': 'Chọn ngày',
  'audit_load_error': 'Lỗi tải kiểm toán',
  'performed_by': 'Thực hiện bởi',
  'not_completed': 'Chưa hoàn thành',
  'occupancy': 'lấp đầy',
  'room_statistics': 'Thống kê phòng',
  'total_rooms': 'Tổng phòng',
  'being_cleaned': 'Đang dọn',
  'booking_statistics': 'Thống kê đặt phòng',
  'new_bookings': 'Đặt mới',
  'no_show': 'Không đến',
  'financial_overview': 'Tổng quan tài chính',

  // ===== PRICING =====
  'edit_rate_plan': 'Sửa gói giá',
  'add_rate_plan': 'Thêm gói giá',
  'delete_rate_plan': 'Xóa gói giá',
  'basic_info': 'Thông tin cơ bản',
  'rate_plan_name': 'Tên gói giá *',
  'rate_plan_hint': 'VD: Giá cuối tuần, Giá mùa hè...',
  'please_enter_rate_plan_name': 'Vui lòng nhập tên gói giá',
  'english_name_optional': 'Tên tiếng Anh (tùy chọn)',
  'base_rate_per_night': 'Giá cơ bản/đêm *',
  'vnd': 'VNĐ',
  'please_enter_rate': 'Vui lòng nhập giá',
  'rate_must_be_positive': 'Giá phải lớn hơn 0',
  'stay_requirements': 'Yêu cầu lưu trú',
  'min_nights': 'Số đêm tối thiểu',
  'max_nights': 'Số đêm tối đa',
  'no_limit': 'Không giới hạn',
  'advance_booking_optional': 'Số ngày đặt trước (tùy chọn)',
  'advance_booking_hint': 'VD: 7 (đặt trước 7 ngày)',
  'cancellation_policy': 'Chính sách hủy',
  'validity_period': 'Thời gian hiệu lực',
  'from_date': 'Từ ngày',
  'to_date': 'Đến ngày',
  'includes_breakfast': 'Bao gồm bữa sáng',
  'rate_plan_includes_free_breakfast': 'Gói giá này bao gồm bữa sáng miễn phí',
  'is_active': 'Đang hoạt động',
  'show_apply_rate_plan': 'Hiển thị và áp dụng gói giá này',
  'description_optional': 'Mô tả (tùy chọn)',
  'rate_plan_notes': 'Ghi chú thêm về gói giá...',
  'create_rate_plan': 'Tạo gói giá',
  'rate_plan_updated': 'Đã cập nhật gói giá',
  'rate_plan_created': 'Đã tạo gói giá',
  'delete_rate_plan_confirm': 'Xóa gói giá?',
  'confirm_delete_rate_plan': 'Bạn có chắc muốn xóa gói giá',
  'rate_plan_deleted': 'Đã xóa gói giá',
  'edit_date_rate': 'Sửa giá theo ngày',
  'add_date_rate': 'Thêm giá theo ngày',
  'weekend': 'Cuối tuần',
  'holiday': 'Ngày lễ',
  'lunar_new_year': 'Tết Nguyên Đán',
  'low_season': 'Mùa thấp điểm',
  'promotion': 'Khuyến mãi',
  'special_event': 'Sự kiện đặc biệt',
  'create_for_multiple_days': 'Tạo cho nhiều ngày',
  'apply_for_date_range': 'Áp dụng cho một khoảng thời gian',
  'date_range': 'Khoảng thời gian',
  'apply_date': 'Ngày áp dụng',
  'rate_adjustment_reason': 'Lý do điều chỉnh giá',
  'rate_reason_hint': 'VD: Tết, Lễ hội, Cuối tuần...',
  'restrictions_optional': 'Hạn chế (tùy chọn)',
  'close_for_arrival': 'Đóng nhận khách',
  'no_checkin_allowed': 'Không cho phép check-in ngày này',
  'close_for_departure': 'Đóng trả phòng',
  'no_checkout_allowed': 'Không cho phép check-out ngày này',
  'min_nights_optional': 'Số đêm tối thiểu (tùy chọn)',
  'min_nights_required': 'Yêu cầu ở tối thiểu X đêm',
  'create_rates_multiple_days': 'Tạo giá cho nhiều ngày',
  'please_select_end_date': 'Vui lòng chọn ngày kết thúc',
  'date_rate_updated': 'Đã cập nhật giá theo ngày',
  'created_rates_for_days': 'Đã tạo giá cho ngày',
  'date_rate_created': 'Đã tạo giá theo ngày',
  'delete_date_rate_confirm': 'Xóa giá theo ngày?',
  'confirm_delete_date_rate': 'Bạn có chắc muốn xóa giá cho ngày',
  'date_rate_deleted': 'Đã xóa giá theo ngày',
  'all_room_types': 'Tất cả loại phòng',
  'filter_by_room_type': 'Lọc theo loại phòng',
  'select_room_type': 'Chọn loại phòng *',
  'add_rate_plan_flexible_pricing': 'Thêm gói giá để quản lý giá linh hoạt',
  'add_special_rates': 'Thêm giá đặc biệt cho ngày lễ, cuối tuần...',
  'no_arrivals': 'Không nhận khách',
  'no_departures': 'Không trả phòng',
  'rate_plans': 'Gói giá',
  'daily_rates': 'Giá theo ngày',

  // ===== DECLARATION =====
  'export_success': 'Xuất file thành công!',
  'residence_declaration_title': 'Khai báo lưu trú',
  'export_guest_list_description': 'Xuất danh sách khách lưu trú để khai báo tạm trú với công an.',
  'list_includes_guests_in_range': 'Danh sách bao gồm tất cả khách đã nhận phòng trong khoảng thời gian được chọn.',
  'today_label': 'Hôm nay',
  'yesterday': 'Hôm qua',
  'file_format': 'Định dạng file',
  'exporting': 'Đang xuất...',
  'export_list': 'Xuất danh sách',
  'cannot_open_file': 'Không thể mở file',
  'cannot_share_file': 'Không thể chia sẻ file',
  'popular': 'Phổ biến',
  'has_format': 'Có format',
  'file_exported': 'File đã được xuất',

  // ===== MINIBAR =====
  'minibar_management': 'Quản lý Minibar',
  'add_product': 'Thêm sản phẩm',
  'search_products': 'Tìm kiếm sản phẩm...',
  'edit_product': 'Chỉnh sửa sản phẩm',
  'delete_product': 'Xóa sản phẩm',
  'please_enter_product_name': 'Vui lòng nhập tên sản phẩm',
  'enter_or_select_category': 'Nhập hoặc chọn danh mục',
  'product_added': 'Thêm sản phẩm thành công',
  'confirm_delete_item': 'Bạn có chắc chắn muốn xóa',
  'product_deleted': 'Đã xóa sản phẩm',
  'inventory_management': 'Quản lý kho',
  'no_matching_products': 'Không tìm thấy sản phẩm phù hợp',
  'please_select_booking_first': 'Vui lòng chọn đặt phòng trước',

  // ===== FOLIO =====
  'hide_cancelled_items': 'Ẩn mục đã hủy',
  'show_cancelled_items': 'Hiện mục đã hủy',
  'add_charge': 'Thêm phí',
  'cancel_charge': 'Hủy phí',
  'confirm_cancel_charge': 'Bạn có chắc muốn hủy phí',
  'cancel_reason': 'Lý do hủy *',
  'enter_cancel_reason': 'Nhập lý do hủy phí',
  'please_enter_cancel_reason': 'Vui lòng nhập lý do hủy',
  'charge_cancelled_success': 'Đã hủy phí thành công',
  'cannot_cancel_charge': 'Không thể hủy phí',
  'confirm_cancel': 'Xác nhận hủy',

  // ===== REPORTS =====
  'total_revenue': 'Tổng doanh thu',
  'rooms_label': 'phòng',
  'total_available_room_nights': 'Tổng đêm phòng khả dụng',
  'total_sold_room_nights': 'Tổng đêm phòng bán',
  'room_revenue': 'Doanh thu phòng',
  'total_expense': 'Tổng chi phí',
  'total_bookings': 'Tổng đặt phòng',
  'bookings_label': 'đặt phòng',
  'total_guests': 'Tổng khách',
  'guests_label': 'khách',

  // ===== ROOM INSPECTION =====
  'room_inspection': 'Kiểm tra phòng',
  'statistics': 'Thống kê',
  'inspection_template': 'Mẫu kiểm tra',
  'requires_action': 'Cần xử lý',
  'create_inspection': 'Tạo kiểm tra',
  'inspection_details': 'Chi tiết kiểm tra',
  'start': 'Bắt đầu',
  'continue_label': 'Tiếp tục',
  'conduct_inspection': 'Tiến hành kiểm tra',
  'create_new_inspection': 'Tạo kiểm tra mới',
  'create_template': 'Tạo mẫu',
  'no_templates': 'Chưa có mẫu kiểm tra nào',
  'create_first_template': 'Tạo mẫu đầu tiên',

  // ===== GROUP BOOKING =====
  'group_booking': 'Đặt phòng đoàn',
  'confirmed_status': 'Đã xác nhận',
  'checked_in_status': 'Đang ở',
  'checked_out_status': 'Đã trả',
  'group_booking_details': 'Chi tiết đặt phòng đoàn',
  'edit_group_booking': 'Sửa đặt phòng đoàn',
  'create_group_booking': 'Tạo đặt phòng đoàn',

  // ===== PHASE 5: NOTIFICATIONS & MESSAGING =====
  'mark_all_read': 'Đánh dấu tất cả đã đọc',
  'no_notifications': 'Không có thông báo',
  'no_notifications_description': 'Khi có thông báo mới, chúng sẽ hiển thị ở đây',
  'error_loading_data': 'Không thể tải dữ liệu',
  'send_message': 'Gửi tin nhắn',
  'channel': 'Kênh',
  'no_templates_messaging': 'Chưa có mẫu tin nhắn',
  'write_custom_message': 'Viết tin nhắn tùy chỉnh',
  'write_custom_message_description': 'Soạn tin nhắn tự do cho khách',
  'message_preview': 'Xem trước tin nhắn',
  'recipient': 'Người nhận',
  'subject': 'Tiêu đề',
  'message_content': 'Nội dung',
  'send': 'Gửi',
  'message_sent_success': 'Tin nhắn đã được gửi thành công!',
  'message_sent_pending': 'Tin nhắn đang được xử lý',
  'message_send_failed': 'Gửi tin nhắn thất bại',
  'no_messages': 'Chưa có tin nhắn nào',
  'resend_message': 'Gửi lại tin nhắn',
  'resend_message_confirm': 'Bạn có muốn gửi lại tin nhắn này?',
  'message_history': 'Lịch sử tin nhắn',

  // ===== PHASE C: EXTRACTED HARDCODED STRINGS =====
  'update_status': 'Cập nhật trạng thái',
  'current_status_label': 'Trạng thái hiện tại',
  'select_new_status': 'Chọn trạng thái mới:',
  'current_label': '(hiện tại)',
  'cannot_update_room_status': 'Không thể cập nhật trạng thái phòng',
  'notes_optional': 'Ghi chú (tùy chọn)',
  'enter_notes': 'Nhập ghi chú...',
  'charge_type': 'Loại phí',
  'description_required': 'Mô tả *',
  'enter_charge_description': 'Nhập mô tả chi phí',
  'quantity_required': 'Số lượng *',
  'quantity_min_one': 'Số lượng >= 1',
  'unit_price_required': 'Đơn giá *',
  'unit_price_positive': 'Đơn giá > 0',
  'date_label': 'Ngày',
  'total_sum': 'Tổng cộng:',
  'charge_added_success': 'Đã thêm phí thành công',
  'cannot_add_charge': 'Không thể thêm phí',
  'record_label': 'Ghi nhận',
  'additional_notes_hint': 'Ghi chú thêm...',
  'options_section': 'Tùy chọn',
  'reason_label': 'Lý do',
  'item_name_label': 'Tên đồ vật *',
  'item_name_hint': 'VD: Ví da, Điện thoại...',
  'please_enter_name': 'Vui lòng nhập tên',
  'found_date_label': 'Ngày tìm thấy',
  'location_section': 'Vị trí',
  'found_location_label': 'Nơi tìm thấy *',
  'found_location_hint': 'VD: Phòng 101, Sảnh chờ...',
  'please_enter_value': 'Vui lòng nhập',
  'storage_location_label': 'Nơi lưu trữ',
  'storage_location_hint': 'VD: Tủ đồ thất lạc...',
  'contact_section': 'Liên hệ',
  'guest_contacted': 'Đã liên hệ khách',
  'contact_notes': 'Ghi chú liên hệ',
  'additional_info': 'Thông tin bổ sung',
  'estimated_value_vnd': 'Giá trị ước tính (VNĐ)',
  'add_new': 'Thêm mới',
  'item_created': 'Đã thêm mới',
  'item_updated': 'Đã cập nhật',
  'store_in_storage': 'Lưu kho',
  'item_claimed': 'Đã nhận',
  'dispose_item': 'Xử lý',
  'stored_success': 'Đã lưu vào kho',
  'claimed_success': 'Đã đánh dấu là đã nhận',
  'disposed_success': 'Đã xử lý đồ vật',
  'deposit_vnd': 'Đặt cọc (VNĐ)',
  'discount_percent': 'Giảm giá (%)',
  'deposit_paid_label': 'Đã thanh toán đặt cọc',
  'booking_created': 'Đã tạo đặt phòng',
  'please_assign_rooms_first': 'Vui lòng phân phòng trước',
  'checked_in_success': 'Đã check-in',
  'room_assignment': 'Phân phòng',
  'room_id_list': 'Danh sách ID phòng',
  'invalid_room_list': 'Danh sách phòng không hợp lệ',
  'rooms_assigned': 'Đã phân phòng',
  'category_name_required': 'Tên danh mục *',
  'category_name_hint': 'VD: Tiền điện',
  'please_enter_category_name': 'Vui lòng nhập tên danh mục',
  'english_name': 'Tên tiếng Anh',
  'icon_label': 'Biểu tượng',
  'color_label': 'Màu sắc',
  'issue_notes': 'Ghi chú vấn đề',
  'describe_issue_hint': 'Mô tả vấn đề...',
  'general_notes': 'Ghi chú chung',
  'action_required_label': 'Hành động cần thực hiện (nếu có)',
  'describe_action_hint': 'Mô tả hành động cần thực hiện...',
  'inspection_created': 'Đã tạo kiểm tra thành công',
  'template_name_required': 'Tên mẫu *',
  'template_name_hint': 'VD: Kiểm tra checkout tiêu chuẩn',
  'please_enter_template_name': 'Vui lòng nhập tên mẫu',
  'inspection_type': 'Loại kiểm tra',
  'sort_order_hint': 'VD: 1, 2, 3',
  'default_template': 'Mẫu mặc định',
  'use_as_default_template': 'Sử dụng mẫu này khi tạo kiểm tra mới',
  'checklist_items_count': 'Danh sách kiểm tra',
  'template_created': 'Đã tạo mẫu thành công',
  'edit_in_development': 'Chức năng chỉnh sửa đang phát triển',
  'template_copied': 'Đã sao chép mẫu thành công',
  'add_checklist_item': 'Thêm mục kiểm tra',
  'item_name_required': 'Tên mục *',
  'bedroom': 'Phòng ngủ',
  'bathroom': 'Phòng tắm',
  'electronics': 'Điện tử',
  'safety_label': 'An toàn',
  'other_category': 'Khác',
  'please_add_checklist_item': 'Vui lòng thêm ít nhất một mục kiểm tra',
  'stats_recalculated': 'Đã tính lại thống kê',
  'close_audit': 'Đóng kiểm toán',
  'close_audit_confirmation': 'Sau khi đóng, bạn sẽ không thể chỉnh sửa kiểm toán này.\n\nBạn có chắc chắn muốn đóng?',
  'audit_closed': 'Đã đóng kiểm toán',
  'assign_repair': 'Phân công sửa chữa',
  'self_assign': 'Tự nhận việc',
  'staff_load_error': 'Lỗi tải danh sách nhân viên',
  'no_staff_available': 'Không có nhân viên',
  'on_sale': 'Đang bán',
  'not_for_sale': 'Ngừng bán',
  'charge_marked_success': 'Đã đánh dấu charge thành công',
  'payment_success': 'Thanh toán thành công',
  'save_file_error': 'Lỗi lưu file',
  'no_data_in_range': 'Không có dữ liệu trong khoảng thời gian này',
  'no_expenses_in_range': 'Không có chi phí trong khoảng thời gian này',
  'backup_in_development': 'Tính năng sao lưu đang phát triển',
  'search_staff_hint': 'Tìm kiếm theo tên, username, SĐT...',
  'stays_label': 'Lượt ở',
  'room_info_not_found': 'Không tìm thấy thông tin phòng',
  'booking_info_not_found': 'Không tìm thấy thông tin đặt phòng',
  'task_info_not_found': 'Không tìm thấy thông tin công việc',
  'maintenance_not_found': 'Không tìm thấy yêu cầu bảo trì',
  'lost_item_not_found': 'Không tìm thấy đồ thất lạc',
  'rate_plan_not_found': 'Không tìm thấy gói giá',
  'date_rate_not_found': 'Không tìm thấy giá theo ngày',
  'page_not_found': 'Không tìm thấy trang',
  'go_home': 'Về trang chủ',

  // ===== PHASE C2: ADDITIONAL EXTRACTED STRINGS =====
  'contact_label': 'Liên hệ',
  'contact_person': 'Người liên hệ',
  'assigned_rooms': 'Phòng đã phân',
  'paid': 'Đã thanh toán',
  'unpaid': 'Chưa thanh toán',
  'amount': 'Số tiền',
  'select_staff': 'Chọn nhân viên',
  'just_now': 'Vừa xong',
  'minutes_ago': 'phút trước',
  'hours_ago': 'giờ trước',
  'days_ago': 'ngày trước',
  'last_month': 'Tháng trước',
  'this_year': 'Năm nay',
  'seven_days': '7 ngày',
  'thirty_days': '30 ngày',
  'ninety_days': '90 ngày',
  'last_7_days': '7 ngày qua',
  'last_30_days': '30 ngày qua',
  'claimed_date': 'Ngày nhận',
  'deposit_amount': 'Số tiền cọc',
  'cash': 'Tiền mặt',
  'bank_transfer': 'Chuyển khoản',
  'record_deposit': 'Ghi nhận đặt cọc',
  'cost_price': 'Giá vốn',
  'selling_price_required': 'Giá bán *',
  'profit_margin': 'Biên lợi nhuận',
  'room_charges': 'Tiền phòng',
  'additional_charges': 'Phí bổ sung',
  'total_charges': 'Tổng chi phí',
  'remaining_balance': 'Còn lại',
  'guest_owes': 'Khách còn nợ',
  'outstanding_balance': 'Còn nợ',
  'no_deposit': 'Chưa cọc',
  'deposit_short': 'Thiếu cọc',
  'deposit_paid_status': 'Đã cọc',
  'required_amount': 'Yêu cầu',
  'amount_short': 'Còn thiếu',
  'record_deposit_btn': 'Ghi cọc',
  'no_pending_deposits': 'Không có khoản cọc nào còn thiếu',
  'currency_type': 'Loại tiền',
  'exchange_rate': 'Tỷ giá',
  'confirm_payment': 'Xác nhận thanh toán',
  'vnd_per_night': 'VNĐ/đêm',
  'reference_code': 'Mã tham chiếu',
  'method_label': 'Phương thức',
  'no_income_categories': 'Chưa có danh mục thu',
  'no_expense_categories': 'Chưa có danh mục chi',
  'category_hidden': 'Đã ẩn danh mục',
  'category_shown': 'Đã hiện danh mục',
  'view_financial_categories': 'Xem danh mục thu, chi',
  'group_info': 'Thông tin đoàn',
  'group_name_required': 'Tên đoàn *',
  'number_of_rooms': 'Số phòng *',
  'number_of_guests': 'Số khách *',
  'no_products': 'Không có sản phẩm',
  'clear_cart': 'Xóa giỏ hàng',
  'confirm_clear_cart': 'Bạn có chắc chắn muốn xóa tất cả sản phẩm trong giỏ hàng?',
  'product_updated_success': 'Cập nhật sản phẩm thành công',
  'confirm_delete_product': 'Bạn có chắc chắn muốn xóa sản phẩm này?',
  'occupancy_percent': '% lấp đầy',
  'export_report': 'Xuất báo cáo',
  'average_occupancy': 'Công suất trung bình',
  'total_spending': 'Tổng chi',
  'hotel_owner': 'Chủ khách sạn',
  'manager_role': 'Quản lý',
  'housekeeping_role': 'Phòng buồng',
  'view_staff_list': 'Xem danh sách nhân sự',
  'booking_history': 'Lịch sử đặt phòng',
  'times_count': 'lần',
  'create_new_guest': 'Tạo khách hàng mới',
  'find_guest': 'Tìm khách hàng',
  'min_2_characters': 'Nhập ít nhất 2 ký tự',
  'select_booking_source': 'Chọn nguồn đặt phòng',
  'no_charges': 'Chưa có phí nào',
  'items_count': 'mục',
  'voided': 'Đã hủy',
  'by_label': 'Bởi',
  'paid_short': 'Đã TT',
  'marked_notifications_read': 'Đã đánh dấu thông báo đã đọc',
  'app_description': 'Ứng dụng quản lý căn hộ dịch vụ Hoàng Lâm Heritage Suites',
  'developed_by': 'Phát triển bởi: Duy Lâm',
  'copyright_notice': '© 2024 Hoàng Lâm Heritage Suites.\nĐã đăng ký bản quyền.',
  'dd10_form_description': 'Mẫu ĐD10 (Nghị định 144/2021): Sổ quản lý lưu trú',
  'na17_form_description': 'Mẫu NA17 (Thông tư 04/2015): Phiếu khai báo tạm trú người nước ngoài',
  'form_type': 'Loại biểu mẫu',
  'inspection_info': 'Thông tin kiểm tra',
  'room_id_required': 'ID Phòng *',
  'inspection_date_label': 'Ngày kiểm tra',
  'inspection_template_optional': 'Mẫu kiểm tra (tùy chọn)',
  'no_default_template': 'Không có mẫu mặc định',
  'confirm_delete_template': 'Bạn có chắc muốn xóa mẫu này?',
  'template_deleted': 'Đã xóa mẫu',
  'important_label': 'Quan trọng',
  'inspection_checklist': 'Danh sách kiểm tra',
  'copy_template': 'Sao chép',
  'inspection_result': 'Kết quả kiểm tra',
  'score_label': 'Điểm',
  'passed_label': 'Đạt',
  'issues_count': 'vấn đề',
  'critical_count': 'nghiêm trọng',
  'no_checklist_items': 'Chưa có mục kiểm tra nào',
  'images_label': 'Hình ảnh',
  'actions_required': 'Hành động cần thực hiện',
  'view_image': 'Xem ảnh',
  'expected_date': 'Ngày dự kiến',
  'inspector': 'Người kiểm tra',

  // ===== PHASE C3: REMAINING HARDCODED STRINGS =====

  // Common/Actions
  'undo': 'Hoàn tác',
  'share_btn': 'Chia sẻ',
  'complete_action': 'Hoàn thành',
  'resend_btn': 'Gửi lại',
  'email_label': 'Email',
  'phone_label': 'Điện thoại',
  'unknown_error': 'Không xác định',
  'confirm_delete_title': 'Xác nhận xóa',
  'confirm_cancel_label': 'Xác nhận hủy',
  'error_with_details': 'Lỗi',

  // Booking Statuses
  'status_pending': 'Chờ xác nhận',
  'status_confirmed': 'Đã xác nhận',
  'status_checked_in': 'Đã nhận phòng',
  'status_checked_out': 'Đã trả phòng',
  'status_cancelled': 'Đã hủy',
  'status_no_show': 'Không đến',

  // Financial
  'delete_category': 'Xoá danh mục',
  'category_deleted_msg': 'Đã xoá danh mục',
  'expense_label': 'Chi phí',
  'profit_label': 'Lợi nhuận',
  'discount_label': 'Giảm giá',
  'transactions_label': 'giao dịch',
  'total_amount_vnd': 'Tổng tiền (VNĐ)',

  // Group Booking
  'stay_period': 'Thời gian lưu trú',
  'additional_info_section': 'Thông tin bổ sung',
  'example_group_name': 'VD: Đoàn du lịch ABC',
  'no_group_bookings': 'Chưa có đặt phòng đoàn',
  'rooms_count_suffix': 'phòng',
  'guests_count_suffix': 'khách',
  'rooms_needed': 'Số phòng cần',
  'check_in_date_label': 'Ngày nhận phòng',
  'check_out_date_label': 'Ngày trả phòng',
  'group_updated': 'Đã cập nhật',
  'group_created': 'Đã tạo đặt phòng',
  'contact_person_required': 'Người liên hệ',
  'phone_required': 'Điện thoại',
  'assign_rooms': 'Phân phòng',
  'cancel_group': 'Hủy',
  'confirm_group': 'Xác nhận',
  'check_in_group': 'Check-in',
  'check_out_group': 'Check-out',

  // Night Audit
  'recalculate': 'Tính lại',
  'recalculate_error': 'Lỗi tính lại',
  'close_audit_btn': 'Đóng kiểm toán',
  'no_audits_yet': 'Chưa có kiểm toán nào',

  // Minibar
  'minibar_pos': 'Minibar POS',
  'no_products_in_category': 'Chưa có sản phẩm nào trong danh mục này',
  'no_sales_yet': 'Chưa có bán hàng',
  'sales_history_here': 'Lịch sử bán hàng sẽ hiển thị ở đây',
  'mark_as_charged': 'Đánh dấu đã charge',
  'payment_successful': 'Thanh toán thành công',
  'confirm_payment_title': 'Xác nhận thanh toán',
  'product_deleted_msg': 'Đã xóa sản phẩm',

  // Reports
  'occupancy_label': 'Công suất',
  'no_expenses_label': 'Không có chi phí trong khoảng thời gian này',

  // Room Inspection Stats
  'inspection_statistics': 'Thống kê kiểm tra',
  'total_inspections': 'Tổng số kiểm tra',
  'completed_inspections': 'Đã hoàn thành',
  'needs_attention': 'Cần xử lý',
  'average_score': 'Điểm trung bình',
  'issues_detected': 'Vấn đề phát hiện',
  'critical_label': 'Nghiêm trọng',
  'failed_label': 'Không đạt',
  'inspection_completed': 'Đã hoàn thành kiểm tra',
  'unchecked_critical_items': 'mục quan trọng chưa kiểm tra',

  // Lost & Found
  'filter_by_category_label': 'Lọc theo danh mục',
  'statistics_label': 'Thống kê',
  'total_count_label': 'Tổng số',
  'unclaimed_value': 'Giá trị chưa nhận',
  'by_status_label': 'Theo trạng thái',

  // Settings Help
  'help_room_management': 'Quản lý phòng',
  'help_room_management_desc': 'Xem trạng thái phòng, thay đổi trạng thái, tạo đặt phòng mới.',
  'help_bookings': 'Đặt phòng',
  'help_bookings_desc': 'Quản lý check-in, check-out, và lịch đặt phòng.',
  'help_housekeeping': 'Housekeeping',
  'help_housekeeping_desc': 'Phân công dọn phòng, theo dõi bảo trì.',
  'help_finance': 'Tài chính',
  'help_finance_desc': 'Báo cáo thu chi, quản lý folio khách.',
  'help_night_audit': 'Night Audit',
  'help_night_audit_desc': 'Kiểm toán cuối ngày, đối soát doanh thu.',
  'english': 'English',
  'push_notifications_label': 'Push notifications',

  // Pricing
  'min_nights_stay_label': 'Tối thiểu',
  'includes_breakfast_label': 'Bao gồm sáng',
  'no_arrivals_label': 'Không nhận khách',
  'no_departures_label': 'Không trả phòng',
  'schedule_conflict_warning': 'Cảnh báo trùng lịch',
  'from_date_required': 'Từ ngày',
  'to_date_required': 'Đến ngày',
  'select_date_required': 'Chọn ngày',

  // Staff
  'owner_manager_filter': 'Chủ/QL',
  'staff_member': 'Nhân viên',
  'username_field': 'Tên đăng nhập',
  'phone_field': 'Số điện thoại',
  'copied_value_msg': 'Đã sao chép',

  // Declaration
  'has_format_multi_sheet': 'Có format, nhiều sheet',
  'text_format_popular': 'Dạng text, phổ biến',

  // Folio
  'folio': 'Folio',
  'cancel_charge_title': 'Hủy phí',

  // Booking Source
  'walk_in': 'Walk-in',
  'phone_source': 'Điện thoại',
  'rank_label': 'Hạng',

  // Housekeeping Checklist Items
  'change_bed_sheets': 'Thay ga giường',
  'vacuum': 'Hút bụi',
  'mop_floor': 'Lau sàn',
  'restock_supplies': 'Bổ sung đồ dùng',
  'check_minibar': 'Kiểm tra minibar',
  'change_towels': 'Thay khăn',
  'empty_trash': 'Đổ rác',
  'restock_water': 'Bổ sung nước',
  'deep_clean_bathroom': 'Vệ sinh sâu phòng tắm',
  'wash_curtains': 'Giặt rèm',
  'clean_ac': 'Vệ sinh điều hòa',
  'clean_fridge': 'Vệ sinh tủ lạnh',
  'check_furniture': 'Kiểm tra nội thất',
  'check_cleanliness': 'Kiểm tra độ sạch',
  'check_equipment': 'Kiểm tra thiết bị',
  'check_supplies': 'Kiểm tra đồ dùng',
  'check_safety': 'Kiểm tra an toàn',
  'check_for_issues': 'Kiểm tra sự cố',
  'perform_repair': 'Thực hiện sửa chữa',
  'reinspect': 'Kiểm tra lại',
  'enter_task_notes': 'Nhập ghi chú về công việc...',

  // ===== PHASE C4: COMPREHENSIVE L10N COVERAGE =====
  // Night Audit
  'total_income': 'Tổng thu',
  'net_profit': 'Lợi nhuận ròng',
  'other_revenue': 'Doanh thu khác',
  'rooms_occupied': 'Có khách',
  'rooms_cleaning': 'Đang dọn',
  'rooms_maintenance': 'Bảo trì',
  'no_shows': 'Không đến',
  'cancellations_label': 'Hủy',
  'pending_payments': 'Thanh toán chờ',
  'payment_details': 'Chi tiết thanh toán',
  'other_payment': 'Khác',
  'notes_label': 'Ghi chú',
  'closing_audit': 'Đang đóng...',
  'audit_history': 'Lịch sử kiểm toán',
  'load_history_error': 'Lỗi tải lịch sử',
  'close_audit_error': 'Lỗi đóng kiểm toán',
  'revenue_short': 'Thu',
  'profit_short': 'Lãi',
  'status_label': 'Trạng thái',
  'room_label': 'Phòng',
  'occupancy_filled': 'lấp đầy',
  'close_button': 'Đóng',

  // Report
  'report_load_error': 'Lỗi tải báo cáo',
  'no_data_in_period': 'Không có dữ liệu trong khoảng thời gian này',
  'last_90_days': '90 ngày',
  'revenue_label': 'Doanh thu',
  'expenses_label': 'Chi phí',
  'main_kpis': 'Chỉ số chính',
  'details_label': 'Chi tiết',
  'total_expenses': 'Tổng chi phí',
  'no_expenses_in_period': 'Không có chi phí trong khoảng thời gian này',

  // Staff
  'no_search_results': 'Không tìm thấy kết quả',
  'staff_role': 'Nhân viên',
  'housekeeping_short': 'Buồng',
  'permissions_label': 'Quyền hạn',
  'no_permissions_assigned': 'Chưa phân quyền',
  'perm_view_all_data': 'Xem tất cả dữ liệu',
  'perm_manage_finance': 'Quản lý tài chính',
  'perm_manage_bookings': 'Quản lý đặt phòng',
  'perm_manage_staff': 'Quản lý nhân viên',
  'perm_edit_room_prices': 'Chỉnh giá phòng',
  'perm_night_audit': 'Kiểm toán đêm',
  'perm_reports_stats': 'Báo cáo & thống kê',
  'perm_view_bookings': 'Xem đặt phòng',
  'perm_update_room_status': 'Cập nhật trạng thái phòng',
  'perm_view_room_list': 'Xem danh sách phòng',
  'perm_update_cleaning': 'Cập nhật dọn phòng',
  'perm_report_maintenance': 'Báo cáo bảo trì',
  'copy_tooltip': 'Sao chép',
  'staying': 'Đang lưu trú',

  // Declaration
  'date_range_label': 'Khoảng thời gian',
  'file_exported_success': 'File đã được xuất thành công',
  'bookings_marked_as_declared': 'Các đặt phòng đã được đánh dấu "Đã khai báo"',
  'open_file_btn': 'Mở',
  'share_file_btn': 'Chia sẻ',
  'file_format_label': 'Định dạng file',
  'last_7_days_label': '7 ngày qua',
  'last_30_days_label': '30 ngày qua',
  'declaration_form_descriptions': '• ĐD10: Sổ quản lý lưu trú (khách Việt Nam)\n• NA17: Phiếu khai báo tạm trú (khách nước ngoài)',

  // Group Booking Detail
  'phone': 'Điện thoại',
  'email': 'Email',
  'check_in_date': 'Ngày nhận phòng',
  'check_out_date': 'Ngày trả phòng',
  'payment_label': 'Thanh toán',
  'discount_amount': 'Giảm giá',
  'yes_label': 'Có',
  'not_yet_label': 'Chưa',
  'notes_section': 'Ghi chú',
  'confirm_group_booking': 'Xác nhận đặt phòng đoàn?',
  'confirmed_msg': 'Đã xác nhận',
  'confirm_group_check_in': 'Xác nhận check-in cho đoàn',
  'confirm_group_check_out': 'Xác nhận check-out cho đoàn',
  'checked_out_success': 'Đã check-out',
  'cancelled_msg': 'Đã hủy',
  'room_id_list_hint': 'VD: 1, 2, 3 (ID phòng, cách nhau bằng dấu phẩy)',

  // Minibar
  'product': 'Sản phẩm',
  'quantity': 'Số lượng',
  'unit_price': 'Đơn giá',
  'charged': 'Đã charge',
  'not_charged': 'Chưa charge',
  'sale_details': 'Chi tiết bán hàng',
  'empty_cart': 'Giỏ hàng trống',
  'checkout_btn': 'Thanh toán',
  'clear_all': 'Xóa tất cả',
  'discontinued': 'Ngừng bán',
  'cart_title': 'Giỏ hàng',
  'product_added_success': 'Thêm sản phẩm thành công',
  'invalid': 'Không hợp lệ',
  'active_status_label': 'Hoạt động',
  'cost_amount': 'Vốn',
  'activate_label': 'Mở bán',

  // Housekeeping
  'unassigned': 'Chưa phân công',
  'complete_btn': 'Hoàn thành',
  'filter_maintenance_requests': 'Lọc yêu cầu bảo trì',
  'clear_filters': 'Xóa bộ lọc',
  'apply_btn': 'Áp dụng',
  'filter_tasks': 'Lọc công việc',
  'task_type_label': 'Loại công việc',
  'tomorrow': 'Ngày mai',

  // Guest
  'search_guest_hint': 'Tìm khách theo tên, SĐT, CCCD...',
  'id_number': 'CCCD',

  // Common Widgets
  'offline_sync_message': 'Đang offline - Dữ liệu sẽ đồng bộ khi có mạng',
  'income_expense_chart': 'Biểu đồ thu chi',
  'income_label': 'Thu',
  'expense_short': 'Chi',

  // Room Folio
  'void_charge': 'Hủy phí',
  'confirm_void_charge': 'Bạn có chắc muốn hủy phí',
  'charge_amount': 'Số tiền',
  'void_reason_required': 'Lý do hủy *',
  'enter_void_reason': 'Nhập lý do hủy phí',
  'please_enter_void_reason': 'Vui lòng nhập lý do hủy',
  'charge_voided_success': 'Đã hủy phí thành công',
  'cannot_void_charge': 'Không thể hủy phí',
  'confirm_void': 'Xác nhận hủy',

  // Inspection Template
  'default_badge': 'Mặc định',
  'duplicate_btn': 'Sao chép',
  'critical': 'Quan trọng',
  'template_duplicated': 'Đã sao chép mẫu thành công',
  'room_type_id_optional': 'ID Loại phòng (tùy chọn)',
  'room_type_id_hint': 'VD: 1, 2, 3',
  'amenities_category': 'Tiện nghi',
  'electronics_category': 'Điện tử',
  'bed_clean': 'Giường ngủ sạch sẽ',
  'bed_sheet_replaced': 'Ga trải giường thay mới',
  'pillows_blanket_clean': 'Gối và chăn sạch',
  'toilet_clean': 'Nhà vệ sinh sạch',
  'towels_complete': 'Khăn tắm đầy đủ',
  'toiletries_complete': 'Đồ dùng vệ sinh đầy đủ',
  'ac_working': 'Điều hòa hoạt động',
  'tv_working': 'TV hoạt động',
  'fridge_working': 'Tủ lạnh hoạt động',
  'create_new_inspection_template': 'Tạo mẫu kiểm tra mới',

  // Room Inspection Detail
  'booking_code_label': 'Mã đặt phòng',
  'action_required_section': 'Hành động cần thực hiện',
  'view_photo': 'Xem ảnh',
  'completed_label': 'Hoàn thành',

  // Booking Source
  'select_booking_source_hint': 'Chọn nguồn đặt phòng',

  // Phase C5
  'total_room_nights_available': 'Tổng đêm phòng khả dụng',
  'total_room_nights_sold': 'Tổng đêm phòng bán',
  'no_expenses_in_date_range': 'Không có chi phí trong khoảng thời gian này',
  'role_housekeeping_label': 'Phòng buồng',
  'rooms_suffix': 'phòng',
  'nights_suffix': 'đêm',
  'guests_suffix': 'khách',
  'transactions_suffix': 'giao dịch',
  'avg_short': 'TB',

  // Phase C6
  'excel_format_desc': 'Có format, nhiều sheet',
  'csv_format_desc': 'Dạng text, phổ biến',
  'sales_history_hint': 'Lịch sử bán hàng sẽ hiển thị ở đây',
  'guest_label': 'Khách',
  'total_price': 'Thành tiền',
  'search_product_hint': 'Tìm kiếm sản phẩm...',
  'select_booking_first': 'Vui lòng chọn đặt phòng trước',
  'clear_cart_title': 'Xóa giỏ hàng',
  'clear_cart_confirm': 'Bạn có chắc chắn muốn xóa tất cả sản phẩm trong giỏ hàng?',
  'confirm_checkout': 'Xác nhận thanh toán',
  'guest_name_label': 'Khách',
  'total_label': 'Tổng',
  'checkout_success': 'Thanh toán thành công',
  'selling_price': 'Giá bán',
  'required_field': 'Bắt buộc',
  'active_label': 'Hoạt động',
  'active_selling': 'Đang bán',
  'inactive_selling': 'Ngừng bán',
  'update_label': 'Cập nhật',
  'product_added_msg': 'Thêm sản phẩm thành công',
  'confirm_delete_product_msg': 'Bạn có chắc chắn muốn xóa',
  'product_deleted_success': 'Đã xóa sản phẩm',
  'room_count_label': 'Số phòng',
  'guest_count_label': 'Số khách',
  'deposit_label': 'Đặt cọc',
  'paid_status': 'Đã thanh toán',
  'assign_rooms_label': 'Phân phòng',
  'room_id_list_label': 'Danh sách ID phòng',
  'rooms_assigned_success': 'Đã phân phòng',
  'assign_rooms_first_msg': 'Vui lòng phân phòng trước',
  'checked_in_msg': 'Đã check-in',
  'checked_out_msg': 'Đã check-out',
  'cancelled_status': 'Đã hủy',
  'scheduled_date_label': 'Ngày dự kiến',
  'inspector_label': 'Người kiểm tra',
  'inspection_results': 'Kết quả kiểm tra',
  'pass_label': 'Đạt',
  'issues_label': 'vấn đề',
  'critical_issues_label': 'nghiêm trọng',
  'checklist_label': 'Danh sách kiểm tra',
  'edit_label': 'Chỉnh sửa',
  'duplicate_label': 'Sao chép',
  'template_created_success': 'Đã tạo mẫu thành công',
  'edit_feature_in_progress': 'Chức năng chỉnh sửa đang phát triển',
  'template_deleted_success': 'Đã xóa mẫu',
  'create_new_template_title': 'Tạo mẫu kiểm tra mới',
  'template_name_label': 'Tên mẫu',
  'inspection_type_label': 'Loại kiểm tra',
  'default_template_label': 'Mẫu mặc định',
  'default_template_hint': 'Sử dụng mẫu này khi tạo kiểm tra mới',
  'checklist_count': 'Danh sách kiểm tra',
  'add_label': 'Thêm',
  'create_template_btn': 'Tạo mẫu',
  'add_checklist_item_title': 'Thêm mục kiểm tra',
  'category_label': 'Danh mục',
  'bedroom_category': 'Phòng ngủ',
  'bathroom_category': 'Phòng tắm',
  'safety_category': 'An toàn',
  'please_add_at_least_one': 'Vui lòng thêm ít nhất một mục kiểm tra',
  'items_suffix': 'mục',

  // ===== PHASE C7: HARDCODED VIETNAMESE STRING EXTRACTION =====

  // Date Rate Override Form
  'tet_holiday': 'Tết Nguyên Đán',
  'christmas': 'Giáng sinh',
  'summer_season': 'Mùa hè',
  'price_section': 'Giá',
  'price_for_this_date': 'Giá cho ngày này *',
  'vnd_suffix': 'VNĐ',
  'please_enter_price': 'Vui lòng nhập giá',
  'price_must_be_positive': 'Giá phải lớn hơn 0',
  'create_price_multiple_days': 'Tạo giá cho nhiều ngày',
  'create_date_rate': 'Tạo giá theo ngày',
  'please_select_date': 'Vui lòng chọn ngày',
  'date_rate_created_for_days': 'Đã tạo giá cho {days} ngày',
  'delete_date_rate_title': 'Xóa giá theo ngày?',
  'select_date_placeholder': 'Chọn ngày',

  // Complete Task Dialog
  'clean_bathroom': 'Dọn dẹp phòng tắm',
  'general_cleaning': 'Dọn dẹp chung',
  'clean_glass': 'Lau kính',
  'complete_task_title': 'Hoàn thành công việc',
  'complete_all_items_warning': 'Vui lòng hoàn thành tất cả các mục',

  // Financial Category Screen
  'cannot_delete_category_msg': 'Không thể xoá danh mục "{name}" vì có {count} giao dịch liên quan.',
  'confirm_delete_category_msg': 'Bạn có chắc muốn xoá danh mục "{name}"?\n\nThao tác này không thể hoàn tác.',
  'active_in_use_count': 'Đang sử dụng ({count})',
  'hidden_count': 'Đã ẩn ({count})',
  'edit_category': 'Sửa danh mục',
  'add_income_category_title': 'Thêm danh mục thu',
  'add_expense_category_title': 'Thêm danh mục chi',
  'category_updated_msg': 'Đã cập nhật danh mục',
  'category_created_msg': 'Đã tạo danh mục mới',
  'income_short': 'Thu',
  'preview_label': 'Xem trước',
  'category_name_placeholder': 'Tên danh mục',
  'example_electricity': 'VD: Tiền điện',
  'example_electricity_en': 'VD: Electricity',

  // Room Inspection Form Screen
  'enter_room_id_hint': 'Nhập ID phòng',
  'please_enter_room_id': 'Vui lòng nhập ID phòng',
  'no_default_template_desc': 'Không có mẫu mặc định nào. Bạn có thể tạo mẫu mới từ danh sách mẫu.',
  'checklist_items_suffix': 'mục kiểm tra',
  'creating_text': 'Đang tạo...',
  'create_inspection_btn': 'Tạo kiểm tra',
  'inspection_not_found': 'Không tìm thấy kiểm tra',
  'complete_btn_label': 'Hoàn tất',
  'progress_count': 'Tiến độ:',
  'important_badge': 'Quan trọng',
  'pass_btn': 'Đạt',
  'fail_btn': 'Không đạt',
  'enter_notes_hint': 'Nhập ghi chú...',
  'action_required_if_any': 'Hành động cần thực hiện (nếu có)',
  'describe_action_required': 'Mô tả hành động cần thực hiện...',
  'please_select_room_msg': 'Vui lòng chọn phòng',
  'inspection_created_success': 'Đã tạo kiểm tra thành công',

  // PHASE C7 Batch 2
  'check_in_date_required': 'Ngày nhận phòng *',
  'check_out_date_required': 'Ngày trả phòng *',
  'nights_count_display': 'Số đêm: {count}',
  'no_pending_inspections': 'Không có kiểm tra chờ xử lý',
  'no_completed_inspections': 'Chưa có kiểm tra hoàn thành',
  'no_action_required_inspections': 'Không có kiểm tra cần xử lý',
  'no_inspections_yet': 'Chưa có kiểm tra nào',
  'pending_inspections_label': 'Đang chờ',
  'total_issues': 'Tổng vấn đề',
  'room_with_number': 'Phòng {number}',
  'score_value_display': 'Điểm: {value}%',
  'no_rate_plans_yet': 'Chưa có gói giá nào',
  'paused_status': 'Tạm dừng',
  'min_nights_stay_display': 'Tối thiểu {count} đêm',
  'from_date_display': 'Từ {date}',
  'to_date_display': 'Đến {date}',
  'no_daily_rates_yet': 'Chưa có giá theo ngày',

  // PHASE C7 Batch 3: Lost & Found strings
  'lost_and_found': 'Lost & Found',
  'no_claimed_items': 'Không có đồ đã nhận',
  'no_unclaimed_items': 'Không có đồ chưa nhận',
  'no_lost_found_items': 'Chưa có đồ thất lạc',
  'confirm_guest_claimed': 'Xác nhận khách đã nhận lại đồ?',
  'dispose_reason_title': 'Lý do xử lý',
  'dispose_reason_hint': 'Nhập lý do xử lý/quyên góp',

  // PHASE C7 Batch 3: Widget/screen strings
  'enter_amount_hint': 'Nhập số tiền',
  'please_enter_amount': 'Vui lòng nhập số tiền',
  'invalid_amount': 'Số tiền không hợp lệ',
  'card_payment': 'Thẻ',
  'other_label': 'Khác',
  'other_ota': 'OTA khác',
  'error_loading_staff_list': 'Lỗi tải danh sách nhân viên',
  'assign_to_self': 'Tự nhận việc',
  'deposit_label_amount': 'Đặt cọc: {amount}',
  'overlap_warning_title': 'Cảnh báo trùng lịch',
  'overlap_warning_message': 'Phòng này đã có {count} đặt phòng trong khoảng thời gian đã chọn. Bạn có muốn tiếp tục?',
  'room_number_hint': 'Ví dụ: 101, 102, 201...',
  'paid_abbreviation': 'Đã TT',
  'phone_validation_length': 'Số điện thoại phải có 10-11 số',
  'phone_validation_start_with_zero': 'Số điện thoại phải bắt đầu bằng 0',
  'product_tab': 'Sản phẩm',

  // ===== ENUM DISPLAY NAMES & ERROR MESSAGES (Batch 5) =====
  'booking_status_pending': 'Chờ xác nhận',
  'booking_status_confirmed': 'Đã xác nhận',
  'booking_status_checked_in': 'Đang ở',
  'booking_status_checked_out': 'Đã trả phòng',
  'booking_status_cancelled': 'Đã hủy',
  'booking_status_no_show': 'Không đến',
  'booking_source_walk_in': 'Khách vãng lai',
  'booking_source_phone': 'Điện thoại',
  'booking_source_other_ota': 'OTA khác',
  'booking_source_other': 'Khác',
  'payment_method_cash': 'Tiền mặt',
  'payment_method_bank_transfer': 'Chuyển khoản',
  'payment_method_card': 'Thẻ',
  'payment_method_ota_collect': 'OTA thu hộ',
  'payment_method_other': 'Khác',
  'booking_type_overnight': 'Qua đêm',
  'booking_type_hourly': 'Theo giờ',
  'room_status_available': 'Trống',
  'room_status_occupied': 'Có khách',
  'room_status_cleaning': 'Đang dọn',
  'room_status_maintenance': 'Bảo trì',
  'room_status_blocked': 'Khóa',
  'payment_type_deposit': 'Đặt cọc',
  'payment_type_room_charge': 'Tiền phòng',
  'payment_type_extra_charge': 'Phí bổ sung',
  'payment_type_refund': 'Hoàn tiền',
  'payment_type_adjustment': 'Điều chỉnh',
  'payment_status_pending': 'Chờ xử lý',
  'payment_status_completed': 'Hoàn tất',
  'payment_status_failed': 'Thất bại',
  'payment_status_refunded': 'Đã hoàn',
  'payment_status_cancelled': 'Đã hủy',
  'folio_type_room': 'Tiền phòng',
  'folio_type_minibar': 'Minibar',
  'folio_type_laundry': 'Giặt là',
  'folio_type_food': 'Đồ ăn',
  'folio_type_service': 'Dịch vụ',
  'folio_type_extra_bed': 'Giường phụ',
  'folio_type_early_checkin': 'Nhận sớm',
  'folio_type_late_checkout': 'Trả muộn',
  'folio_type_damage': 'Hư hỏng',
  'folio_type_other': 'Khác',
  'month_1': 'Tháng 1',
  'month_2': 'Tháng 2',
  'month_3': 'Tháng 3',
  'month_4': 'Tháng 4',
  'month_5': 'Tháng 5',
  'month_6': 'Tháng 6',
  'month_7': 'Tháng 7',
  'month_8': 'Tháng 8',
  'month_9': 'Tháng 9',
  'month_10': 'Tháng 10',
  'month_11': 'Tháng 11',
  'month_12': 'Tháng 12',
  'id_type_cccd': 'CCCD',
  'id_type_passport': 'Hộ chiếu',
  'id_type_cmnd': 'CMND',
  'id_type_driving_license': 'GPLX',
  'id_type_other': 'Khác',
  'id_type_cccd_full': 'CCCD (Căn cước công dân)',
  'id_type_passport_full': 'Hộ chiếu',
  'id_type_cmnd_full': 'CMND (Chứng minh nhân dân)',
  'id_type_driving_license_full': 'GPLX (Giấy phép lái xe)',
  'id_type_other_full': 'Khác',
  'gender_male': 'Nam',
  'gender_female': 'Nữ',
  'gender_other': 'Khác',
  'passport_type_regular': 'Phổ thông',
  'passport_type_official': 'Công vụ',
  'passport_type_diplomatic': 'Ngoại giao',
  'passport_type_other': 'Khác',
  'visa_type_visa': 'Thị thực (Visa)',
  'visa_type_temporary_residence': 'Thẻ tạm trú',
  'visa_type_visa_exemption_cert': 'Giấy miễn thị thực',
  'visa_type_abtc': 'Thẻ ABTC',
  'visa_type_visa_exempt': 'Miễn thị thực',
  'nationality_vietnam': 'Việt Nam',
  'nationality_china': 'Trung Quốc',
  'nationality_south_korea': 'Hàn Quốc',
  'nationality_japan': 'Nhật Bản',
  'nationality_usa': 'Mỹ',
  'nationality_france': 'Pháp',
  'nationality_uk': 'Anh',
  'nationality_australia': 'Úc',
  'nationality_germany': 'Đức',
  'nationality_russia': 'Nga',
  'nationality_thailand': 'Thái Lan',
  'nationality_singapore': 'Singapore',
  'nationality_malaysia': 'Malaysia',
  'nationality_taiwan': 'Đài Loan',
  'nationality_hong_kong': 'Hồng Kông',
  'nationality_other': 'Khác',
  'task_type_checkout_clean': 'Dọn trả phòng',
  'task_type_stayover_clean': 'Dọn phòng đang ở',
  'task_type_deep_clean': 'Dọn sâu',
  'task_type_maintenance': 'Bảo trì',
  'task_type_inspection': 'Kiểm tra',
  'housekeeping_status_pending': 'Chờ xử lý',
  'housekeeping_status_in_progress': 'Đang làm',
  'housekeeping_status_completed': 'Hoàn thành',
  'housekeeping_status_verified': 'Đã xác nhận',
  'priority_low': 'Thấp',
  'priority_medium': 'Trung bình',
  'priority_high': 'Cao',
  'priority_urgent': 'Khẩn cấp',
  'maintenance_status_pending': 'Chờ xử lý',
  'maintenance_status_assigned': 'Đã phân công',
  'maintenance_status_in_progress': 'Đang thực hiện',
  'maintenance_status_paused': 'Tạm dừng',
  'maintenance_status_completed': 'Hoàn thành',
  'maintenance_status_cancelled': 'Đã hủy',
  'maint_cat_electrical': 'Điện',
  'maint_cat_plumbing': 'Nước',
  'maint_cat_hvac': 'Điều hòa/Sưởi',
  'maint_cat_furniture': 'Nội thất',
  'maint_cat_appliance': 'Thiết bị',
  'maint_cat_structural': 'Kết cấu',
  'maint_cat_safety': 'An toàn',
  'maint_cat_other': 'Khác',
  'inspection_status_pending': 'Chờ kiểm tra',
  'inspection_status_in_progress': 'Đang kiểm tra',
  'inspection_status_completed': 'Hoàn thành',
  'inspection_status_action_required': 'Cần xử lý',
  'inspection_type_checkout': 'Sau trả phòng',
  'inspection_type_checkin': 'Trước nhận phòng',
  'inspection_type_routine': 'Định kỳ',
  'inspection_type_maintenance': 'Bảo trì',
  'inspection_type_deep_clean': 'Vệ sinh tổng',
  'inspection_cat_bedroom': 'Phòng ngủ',
  'inspection_cat_bathroom': 'Phòng tắm',
  'inspection_cat_amenities': 'Tiện nghi',
  'inspection_cat_electronics': 'Điện tử',
  'inspection_cat_safety': 'An toàn',
  'inspection_cat_general': 'Tổng quát',
  'lost_found_status_found': 'Đã tìm thấy',
  'lost_found_status_stored': 'Đang lưu giữ',
  'lost_found_status_claimed': 'Đã trả khách',
  'lost_found_status_donated': 'Đã quyên góp',
  'lost_found_status_disposed': 'Đã tiêu hủy',
  'lost_found_cat_electronics': 'Đồ điện tử',
  'lost_found_cat_clothing': 'Quần áo',
  'lost_found_cat_jewelry': 'Trang sức',
  'lost_found_cat_documents': 'Giấy tờ',
  'lost_found_cat_money': 'Tiền',
  'lost_found_cat_bags': 'Túi/Vali',
  'lost_found_cat_personal': 'Đồ cá nhân',
  'lost_found_cat_other': 'Khác',
  'cancel_policy_free': 'Miễn phí hủy',
  'cancel_policy_flexible': 'Linh hoạt',
  'cancel_policy_moderate': 'Trung bình',
  'cancel_policy_strict': 'Nghiêm ngặt',
  'cancel_policy_non_refundable': 'Không hoàn tiền',
  'user_role_owner': 'Chủ căn hộ',
  'user_role_manager': 'Quản lý',
  'user_role_staff': 'Nhân viên',
  'user_role_housekeeping': 'Phòng buồng',
  'night_audit_status_draft': 'Nháp',
  'night_audit_status_completed': 'Hoàn thành',
  'night_audit_status_closed': 'Đã đóng',
  'notification_type_new_booking': 'Đặt phòng mới',
  'notification_type_booking_confirmed': 'Xác nhận đặt phòng',
  'notification_type_booking_cancelled': 'Hủy đặt phòng',
  'notification_type_checkin_reminder': 'Nhắc nhận phòng',
  'notification_type_checkout_reminder': 'Nhắc trả phòng',
  'notification_type_checked_in': 'Đã nhận phòng',
  'notification_type_checked_out': 'Đã trả phòng',
  'notification_type_general': 'Thông báo chung',
  'message_status_draft': 'Nháp',
  'message_status_sending': 'Đang gửi',
  'message_status_sent': 'Đã gửi',
  'message_status_delivered': 'Đã nhận',
  'message_status_failed': 'Thất bại',
  'msg_template_booking_confirm': 'Xác nhận đặt phòng',
  'msg_template_pre_arrival': 'Thông tin trước khi đến',
  'msg_template_checkout_reminder': 'Nhắc trả phòng',
  'msg_template_review_request': 'Yêu cầu đánh giá',
  'msg_template_custom': 'Tùy chỉnh',
  'report_group_daily': 'Ngày',
  'report_group_weekly': 'Tuần',
  'report_group_monthly': 'Tháng',
  'report_type_occupancy': 'Công suất phòng',
  'report_type_revenue': 'Doanh thu',
  'report_type_expense': 'Chi phí',
  'report_type_kpi': 'KPI',
  'report_type_channel': 'Kênh bán',
  'report_type_guest': 'Khách hàng',
  'comparison_previous_period': 'Kỳ trước',
  'comparison_previous_year': 'Năm trước',
  'comparison_custom': 'Tùy chỉnh',
  'demographics_nationality': 'Quốc tịch',
  'demographics_source': 'Nguồn đặt',
  'demographics_room_type': 'Loại phòng',
  'declaration_dd10': 'ĐD10 - Khách Việt Nam',
  'declaration_na17': 'NA17 - Khách nước ngoài',
  'declaration_all': 'Tất cả',
  'declaration_dd10_desc': 'Sổ quản lý lưu trú (Nghị định 144/2021)',
  'declaration_na17_desc': 'Phiếu khai báo tạm trú người nước ngoài (Thông tư 04/2015)',
  'declaration_all_desc': 'Cả ĐD10 và NA17',
  'group_status_pending': 'Đang chờ',
  'group_status_confirmed': 'Đã xác nhận',
  'group_status_checked_in': 'Đang ở',
  'group_status_checked_out': 'Đã trả phòng',
  'group_status_cancelled': 'Đã hủy',
  'minibar_charged': 'Đã tính tiền',
  'minibar_uncharged': 'Chưa tính tiền',
  'guest_number': 'Khách #{guest}',
  'report_metric_occupancy': 'Công suất',
  'report_metric_bookings': 'Số đặt phòng',
  'report_metric_guests': 'Số khách',
  'month_label': 'Tháng {month}',
  'entry_type_income': 'Thu',
  'entry_type_expense': 'Chi',
  'search_min_chars': 'Từ khóa tìm kiếm phải có ít nhất 2 ký tự',
  'guest_added_success': 'Đã thêm khách hàng thành công',
  'guest_updated_success': 'Đã cập nhật thông tin khách hàng',
  'error_no_network': 'Không có kết nối mạng',
  'error_phone_registered': 'Số điện thoại đã được đăng ký',
  'error_id_registered': 'Số CCCD/Passport đã được đăng ký',
  'error_phone_digits': 'Số điện thoại phải có 10-11 chữ số',
  'error_cannot_delete_guest': 'Không thể xóa khách hàng có lịch sử đặt phòng',
  'error_guest_not_found': 'Không tìm thấy khách hàng',
  'error_generic': 'Đã xảy ra lỗi. Vui lòng thử lại.',
  'error_wrong_credentials': 'Tên đăng nhập hoặc mật khẩu không đúng',
  'error_folio_load': 'Không thể tải folio: {error}',
  'error_charge_add': 'Không thể thêm phí: {error}',
  'error_charge_void': 'Không thể hủy phí: {error}',
  'error_no_booking_selected': 'Chưa chọn đặt phòng',
  'error_empty_cart': 'Giỏ hàng trống',
  'error_room_exists': 'Số phòng đã tồn tại',
  'error_cannot_delete_room': 'Không thể xóa phòng đang có đặt phòng',
  'error_report_export': 'Lỗi xuất báo cáo: {error}',
  'biometric_authenticate_login': 'Xác thực để đăng nhập',
  'biometric_fingerprint': 'Vân tay',
  'biometric_iris': 'Quét mống mắt',
  'biometric_generic': 'Sinh trắc học',
  'date_today': 'Hôm nay',
  'date_tomorrow': 'Ngày mai',
  'date_yesterday': 'Hôm qua',
  'date_in_days': 'Trong {count} ngày',
  'date_days_ago': '{count} ngày trước',
  'day_sunday': 'Chủ nhật',
  'day_monday': 'Thứ hai',
  'day_tuesday': 'Thứ ba',
  'day_wednesday': 'Thứ tư',
  'day_thursday': 'Thứ năm',
  'day_friday': 'Thứ sáu',
  'day_saturday': 'Thứ bảy',
  'error_booking_conflict': 'Phòng đã được đặt trong thời gian này.',
  'error_cache': 'Lỗi bộ nhớ đệm.',
  'error_offline': 'Không có kết nối mạng. Đang làm việc offline.',
  'error_connection_timeout': 'Kết nối quá thời gian. Vui lòng thử lại.',
  'error_no_connection': 'Không có kết nối mạng.',
  'error_request_cancelled': 'Yêu cầu đã bị hủy.',
  'error_unknown': 'Đã xảy ra lỗi. Vui lòng thử lại.',
  'error_invalid_data': 'Dữ liệu không hợp lệ.',
  'error_session_expired': 'Phiên đăng nhập đã hết hạn.',
  'error_no_permission': 'Bạn không có quyền thực hiện thao tác này.',
  'error_not_found': 'Không tìm thấy dữ liệu.',
  'error_conflict': 'Dữ liệu bị xung đột.',
  'error_server': 'Lỗi máy chủ. Vui lòng thử lại sau.',

};
// English translations
const Map<String, String> _enTranslations = {
  // ===== COMMON =====
  'app_name': 'Hoang Lam Heritage Suites',
  'home': 'Home',
  'bookings': 'Bookings',
  'finance': 'Finance',
  'settings': 'Settings',
  'login': 'Login',
  'logout': 'Logout',
  'cancel': 'Cancel',
  'save': 'Save',
  'confirm': 'Confirm',
  'delete': 'Delete',
  'edit': 'Edit',
  'add': 'Add',
  'search': 'Search',
  'loading': 'Loading...',
  'error': 'Error',
  'success': 'Success',
  'retry': 'Retry',
  'no_data': 'No data',
  'feature_coming_soon': 'Feature coming soon',
  'offline': 'Offline',
  'close': 'Close',
  'continue': 'Continue',
  'please': 'Please',
  'are_you_sure': 'Are you sure',
  'action_cannot_be_undone': 'This action cannot be undone.',
  'error_occurred': 'An error occurred',
  'error_try_again': 'An error occurred. Please try again.',
  'update': 'Update',
  'create': 'Create',
  'view_all': 'View all',
  'all': 'All',
  'filter': 'Filter',
  'status': 'Status',
  'advanced_filter': 'Advanced filter',
  'booking_source': 'Booking source',
  'clear_filter': 'Clear filter',
  'total': 'Total',
  'active': 'Active',
  'inactive': 'Inactive',
  'enable': 'Enable',
  'later': 'Later',
  'open': 'Open',
  'copied': 'Copied',
  'reset': 'Reset',
  'info': 'Information',
  'name': 'Name',
  'version': 'Version',

  // ===== ROOM STATUS =====
  'available': 'Available',
  'occupied': 'Occupied',
  'cleaning': 'Cleaning',
  'maintenance': 'Maintenance',
  'blocked': 'Blocked',

  // ===== AUTH =====
  'login_subtitle': 'Login to manage',
  'username_label': 'Username',
  'username_hint': 'Enter username',
  'username_required': 'Please enter username',
  'password_label': 'Password',
  'password_required': 'Please enter password',
  'password_min_length': 'Password must be at least 6 characters',
  'login_button': 'Login',
  'forgot_password': 'Forgot password?',
  'contact_admin_reset_password': 'Please contact administrator to reset password',
  'enable_biometric_title': 'Enable biometric login',
  'enable_biometric_message': 'Do you want to use fingerprint or Face ID for faster login next time?',
  'biometric_enabled': 'Biometric login enabled',
  'biometric_auth_failed': 'Biometric authentication failed',
  'authenticating': 'Authenticating...',
  'login_with': 'Login with',
  'change_password': 'Change password',
  'new_password_min_length': 'New password must be at least 6 characters',
  'password_change_success': 'Password changed successfully',
  'password_change_failed': 'Cannot change password. Please check again.',
  'current_password': 'Current password',
  'new_password': 'New password',
  'confirm_new_password': 'Confirm new password',
  'please_enter_current_password': 'Please enter current password',
  'please_enter_new_password': 'Please enter new password',
  'please_confirm_new_password': 'Please confirm new password',
  'new_password_must_be_different': 'New password must be different from current password',
  'passwords_do_not_match': 'Passwords do not match',
  'apartment_management': 'Apartment management',

  // ===== DASHBOARD =====
  'notifications': 'Notifications',
  'account': 'Account',
  'room_status': 'Room status',
  'upcoming_checkout': 'Upcoming check-out',
  'upcoming_checkin': 'Upcoming check-in',
  'available_rooms': 'Available rooms',
  'rooms_available': 'Rooms available',
  'today_check_ins': 'Today\'s check-ins',
  'today_check_outs': 'Today\'s check-outs',
  'today_revenue': 'Today\'s revenue',
  'occupancy_rate': 'Occupancy rate',
  'checkout_today': 'Check-out today',
  'checkin_today': 'Check-in today',
  'dashboard_load_error': 'Cannot load dashboard data',
  'new_booking': 'New booking',
  'no_rooms': 'No rooms yet',
  'room_load_error': 'Error loading room data',
  'no_checkout_today': 'No check-out today',
  'no_checkin_today': 'No check-in today',
  'guest': 'Guest',

  // ===== BOOKING =====
  'check_in': 'Check-in',
  'check_out': 'Check-out',
  'guest_name': 'Guest name',
  'guest_phone': 'Phone number',
  'room_number': 'Room number',
  'nights': 'nights',
  'total_amount': 'Total amount',
  'deposit': 'Deposit',
  'balance': 'Balance',
  'booking_list': 'Booking list',
  'data_load_error': 'Error loading data',
  'search_guest_room': 'Search by guest name, room number...',
  'no_bookings': 'No bookings',
  'no_bookings_for_filter': 'No bookings for this filter',
  'edit_booking': 'Edit booking',
  'room_required': 'Room *',
  'please_select_room': 'Please select room',
  'guest_required': 'Guest *',
  'please_select_create_guest': 'Please select or create guest',
  'booking_dates': 'Booking dates',
  'number_of_nights': 'Number of nights',
  'create_booking': 'Create booking',
  'booking_details': 'Booking details',
  'go_back': 'Go back',
  'guest_info': 'Guest information',
  'guest_count': 'Guest count',
  'people': 'people',
  'time_label': 'Time',
  'expected_checkin': 'Expected check-in',
  'expected_checkout': 'Expected check-out',
  'actual_checkin': 'Actual check-in',
  'actual_checkout': 'Actual check-out',
  'payment': 'Payment',
  'rate_per_night': 'Rate/night',
  'deposit_paid': 'Deposit paid',
  'balance_due': 'Balance due',
  'payment_method': 'Payment method',
  'booking_info': 'Booking information',
  'source': 'Source',
  'booking_date': 'Booking date',
  'special_requests': 'Special requests',
  'internal_notes': 'Internal notes',
  'select_booking': 'Select booking',
  'booking_list_load_error': 'Booking list load error',
  'book_room': 'Book room',

  // ===== EARLY/LATE FEES =====
  'early_check_in': 'Early Check-in',
  'late_check_out': 'Late Check-out',
  'early_check_in_fee': 'Early check-in fee',
  'late_check_out_fee': 'Late check-out fee',
  'quick_select': 'Quick select',
  'number_of_hours': 'Number of hours',
  'hours': 'hours',
  'fee_amount': 'Fee amount',
  'optional_notes': 'Notes (optional)',
  'create_folio_item': 'Create folio item',
  'track_in_financials': 'Track in financials',
  'max_hours_24': 'Maximum 24 hours',
  'invalid_value': 'Invalid value',
  'required': 'Required',
  'record_early_check_in': 'Record early check-in',
  'record_late_check_out': 'Record late check-out',
  'early_check_in_recorded': 'Early check-in fee recorded',
  'late_check_out_recorded': 'Late check-out fee recorded',
  'fees_and_charges': 'Fees & Charges',

  // ===== ROOM =====
  'room_management': 'Room management',
  'hide_inactive_rooms': 'Hide inactive rooms',
  'show_inactive_rooms': 'Show inactive rooms',
  'search_rooms': 'Search rooms...',
  'room_not_found': 'Room not found',
  'no_rooms_yet': 'No rooms yet',
  'add_first_room': 'Add first room',
  'floor': 'Floor',
  'add_room': 'Add room',
  'deactivate': 'Deactivate',
  'activate': 'Activate',
  'room_deactivated': 'Room deactivated',
  'room_activated': 'Room activated',
  'delete_room': 'Delete room?',
  'room_deleted': 'Room deleted',
  'edit_room': 'Edit room',
  'add_new_room': 'Add new room',
  'room_number_label': 'Room number *',
  'please_enter_room_number': 'Please enter room number',
  'room_name_optional': 'Room name (optional)',
  'example_room_name': 'Example: Ocean View Room',
  'room_type': 'Room type *',
  'please_select_room_type': 'Please select room type',
  'cannot_load_room_types': 'Cannot load room types',
  'amenities': 'Amenities',
  'air_conditioning': 'Air conditioning',
  'safe': 'Safe',
  'bathtub': 'Bathtub',
  'hair_dryer': 'Hair dryer',
  'work_desk': 'Work desk',
  'balcony': 'Balcony',
  'room_notes': 'Room notes...',
  'room_is_active': 'Room is active',
  'room_can_be_booked': 'Room can be booked',
  'room_disabled': 'Room disabled',
  'room_updated': 'Room updated',
  'room_added': 'Room added',
  'confirm_delete_room': 'Are you sure you want to delete room',
  'change_status': 'Change status',
  'room_info': 'Room information',
  'undefined': 'Undefined',
  'has_guests': 'Has guests',
  'view_booking_details': 'View booking details',
  'history': 'History',
  'no_history': 'No history',

  // ===== GUEST =====
  'guests': 'Guests',
  'add_guest': 'Add guest',
  'search_guests': 'Search guests...',
  'guest_not_found': 'Guest not found',
  'no_guests_yet': 'No guests yet',
  'try_different_search': 'Try different search keywords',
  'press_to_add_guest': 'Press + to add new guest',
  'edit_guest': 'Edit',
  'contact_info': 'Contact information',
  'phone_number': 'Phone number',
  'address': 'Address',
  'identity_document': 'Identity document',
  'document_type': 'Document type',
  'document_number': 'Document number',
  'issued_by': 'Issued by',
  'issue_date': 'Issue date',
  'personal_info': 'Personal information',
  'nationality': 'Nationality',
  'gender': 'Gender',
  'date_of_birth': 'Date of birth',
  'age': 'Age',
  'years_old': 'years old',
  'call': 'Call',
  'remove_vip': 'Remove VIP',
  'mark_vip': 'Mark VIP',
  'marked_as_vip': 'marked as VIP',
  'vip_removed': 'VIP mark removed',
  'edit_info': 'Edit information',
  'delete_guest': 'Delete guest',
  'confirm_delete': 'Confirm delete',
  'confirm_delete_guest': 'Are you sure you want to delete guest',
  'guest_deleted': 'Guest deleted',
  'edit_guest_title': 'Edit guest',
  'required_info': 'Required information',
  'full_name': 'Full name',
  'please_enter_full_name': 'Please enter full name',
  'full_name_min_length': 'Full name must be at least 2 characters',
  'please_enter_phone': 'Please enter phone number',
  'phone_must_be_10': 'Phone number must have 10-11 digits',
  'phone_must_start_with_0': 'Phone number must start with 0',
  'invalid_email': 'Invalid email',
  'not_specified': 'Not specified',
  'city': 'City',
  'preferences_hint': 'Preferences, special requests...',
  'save_changes': 'Save changes',
  'guest_info_updated': 'Guest information updated',
  'new_guest_added': 'New guest added',
  'select_from_list': 'Select from list',

  // ===== FINANCE =====
  'income': 'Income',
  'expense': 'Expense',
  'profit': 'Profit',
  'today': 'Today',
  'this_month': 'This month',
  'reports': 'Reports',
  'month': 'Month',

  // ===== SETTINGS =====
  'security': 'Security',
  'enabled': 'Enabled',
  'faster_login_biometric': 'Login faster with biometrics',
  'biometric_login_enabled': 'Biometric login enabled',
  'biometric_login_disabled': 'Biometric login disabled',
  'property_management': 'Property management',
  'add_edit_delete_rooms': 'Add, edit, delete rooms',
  'price_management': 'Price management',
  'rate_plans_promotions': 'Rate plans, daily rates, promotions',
  'general_settings': 'General settings',
  'theme': 'Theme',
  'light': 'Light',
  'dark': 'Dark',
  'system_default': 'System default',
  'language': 'Language',
  'vietnamese': 'Vietnamese',
  'text_size': 'Text size',
  'small': 'Small',
  'normal': 'Normal',
  'large': 'Large',
  'extra_large': 'Extra large',
  'notifications_settings': 'Notifications',
  'room_cleaning': 'Room cleaning',
  'all_off': 'All off',
  'management': 'Management',
  'night_audit': 'Night audit',
  'check_daily_figures': 'Check end-of-day figures',
  'residence_declaration': 'Residence declaration',
  'export_guest_list_police': 'Export guest list for police',
  'financial_categories': 'Financial categories',
  'account_management': 'Account management',
  'data': 'Data',
  'sync_data': 'Sync data',
  'last_update_just_now': 'Last update: Just now',
  'backup': 'Backup',
  'support': 'Support',
  'user_guide': 'User guide',
  'about_app': 'About app',
  'user': 'User',
  'staff': 'Staff',
  'select_theme': 'Select theme',
  'auto_phone_settings': 'Auto based on phone settings',
  'select_language': 'Select language',
  'notification_settings': 'Notification settings',
  'push_notifications': 'Push notifications',
  'receive_push_notifications': 'Receive push notifications from server',
  'local_reminders': 'Local reminders',
  'tap_to_retry': 'Tap to retry',
  'checkin_reminder': 'Check-in reminder',
  'notify_checkin_today': 'Notify when guests check in today',
  'checkout_reminder': 'Check-out reminder',
  'notify_checkout_today': 'Notify when guests check out today',
  'cleaning_reminder': 'Cleaning reminder',
  'notify_room_needs_cleaning': 'Notify when rooms need cleaning',
  'confirm_logout': 'Confirm logout?',
  'confirm_logout_message': 'Are you sure you want to log out of the app?',

  // ===== HOUSEKEEPING =====
  'housekeeping_tasks': 'Housekeeping tasks',
  'my_tasks': 'My tasks',
  'no_tasks': 'No tasks',
  'no_tasks_scheduled_today': 'No tasks scheduled for today',
  'no_tasks_created': 'No tasks created yet',
  'no_tasks_assigned': 'You have not been assigned any tasks',
  'pending': 'Pending',
  'in_progress': 'In progress',
  'completed': 'Completed',
  'create_new_task': 'Create new task',
  'urgent': 'Urgent',
  'no_urgent_requests': 'No urgent requests',
  'no_urgent_maintenance_requests': 'No urgent maintenance requests at the moment',
  'no_maintenance_requests': 'No maintenance requests',
  'no_maintenance_requests_created': 'No maintenance requests created yet',
  'no_your_requests': 'No requests from you',
  'no_assigned_maintenance_requests': 'You have not been assigned any maintenance requests',
  'assigned': 'Assigned',
  'on_hold': 'On hold',
  'completed_cancelled': 'Completed/Cancelled',
  'create_request': 'Create request',
  'edit_request': 'Edit request',
  'create_maintenance_request': 'Create maintenance request',
  'room': 'Room',
  'cannot_load_room_list': 'Cannot load room list',
  'title': 'Title',
  'describe_issue_briefly': 'Describe the issue briefly',
  'please_enter_title': 'Please enter title',
  'category': 'Category',
  'priority_level': 'Priority level',
  'detailed_description': 'Detailed description',
  'describe_issue_in_detail': 'Describe the issue in detail...',
  'please_enter_description': 'Please enter description',
  'estimated_cost_optional': 'Estimated cost (optional)',
  'request_updated': 'Request updated',
  'new_maintenance_request_created': 'New maintenance request created',
  'select_room': 'Select room',
  'hold': 'Hold',
  'resume': 'Resume',
  'request_info': 'Request information',
  'assignee': 'Assignee',
  'not_assigned': 'Not assigned',
  'reporter': 'Reporter',
  'description': 'Description',
  'resolution_result': 'Resolution result',
  'created_at': 'Created at',
  'completed_at': 'Completed at',
  'updated_at': 'Updated at',
  'assign': 'Assign',
  'maintenance_request_completed': 'Maintenance request completed',
  'request_on_hold': 'Request on hold',
  'continue_request': 'Continue request',
  'continue_request_confirmation': 'Do you want to continue processing this request?',
  'request_continued': 'Request continued',
  'cancel_request': 'Cancel request',
  'cancel_request_confirmation': 'Are you sure you want to cancel this maintenance request?',
  'no': 'No',
  'request_cancelled': 'Request cancelled',
  'complete_request': 'Complete request',
  'enter_resolution_notes': 'Enter notes about the resolution (optional):',
  'describe_work_done': 'Describe the work done...',
  'hold_request': 'Hold request',
  'enter_hold_reason': 'Enter reason for holding (optional):',
  'reason': 'Reason...',
  'assignment_in_development': 'Assignment feature is under development',
  'complete_request_confirmation': 'Are you sure you have completed this maintenance request?',
  'task_info': 'Task information',
  'task_type': 'Task type',
  'scheduled_date': 'Scheduled date',
  'booking_code': 'Booking code',
  'creator': 'Creator',
  'notes': 'Notes',
  'task_assigned': 'Task assigned',
  'task_completed': 'Task completed',
  'verify_task': 'Verify task',
  'verify_task_confirmation': 'Are you sure you want to verify this task is complete?',
  'task_verified': 'Task verified',
  'delete_task': 'Delete task',
  'delete_task_confirmation': 'Are you sure you want to delete this task?',
  'task_deleted': 'Task deleted',
  'edit_task': 'Edit task',
  'create_task': 'Create task',
  'enter_notes_optional': 'Enter notes (optional)',
  'task_updated': 'Task updated',
  'new_task_created': 'New task created',
  'verify': 'Verify',

  // ===== NIGHT AUDIT =====
  'night_audit_title': 'Night audit',
  'history_label': 'History',
  'select_date': 'Select date',
  'audit_load_error': 'Error loading audit',
  'performed_by': 'Performed by',
  'not_completed': 'Not completed',
  'occupancy': 'occupancy',
  'room_statistics': 'Room statistics',
  'total_rooms': 'Total rooms',
  'being_cleaned': 'Being cleaned',
  'booking_statistics': 'Booking statistics',
  'new_bookings': 'New bookings',
  'no_show': 'No show',
  'financial_overview': 'Financial overview',

  // ===== PRICING =====
  'edit_rate_plan': 'Edit rate plan',
  'add_rate_plan': 'Add rate plan',
  'delete_rate_plan': 'Delete rate plan',
  'basic_info': 'Basic information',
  'rate_plan_name': 'Rate plan name *',
  'rate_plan_hint': 'Ex: Weekend rate, Summer rate...',
  'please_enter_rate_plan_name': 'Please enter rate plan name',
  'english_name_optional': 'English name (optional)',
  'base_rate_per_night': 'Base rate/night *',
  'vnd': 'VND',
  'please_enter_rate': 'Please enter rate',
  'rate_must_be_positive': 'Rate must be greater than 0',
  'stay_requirements': 'Stay requirements',
  'min_nights': 'Minimum nights',
  'max_nights': 'Maximum nights',
  'no_limit': 'No limit',
  'advance_booking_optional': 'Advance booking days (optional)',
  'advance_booking_hint': 'Ex: 7 (book 7 days ahead)',
  'cancellation_policy': 'Cancellation policy',
  'validity_period': 'Validity period',
  'from_date': 'From date',
  'to_date': 'To date',
  'includes_breakfast': 'Includes breakfast',
  'rate_plan_includes_free_breakfast': 'This rate plan includes free breakfast',
  'is_active': 'Active',
  'show_apply_rate_plan': 'Show and apply this rate plan',
  'description_optional': 'Description (optional)',
  'rate_plan_notes': 'Additional notes about rate plan...',
  'create_rate_plan': 'Create rate plan',
  'rate_plan_updated': 'Rate plan updated',
  'rate_plan_created': 'Rate plan created',
  'delete_rate_plan_confirm': 'Delete rate plan?',
  'confirm_delete_rate_plan': 'Are you sure you want to delete rate plan',
  'rate_plan_deleted': 'Rate plan deleted',
  'edit_date_rate': 'Edit daily rate',
  'add_date_rate': 'Add daily rate',
  'weekend': 'Weekend',
  'holiday': 'Holiday',
  'lunar_new_year': 'Lunar New Year',
  'low_season': 'Low season',
  'promotion': 'Promotion',
  'special_event': 'Special event',
  'create_for_multiple_days': 'Create for multiple days',
  'apply_for_date_range': 'Apply for date range',
  'date_range': 'Date range',
  'apply_date': 'Apply date',
  'rate_adjustment_reason': 'Rate adjustment reason',
  'rate_reason_hint': 'Ex: Tet, Festival, Weekend...',
  'restrictions_optional': 'Restrictions (optional)',
  'close_for_arrival': 'Close for arrival',
  'no_checkin_allowed': 'No check-in allowed on this day',
  'close_for_departure': 'Close for departure',
  'no_checkout_allowed': 'No check-out allowed on this day',
  'min_nights_optional': 'Minimum nights (optional)',
  'min_nights_required': 'Minimum X nights required',
  'create_rates_multiple_days': 'Create rates for multiple days',
  'please_select_end_date': 'Please select end date',
  'date_rate_updated': 'Daily rate updated',
  'created_rates_for_days': 'Created rates for days',
  'date_rate_created': 'Daily rate created',
  'delete_date_rate_confirm': 'Delete daily rate?',
  'confirm_delete_date_rate': 'Are you sure you want to delete rate for date',
  'date_rate_deleted': 'Daily rate deleted',
  'all_room_types': 'All room types',
  'filter_by_room_type': 'Filter by room type',
  'select_room_type': 'Select room type *',
  'add_rate_plan_flexible_pricing': 'Add rate plans for flexible pricing',
  'add_special_rates': 'Add special rates for holidays, weekends...',
  'no_arrivals': 'No arrivals',
  'no_departures': 'No departures',
  'rate_plans': 'Rate plans',
  'daily_rates': 'Daily rates',

  // ===== DECLARATION =====
  'export_success': 'Export successful!',
  'residence_declaration_title': 'Residence declaration',
  'export_guest_list_description': 'Export guest list for temporary residence declaration with police.',
  'list_includes_guests_in_range': 'List includes all guests who checked in during the selected period.',
  'today_label': 'Today',
  'yesterday': 'Yesterday',
  'file_format': 'File format',
  'exporting': 'Exporting...',
  'export_list': 'Export list',
  'cannot_open_file': 'Cannot open file',
  'cannot_share_file': 'Cannot share file',
  'popular': 'Popular',
  'has_format': 'Has format',
  'file_exported': 'File exported',

  // ===== MINIBAR =====
  'minibar_management': 'Minibar management',
  'add_product': 'Add product',
  'search_products': 'Search products...',
  'edit_product': 'Edit product',
  'delete_product': 'Delete product',
  'please_enter_product_name': 'Please enter product name',
  'enter_or_select_category': 'Enter or select category',
  'product_added': 'Product added successfully',
  'confirm_delete_item': 'Are you sure you want to delete',
  'product_deleted': 'Product deleted',
  'inventory_management': 'Inventory management',
  'no_matching_products': 'No matching products found',
  'please_select_booking_first': 'Please select booking first',

  // ===== FOLIO =====
  'hide_cancelled_items': 'Hide cancelled items',
  'show_cancelled_items': 'Show cancelled items',
  'add_charge': 'Add charge',
  'cancel_charge': 'Cancel charge',
  'confirm_cancel_charge': 'Are you sure you want to cancel charge',
  'cancel_reason': 'Cancel reason *',
  'enter_cancel_reason': 'Enter cancel reason',
  'please_enter_cancel_reason': 'Please enter cancel reason',
  'charge_cancelled_success': 'Charge cancelled successfully',
  'cannot_cancel_charge': 'Cannot cancel charge',
  'confirm_cancel': 'Confirm cancel',

  // ===== REPORTS =====
  'total_revenue': 'Total revenue',
  'rooms_label': 'rooms',
  'total_available_room_nights': 'Total available room nights',
  'total_sold_room_nights': 'Total sold room nights',
  'room_revenue': 'Room revenue',
  'total_expense': 'Total expense',
  'total_bookings': 'Total bookings',
  'bookings_label': 'bookings',
  'total_guests': 'Total guests',
  'guests_label': 'guests',

  // ===== ROOM INSPECTION =====
  'room_inspection': 'Room Inspection',
  'statistics': 'Statistics',
  'inspection_template': 'Inspection Template',
  'requires_action': 'Requires Action',
  'create_inspection': 'Create Inspection',
  'inspection_details': 'Inspection Details',
  'start': 'Start',
  'continue_label': 'Continue',
  'conduct_inspection': 'Conduct Inspection',
  'create_new_inspection': 'Create New Inspection',
  'create_template': 'Create Template',
  'no_templates': 'No inspection templates yet',
  'create_first_template': 'Create First Template',

  // ===== GROUP BOOKING =====
  'group_booking': 'Group Booking',
  'confirmed_status': 'Confirmed',
  'checked_in_status': 'Checked In',
  'checked_out_status': 'Checked Out',
  'group_booking_details': 'Group Booking Details',
  'edit_group_booking': 'Edit Group Booking',
  'create_group_booking': 'Create Group Booking',

  // ===== PHASE 5: NOTIFICATIONS & MESSAGING =====
  'mark_all_read': 'Mark all as read',
  'no_notifications': 'No notifications',
  'no_notifications_description': 'When there are new notifications, they will appear here',
  'error_loading_data': 'Failed to load data',
  'send_message': 'Send message',
  'channel': 'Channel',
  'no_templates_messaging': 'No message templates yet',
  'write_custom_message': 'Write custom message',
  'write_custom_message_description': 'Compose a free-form message for guest',
  'message_preview': 'Message preview',
  'recipient': 'Recipient',
  'subject': 'Subject',
  'message_content': 'Content',
  'send': 'Send',
  'message_sent_success': 'Message sent successfully!',
  'message_sent_pending': 'Message is being processed',
  'message_send_failed': 'Failed to send message',
  'no_messages': 'No messages yet',
  'resend_message': 'Resend message',
  'resend_message_confirm': 'Do you want to resend this message?',
  'message_history': 'Message history',

  // ===== PHASE C: EXTRACTED HARDCODED STRINGS =====
  'update_status': 'Update status',
  'current_status_label': 'Current status',
  'select_new_status': 'Select new status:',
  'current_label': '(current)',
  'cannot_update_room_status': 'Cannot update room status',
  'notes_optional': 'Notes (optional)',
  'enter_notes': 'Enter notes...',
  'charge_type': 'Charge type',
  'description_required': 'Description *',
  'enter_charge_description': 'Enter charge description',
  'quantity_required': 'Quantity *',
  'quantity_min_one': 'Quantity >= 1',
  'unit_price_required': 'Unit price *',
  'unit_price_positive': 'Unit price > 0',
  'date_label': 'Date',
  'total_sum': 'Total:',
  'charge_added_success': 'Charge added successfully',
  'cannot_add_charge': 'Cannot add charge',
  'record_label': 'Record',
  'additional_notes_hint': 'Additional notes...',
  'options_section': 'Options',
  'reason_label': 'Reason',
  'item_name_label': 'Item name *',
  'item_name_hint': 'Ex: Wallet, Phone...',
  'please_enter_name': 'Please enter name',
  'found_date_label': 'Found date',
  'location_section': 'Location',
  'found_location_label': 'Found location *',
  'found_location_hint': 'Ex: Room 101, Lobby...',
  'please_enter_value': 'Please enter',
  'storage_location_label': 'Storage location',
  'storage_location_hint': 'Ex: Lost & found cabinet...',
  'contact_section': 'Contact',
  'guest_contacted': 'Guest contacted',
  'contact_notes': 'Contact notes',
  'additional_info': 'Additional information',
  'estimated_value_vnd': 'Estimated value (VND)',
  'add_new': 'Add new',
  'item_created': 'Item created',
  'item_updated': 'Item updated',
  'store_in_storage': 'Store',
  'item_claimed': 'Claimed',
  'dispose_item': 'Dispose',
  'stored_success': 'Stored successfully',
  'claimed_success': 'Marked as claimed',
  'disposed_success': 'Item disposed',
  'deposit_vnd': 'Deposit (VND)',
  'discount_percent': 'Discount (%)',
  'deposit_paid_label': 'Deposit paid',
  'booking_created': 'Booking created',
  'please_assign_rooms_first': 'Please assign rooms first',
  'checked_in_success': 'Checked in',
  'room_assignment': 'Room assignment',
  'room_id_list': 'Room ID list',
  'invalid_room_list': 'Invalid room list',
  'rooms_assigned': 'Rooms assigned',
  'category_name_required': 'Category name *',
  'category_name_hint': 'Ex: Electricity',
  'please_enter_category_name': 'Please enter category name',
  'english_name': 'English name',
  'icon_label': 'Icon',
  'color_label': 'Color',
  'issue_notes': 'Issue notes',
  'describe_issue_hint': 'Describe issue...',
  'general_notes': 'General notes',
  'action_required_label': 'Actions required (if any)',
  'describe_action_hint': 'Describe required actions...',
  'inspection_created': 'Inspection created successfully',
  'template_name_required': 'Template name *',
  'template_name_hint': 'Ex: Standard checkout inspection',
  'please_enter_template_name': 'Please enter template name',
  'inspection_type': 'Inspection type',
  'sort_order_hint': 'Ex: 1, 2, 3',
  'default_template': 'Default template',
  'use_as_default_template': 'Use this template for new inspections',
  'checklist_items_count': 'Checklist items',
  'template_created': 'Template created successfully',
  'edit_in_development': 'Edit feature in development',
  'template_copied': 'Template copied successfully',
  'add_checklist_item': 'Add checklist item',
  'item_name_required': 'Item name *',
  'bedroom': 'Bedroom',
  'bathroom': 'Bathroom',
  'electronics': 'Electronics',
  'safety_label': 'Safety',
  'other_category': 'Other',
  'please_add_checklist_item': 'Please add at least one checklist item',
  'stats_recalculated': 'Statistics recalculated',
  'close_audit': 'Close audit',
  'close_audit_confirmation': 'After closing, you will not be able to edit this audit.\n\nAre you sure you want to close?',
  'audit_closed': 'Audit closed',
  'assign_repair': 'Assign repair',
  'self_assign': 'Self assign',
  'staff_load_error': 'Error loading staff list',
  'no_staff_available': 'No staff available',
  'on_sale': 'On sale',
  'not_for_sale': 'Not for sale',
  'charge_marked_success': 'Charge marked successfully',
  'payment_success': 'Payment successful',
  'save_file_error': 'Error saving file',
  'no_data_in_range': 'No data in this time range',
  'no_expenses_in_range': 'No expenses in this time range',
  'backup_in_development': 'Backup feature in development',
  'search_staff_hint': 'Search by name, username, phone...',
  'stays_label': 'Stays',
  'room_info_not_found': 'Room information not found',
  'booking_info_not_found': 'Booking information not found',
  'task_info_not_found': 'Task information not found',
  'maintenance_not_found': 'Maintenance request not found',
  'lost_item_not_found': 'Lost item not found',
  'rate_plan_not_found': 'Rate plan not found',
  'date_rate_not_found': 'Date rate not found',
  'page_not_found': 'Page not found',
  'go_home': 'Go home',

  // ===== PHASE C2: ADDITIONAL EXTRACTED STRINGS =====
  'contact_label': 'Contact',
  'contact_person': 'Contact person',
  'assigned_rooms': 'Assigned rooms',
  'paid': 'Paid',
  'unpaid': 'Unpaid',
  'amount': 'Amount',
  'select_staff': 'Select staff',
  'just_now': 'Just now',
  'minutes_ago': 'minutes ago',
  'hours_ago': 'hours ago',
  'days_ago': 'days ago',
  'last_month': 'Last month',
  'this_year': 'This year',
  'seven_days': '7 days',
  'thirty_days': '30 days',
  'ninety_days': '90 days',
  'last_7_days': 'Last 7 days',
  'last_30_days': 'Last 30 days',
  'claimed_date': 'Claimed date',
  'deposit_amount': 'Deposit amount',
  'cash': 'Cash',
  'bank_transfer': 'Bank transfer',
  'record_deposit': 'Record deposit',
  'cost_price': 'Cost price',
  'selling_price_required': 'Selling price *',
  'profit_margin': 'Profit margin',
  'room_charges': 'Room charges',
  'additional_charges': 'Additional charges',
  'total_charges': 'Total charges',
  'remaining_balance': 'Remaining',
  'guest_owes': 'Guest owes',
  'outstanding_balance': 'Outstanding',
  'no_deposit': 'No deposit',
  'deposit_short': 'Deposit short',
  'deposit_paid_status': 'Deposit paid',
  'required_amount': 'Required',
  'amount_short': 'Short',
  'record_deposit_btn': 'Record',
  'no_pending_deposits': 'No pending deposits',
  'currency_type': 'Currency type',
  'exchange_rate': 'Exchange rate',
  'confirm_payment': 'Confirm payment',
  'vnd_per_night': 'VND/night',
  'reference_code': 'Reference code',
  'method_label': 'Method',
  'no_income_categories': 'No income categories',
  'no_expense_categories': 'No expense categories',
  'category_hidden': 'Category hidden',
  'category_shown': 'Category shown',
  'view_financial_categories': 'View financial categories',
  'group_info': 'Group info',
  'group_name_required': 'Group name *',
  'number_of_rooms': 'Number of rooms *',
  'number_of_guests': 'Number of guests *',
  'no_products': 'No products',
  'clear_cart': 'Clear cart',
  'confirm_clear_cart': 'Are you sure you want to clear all items from the cart?',
  'product_updated_success': 'Product updated successfully',
  'confirm_delete_product': 'Are you sure you want to delete this product?',
  'occupancy_percent': '% occupancy',
  'export_report': 'Export report',
  'average_occupancy': 'Average occupancy',
  'total_spending': 'Total spending',
  'hotel_owner': 'Hotel owner',
  'manager_role': 'Manager',
  'housekeeping_role': 'Housekeeping',
  'view_staff_list': 'View staff list',
  'booking_history': 'Booking history',
  'times_count': 'times',
  'create_new_guest': 'Create new guest',
  'find_guest': 'Find guest',
  'min_2_characters': 'Enter at least 2 characters',
  'select_booking_source': 'Select booking source',
  'no_charges': 'No charges',
  'items_count': 'items',
  'voided': 'Voided',
  'by_label': 'By',
  'paid_short': 'Paid',
  'marked_notifications_read': 'Marked notifications as read',
  'app_description': 'Hoang Lam Heritage Suites apartment management application',
  'developed_by': 'Developed by: Duy Lam',
  'copyright_notice': '© 2024 Hoang Lam Heritage Suites.\nAll rights reserved.',
  'dd10_form_description': 'Form DD10 (Decree 144/2021): Residence management register',
  'na17_form_description': 'Form NA17 (Circular 04/2015): Foreign guest temporary residence declaration',
  'form_type': 'Form type',
  'inspection_info': 'Inspection info',
  'room_id_required': 'Room ID *',
  'inspection_date_label': 'Inspection date',
  'inspection_template_optional': 'Inspection template (optional)',
  'no_default_template': 'No default template',
  'confirm_delete_template': 'Are you sure you want to delete this template?',
  'template_deleted': 'Template deleted',
  'important_label': 'Important',
  'inspection_checklist': 'Inspection checklist',
  'copy_template': 'Copy',
  'inspection_result': 'Inspection result',
  'score_label': 'Score',
  'passed_label': 'Passed',
  'issues_count': 'issues',
  'critical_count': 'critical',
  'no_checklist_items': 'No checklist items',
  'images_label': 'Images',
  'actions_required': 'Actions required',
  'view_image': 'View image',
  'expected_date': 'Expected date',
  'inspector': 'Inspector',

  // ===== PHASE C3: REMAINING HARDCODED STRINGS =====

  // Common/Actions
  'undo': 'Undo',
  'share_btn': 'Share',
  'complete_action': 'Complete',
  'resend_btn': 'Resend',
  'email_label': 'Email',
  'phone_label': 'Phone',
  'unknown_error': 'Unknown',
  'confirm_delete_title': 'Confirm Delete',
  'confirm_cancel_label': 'Confirm Cancel',
  'error_with_details': 'Error',

  // Booking Statuses
  'status_pending': 'Pending Confirmation',
  'status_confirmed': 'Confirmed',
  'status_checked_in': 'Checked In',
  'status_checked_out': 'Checked Out',
  'status_cancelled': 'Cancelled',
  'status_no_show': 'No Show',

  // Financial
  'delete_category': 'Delete Category',
  'category_deleted_msg': 'Category deleted',
  'expense_label': 'Expenses',
  'profit_label': 'Profit',
  'discount_label': 'Discount',
  'transactions_label': 'transactions',
  'total_amount_vnd': 'Total (VND)',

  // Group Booking
  'stay_period': 'Stay Period',
  'additional_info_section': 'Additional Information',
  'example_group_name': 'Ex: Tour Group ABC',
  'no_group_bookings': 'No group bookings',
  'rooms_count_suffix': 'rooms',
  'guests_count_suffix': 'guests',
  'rooms_needed': 'Rooms needed',
  'check_in_date_label': 'Check-in date',
  'check_out_date_label': 'Check-out date',
  'group_updated': 'Updated',
  'group_created': 'Booking created',
  'contact_person_required': 'Contact Person',
  'phone_required': 'Phone',
  'assign_rooms': 'Assign Rooms',
  'cancel_group': 'Cancel',
  'confirm_group': 'Confirm',
  'check_in_group': 'Check-in',
  'check_out_group': 'Check-out',

  // Night Audit
  'recalculate': 'Recalculate',
  'recalculate_error': 'Recalculation error',
  'close_audit_btn': 'Close Audit',
  'no_audits_yet': 'No audits yet',

  // Minibar
  'minibar_pos': 'Minibar POS',
  'no_products_in_category': 'No products in this category',
  'no_sales_yet': 'No sales yet',
  'sales_history_here': 'Sales history will appear here',
  'mark_as_charged': 'Mark as charged',
  'payment_successful': 'Payment successful',
  'confirm_payment_title': 'Confirm Payment',
  'product_deleted_msg': 'Product deleted',

  // Reports
  'occupancy_label': 'Occupancy',
  'no_expenses_label': 'No expenses in this period',

  // Room Inspection Stats
  'inspection_statistics': 'Inspection Statistics',
  'total_inspections': 'Total Inspections',
  'completed_inspections': 'Completed',
  'needs_attention': 'Needs Attention',
  'average_score': 'Average Score',
  'issues_detected': 'Issues Detected',
  'critical_label': 'Critical',
  'failed_label': 'Failed',
  'inspection_completed': 'Inspection completed',
  'unchecked_critical_items': 'unchecked critical items',

  // Lost & Found
  'filter_by_category_label': 'Filter by Category',
  'statistics_label': 'Statistics',
  'total_count_label': 'Total',
  'unclaimed_value': 'Unclaimed Value',
  'by_status_label': 'By Status',

  // Settings Help
  'help_room_management': 'Room Management',
  'help_room_management_desc': 'View room status, change status, create new bookings.',
  'help_bookings': 'Bookings',
  'help_bookings_desc': 'Manage check-in, check-out, and booking calendar.',
  'help_housekeeping': 'Housekeeping',
  'help_housekeeping_desc': 'Assign room cleaning, track maintenance.',
  'help_finance': 'Finance',
  'help_finance_desc': 'Income/expense reports, manage guest folios.',
  'help_night_audit': 'Night Audit',
  'help_night_audit_desc': 'End-of-day audit, revenue reconciliation.',
  'english': 'English',
  'push_notifications_label': 'Push notifications',

  // Pricing
  'min_nights_stay_label': 'Minimum',
  'includes_breakfast_label': 'Includes breakfast',
  'no_arrivals_label': 'No arrivals',
  'no_departures_label': 'No departures',
  'schedule_conflict_warning': 'Schedule Conflict Warning',
  'from_date_required': 'From date',
  'to_date_required': 'To date',
  'select_date_required': 'Select date',

  // Staff
  'owner_manager_filter': 'Owner/Mgr',
  'staff_member': 'Staff',
  'username_field': 'Username',
  'phone_field': 'Phone number',
  'copied_value_msg': 'Copied',

  // Declaration
  'has_format_multi_sheet': 'Formatted, multiple sheets',
  'text_format_popular': 'Text format, popular',

  // Folio
  'folio': 'Folio',
  'cancel_charge_title': 'Cancel Charge',

  // Booking Source
  'walk_in': 'Walk-in',
  'phone_source': 'Phone',
  'rank_label': 'Rank',

  // Housekeeping Checklist Items
  'change_bed_sheets': 'Change bed sheets',
  'vacuum': 'Vacuum',
  'mop_floor': 'Mop floor',
  'restock_supplies': 'Restock supplies',
  'check_minibar': 'Check minibar',
  'change_towels': 'Change towels',
  'empty_trash': 'Empty trash',
  'restock_water': 'Restock water',
  'deep_clean_bathroom': 'Deep clean bathroom',
  'wash_curtains': 'Wash curtains',
  'clean_ac': 'Clean air conditioner',
  'clean_fridge': 'Clean refrigerator',
  'check_furniture': 'Check furniture',
  'check_cleanliness': 'Check cleanliness',
  'check_equipment': 'Check equipment',
  'check_supplies': 'Check supplies',
  'check_safety': 'Check safety',
  'check_for_issues': 'Check for issues',
  'perform_repair': 'Perform repair',
  'reinspect': 'Reinspect',
  'enter_task_notes': 'Enter task notes...',

  // ===== PHASE C4: COMPREHENSIVE L10N COVERAGE =====
  // Night Audit
  'total_income': 'Total income',
  'net_profit': 'Net profit',
  'other_revenue': 'Other revenue',
  'rooms_occupied': 'Occupied',
  'rooms_cleaning': 'Cleaning',
  'rooms_maintenance': 'Maintenance',
  'no_shows': 'No shows',
  'cancellations_label': 'Cancellations',
  'pending_payments': 'Pending payments',
  'payment_details': 'Payment details',
  'other_payment': 'Other',
  'notes_label': 'Notes',
  'closing_audit': 'Closing...',
  'audit_history': 'Audit history',
  'load_history_error': 'Error loading history',
  'close_audit_error': 'Error closing audit',
  'revenue_short': 'Rev',
  'profit_short': 'Profit',
  'status_label': 'Status',
  'room_label': 'Room',
  'occupancy_filled': 'filled',
  'close_button': 'Close',

  // Report
  'report_load_error': 'Error loading report',
  'no_data_in_period': 'No data in this period',
  'last_90_days': '90 days',
  'revenue_label': 'Revenue',
  'expenses_label': 'Expenses',
  'main_kpis': 'Key metrics',
  'details_label': 'Details',
  'total_expenses': 'Total expenses',
  'no_expenses_in_period': 'No expenses in this period',

  // Staff
  'no_search_results': 'No results found',
  'staff_role': 'Staff',
  'housekeeping_short': 'HK',
  'permissions_label': 'Permissions',
  'no_permissions_assigned': 'No permissions assigned',
  'perm_view_all_data': 'View all data',
  'perm_manage_finance': 'Manage finance',
  'perm_manage_bookings': 'Manage bookings',
  'perm_manage_staff': 'Manage staff',
  'perm_edit_room_prices': 'Edit room prices',
  'perm_night_audit': 'Night audit',
  'perm_reports_stats': 'Reports & statistics',
  'perm_view_bookings': 'View bookings',
  'perm_update_room_status': 'Update room status',
  'perm_view_room_list': 'View room list',
  'perm_update_cleaning': 'Update cleaning',
  'perm_report_maintenance': 'Report maintenance',
  'copy_tooltip': 'Copy',
  'staying': 'Staying',

  // Declaration
  'date_range_label': 'Date range',
  'file_exported_success': 'File exported successfully',
  'bookings_marked_as_declared': 'Bookings have been marked as "Declared"',
  'open_file_btn': 'Open',
  'share_file_btn': 'Share',
  'file_format_label': 'File format',
  'last_7_days_label': 'Last 7 days',
  'last_30_days_label': 'Last 30 days',
  'declaration_form_descriptions': '• ĐD10: Residence management register (Vietnamese guests)\n• NA17: Temporary residence declaration (Foreign guests)',

  // Group Booking Detail
  'phone': 'Phone',
  'email': 'Email',
  'check_in_date': 'Check-in date',
  'check_out_date': 'Check-out date',
  'payment_label': 'Payment',
  'discount_amount': 'Discount',
  'yes_label': 'Yes',
  'not_yet_label': 'Not yet',
  'notes_section': 'Notes',
  'confirm_group_booking': 'Confirm group booking?',
  'confirmed_msg': 'Confirmed',
  'confirm_group_check_in': 'Confirm check-in for group',
  'confirm_group_check_out': 'Confirm check-out for group',
  'checked_out_success': 'Checked out',
  'cancelled_msg': 'Cancelled',
  'room_id_list_hint': 'Ex: 1, 2, 3 (Room IDs, separated by commas)',

  // Minibar
  'product': 'Product',
  'quantity': 'Quantity',
  'unit_price': 'Unit price',
  'charged': 'Charged',
  'not_charged': 'Not charged',
  'sale_details': 'Sale details',
  'empty_cart': 'Cart is empty',
  'checkout_btn': 'Checkout',
  'clear_all': 'Clear all',
  'discontinued': 'Discontinued',
  'cart_title': 'Cart',
  'product_added_success': 'Product added successfully',
  'invalid': 'Invalid',
  'active_status_label': 'Active',
  'cost_amount': 'Cost',
  'activate_label': 'Activate',

  // Housekeeping
  'unassigned': 'Unassigned',
  'complete_btn': 'Complete',
  'filter_maintenance_requests': 'Filter maintenance requests',
  'clear_filters': 'Clear filters',
  'apply_btn': 'Apply',
  'filter_tasks': 'Filter tasks',
  'task_type_label': 'Task type',
  'tomorrow': 'Tomorrow',

  // Guest
  'search_guest_hint': 'Search guest by name, phone, ID...',
  'id_number': 'ID Number',

  // Common Widgets
  'offline_sync_message': 'Offline - Data will sync when connected',
  'income_expense_chart': 'Income & Expense Chart',
  'income_label': 'Income',
  'expense_short': 'Expense',

  // Room Folio
  'void_charge': 'Void charge',
  'confirm_void_charge': 'Are you sure you want to void charge',
  'charge_amount': 'Amount',
  'void_reason_required': 'Void reason *',
  'enter_void_reason': 'Enter void reason',
  'please_enter_void_reason': 'Please enter void reason',
  'charge_voided_success': 'Charge voided successfully',
  'cannot_void_charge': 'Cannot void charge',
  'confirm_void': 'Confirm void',

  // Inspection Template
  'default_badge': 'Default',
  'duplicate_btn': 'Duplicate',
  'critical': 'Critical',
  'template_duplicated': 'Template duplicated successfully',
  'room_type_id_optional': 'Room Type ID (optional)',
  'room_type_id_hint': 'Ex: 1, 2, 3',
  'amenities_category': 'Amenities',
  'electronics_category': 'Electronics',
  'bed_clean': 'Bed is clean',
  'bed_sheet_replaced': 'Bed sheet replaced',
  'pillows_blanket_clean': 'Pillows and blankets clean',
  'toilet_clean': 'Toilet clean',
  'towels_complete': 'Towels complete',
  'toiletries_complete': 'Toiletries complete',
  'ac_working': 'AC working',
  'tv_working': 'TV working',
  'fridge_working': 'Fridge working',
  'create_new_inspection_template': 'Create new inspection template',

  // Room Inspection Detail
  'booking_code_label': 'Booking code',
  'action_required_section': 'Action required',
  'view_photo': 'View photo',
  'completed_label': 'Completed',

  // Booking Source
  'select_booking_source_hint': 'Select booking source',

  // Phase C5
  'total_room_nights_available': 'Total available room nights',
  'total_room_nights_sold': 'Total sold room nights',
  'no_expenses_in_date_range': 'No expenses in this date range',
  'role_housekeeping_label': 'Housekeeping',
  'rooms_suffix': 'rooms',
  'nights_suffix': 'nights',
  'guests_suffix': 'guests',
  'transactions_suffix': 'transactions',
  'avg_short': 'Avg',

  // Phase C6
  'excel_format_desc': 'Formatted, multiple sheets',
  'csv_format_desc': 'Text format, widely used',
  'sales_history_hint': 'Sales history will appear here',
  'guest_label': 'Guest',
  'total_price': 'Total price',
  'search_product_hint': 'Search products...',
  'select_booking_first': 'Please select a booking first',
  'clear_cart_title': 'Clear cart',
  'clear_cart_confirm': 'Are you sure you want to remove all products from the cart?',
  'confirm_checkout': 'Confirm payment',
  'guest_name_label': 'Guest',
  'total_label': 'Total',
  'checkout_success': 'Payment successful',
  'selling_price': 'Selling price',
  'required_field': 'Required',
  'active_label': 'Active',
  'active_selling': 'On sale',
  'inactive_selling': 'Discontinued',
  'update_label': 'Update',
  'product_added_msg': 'Product added successfully',
  'confirm_delete_product_msg': 'Are you sure you want to delete',
  'product_deleted_success': 'Product deleted',
  'room_count_label': 'Rooms',
  'guest_count_label': 'Guests',
  'deposit_label': 'Deposit',
  'paid_status': 'Paid',
  'assign_rooms_label': 'Assign rooms',
  'room_id_list_label': 'Room ID list',
  'rooms_assigned_success': 'Rooms assigned',
  'assign_rooms_first_msg': 'Please assign rooms first',
  'checked_in_msg': 'Checked in',
  'checked_out_msg': 'Checked out',
  'cancelled_status': 'Cancelled',
  'scheduled_date_label': 'Scheduled date',
  'inspector_label': 'Inspector',
  'inspection_results': 'Inspection results',
  'pass_label': 'Pass',
  'issues_label': 'issues',
  'critical_issues_label': 'critical',
  'checklist_label': 'Checklist',
  'edit_label': 'Edit',
  'duplicate_label': 'Duplicate',
  'template_created_success': 'Template created successfully',
  'edit_feature_in_progress': 'Edit feature is under development',
  'template_deleted_success': 'Template deleted',
  'create_new_template_title': 'Create new inspection template',
  'template_name_label': 'Template name',
  'inspection_type_label': 'Inspection type',
  'default_template_label': 'Default template',
  'default_template_hint': 'Use this template when creating new inspections',
  'checklist_count': 'Checklist',
  'add_label': 'Add',
  'create_template_btn': 'Create template',
  'add_checklist_item_title': 'Add checklist item',
  'category_label': 'Category',
  'bedroom_category': 'Bedroom',
  'bathroom_category': 'Bathroom',
  'safety_category': 'Safety',
  'please_add_at_least_one': 'Please add at least one checklist item',
  'items_suffix': 'items',

  // ===== PHASE C7: HARDCODED VIETNAMESE STRING EXTRACTION =====

  // Date Rate Override Form
  'tet_holiday': 'Tet Holiday',
  'christmas': 'Christmas',
  'summer_season': 'Summer',
  'price_section': 'Price',
  'price_for_this_date': 'Price for this date *',
  'vnd_suffix': 'VND',
  'please_enter_price': 'Please enter price',
  'price_must_be_positive': 'Price must be greater than 0',
  'create_price_multiple_days': 'Create price for multiple days',
  'create_date_rate': 'Create date rate',
  'please_select_date': 'Please select a date',
  'date_rate_created_for_days': 'Created price for {days} days',
  'delete_date_rate_title': 'Delete date rate?',
  'select_date_placeholder': 'Select date',

  // Complete Task Dialog
  'clean_bathroom': 'Clean bathroom',
  'general_cleaning': 'General cleaning',
  'clean_glass': 'Clean glass',
  'complete_task_title': 'Complete task',
  'complete_all_items_warning': 'Please complete all items',

  // Financial Category Screen
  'cannot_delete_category_msg': 'Cannot delete category "{name}" because it has {count} related transactions.',
  'confirm_delete_category_msg': 'Are you sure you want to delete category "{name}"?\n\nThis action cannot be undone.',
  'active_in_use_count': 'Active ({count})',
  'hidden_count': 'Hidden ({count})',
  'edit_category': 'Edit category',
  'add_income_category_title': 'Add income category',
  'add_expense_category_title': 'Add expense category',
  'category_updated_msg': 'Category updated',
  'category_created_msg': 'New category created',
  'income_short': 'Income',
  'preview_label': 'Preview',
  'category_name_placeholder': 'Category name',
  'example_electricity': 'e.g. Electricity bill',
  'example_electricity_en': 'e.g. Electricity',

  // Room Inspection Form Screen
  'enter_room_id_hint': 'Enter room ID',
  'please_enter_room_id': 'Please enter room ID',
  'no_default_template_desc': 'No default templates available. You can create new templates from the template list.',
  'checklist_items_suffix': 'checklist items',
  'creating_text': 'Creating...',
  'create_inspection_btn': 'Create inspection',
  'inspection_not_found': 'Inspection not found',
  'complete_btn_label': 'Complete',
  'progress_count': 'Progress:',
  'important_badge': 'Important',
  'pass_btn': 'Pass',
  'fail_btn': 'Fail',
  'enter_notes_hint': 'Enter notes...',
  'action_required_if_any': 'Action required (if any)',
  'describe_action_required': 'Describe required action...',
  'please_select_room_msg': 'Please select a room',
  'inspection_created_success': 'Inspection created successfully',

  // PHASE C7 Batch 2
  'check_in_date_required': 'Check-in date *',
  'check_out_date_required': 'Check-out date *',
  'nights_count_display': 'Nights: {count}',
  'no_pending_inspections': 'No pending inspections',
  'no_completed_inspections': 'No completed inspections',
  'no_action_required_inspections': 'No inspections requiring action',
  'no_inspections_yet': 'No inspections yet',
  'pending_inspections_label': 'Pending',
  'total_issues': 'Total issues',
  'room_with_number': 'Room {number}',
  'score_value_display': 'Score: {value}%',
  'no_rate_plans_yet': 'No rate plans yet',
  'paused_status': 'Paused',
  'min_nights_stay_display': 'Minimum {count} nights',
  'from_date_display': 'From {date}',
  'to_date_display': 'Until {date}',
  'no_daily_rates_yet': 'No daily rates yet',

  // PHASE C7 Batch 3: Lost & Found strings
  'lost_and_found': 'Lost & Found',
  'no_claimed_items': 'No claimed items',
  'no_unclaimed_items': 'No unclaimed items',
  'no_lost_found_items': 'No lost & found items yet',
  'confirm_guest_claimed': 'Confirm guest has claimed the item?',
  'dispose_reason_title': 'Dispose reason',
  'dispose_reason_hint': 'Enter dispose/donation reason',

  // PHASE C7 Batch 3: Widget/screen strings
  'enter_amount_hint': 'Enter amount',
  'please_enter_amount': 'Please enter amount',
  'invalid_amount': 'Invalid amount',
  'card_payment': 'Card',
  'other_label': 'Other',
  'other_ota': 'Other OTA',
  'error_loading_staff_list': 'Error loading staff list',
  'assign_to_self': 'Assign to self',
  'deposit_label_amount': 'Deposit: {amount}',
  'overlap_warning_title': 'Schedule Overlap Warning',
  'overlap_warning_message': 'This room already has {count} bookings in the selected period. Do you want to continue?',
  'room_number_hint': 'E.g.: 101, 102, 201...',
  'paid_abbreviation': 'Paid',
  'phone_validation_length': 'Phone number must be 10-11 digits',
  'phone_validation_start_with_zero': 'Phone number must start with 0',
  'product_tab': 'Product',

  // ===== ENUM DISPLAY NAMES & ERROR MESSAGES (Batch 5) =====
  'booking_status_pending': 'Pending',
  'booking_status_confirmed': 'Confirmed',
  'booking_status_checked_in': 'Checked In',
  'booking_status_checked_out': 'Checked Out',
  'booking_status_cancelled': 'Cancelled',
  'booking_status_no_show': 'No Show',
  'booking_source_walk_in': 'Walk-in',
  'booking_source_phone': 'Phone',
  'booking_source_other_ota': 'Other OTA',
  'booking_source_other': 'Other',
  'payment_method_cash': 'Cash',
  'payment_method_bank_transfer': 'Bank Transfer',
  'payment_method_card': 'Card',
  'payment_method_ota_collect': 'OTA Collect',
  'payment_method_other': 'Other',
  'booking_type_overnight': 'Overnight',
  'booking_type_hourly': 'Hourly',
  'room_status_available': 'Available',
  'room_status_occupied': 'Occupied',
  'room_status_cleaning': 'Cleaning',
  'room_status_maintenance': 'Maintenance',
  'room_status_blocked': 'Blocked',
  'payment_type_deposit': 'Deposit',
  'payment_type_room_charge': 'Room Charge',
  'payment_type_extra_charge': 'Extra Charge',
  'payment_type_refund': 'Refund',
  'payment_type_adjustment': 'Adjustment',
  'payment_status_pending': 'Pending',
  'payment_status_completed': 'Completed',
  'payment_status_failed': 'Failed',
  'payment_status_refunded': 'Refunded',
  'payment_status_cancelled': 'Cancelled',
  'folio_type_room': 'Room Charge',
  'folio_type_minibar': 'Minibar',
  'folio_type_laundry': 'Laundry',
  'folio_type_food': 'Food',
  'folio_type_service': 'Service',
  'folio_type_extra_bed': 'Extra Bed',
  'folio_type_early_checkin': 'Early Check-in',
  'folio_type_late_checkout': 'Late Check-out',
  'folio_type_damage': 'Damage',
  'folio_type_other': 'Other',
  'month_1': 'January',
  'month_2': 'February',
  'month_3': 'March',
  'month_4': 'April',
  'month_5': 'May',
  'month_6': 'June',
  'month_7': 'July',
  'month_8': 'August',
  'month_9': 'September',
  'month_10': 'October',
  'month_11': 'November',
  'month_12': 'December',
  'id_type_cccd': 'National ID',
  'id_type_passport': 'Passport',
  'id_type_cmnd': 'Old National ID',
  'id_type_driving_license': 'Driving License',
  'id_type_other': 'Other',
  'id_type_cccd_full': 'CCCD (National ID Card)',
  'id_type_passport_full': 'Passport',
  'id_type_cmnd_full': 'CMND (Old ID Card)',
  'id_type_driving_license_full': 'GPLX (Driving License)',
  'id_type_other_full': 'Other',
  'gender_male': 'Male',
  'gender_female': 'Female',
  'gender_other': 'Other',
  'passport_type_regular': 'Regular',
  'passport_type_official': 'Official',
  'passport_type_diplomatic': 'Diplomatic',
  'passport_type_other': 'Other',
  'visa_type_visa': 'Visa',
  'visa_type_temporary_residence': 'Temporary Residence Card',
  'visa_type_visa_exemption_cert': 'Visa Exemption Certificate',
  'visa_type_abtc': 'ABTC Card',
  'visa_type_visa_exempt': 'Visa Exempt',
  'nationality_vietnam': 'Vietnam',
  'nationality_china': 'China',
  'nationality_south_korea': 'South Korea',
  'nationality_japan': 'Japan',
  'nationality_usa': 'USA',
  'nationality_france': 'France',
  'nationality_uk': 'UK',
  'nationality_australia': 'Australia',
  'nationality_germany': 'Germany',
  'nationality_russia': 'Russia',
  'nationality_thailand': 'Thailand',
  'nationality_singapore': 'Singapore',
  'nationality_malaysia': 'Malaysia',
  'nationality_taiwan': 'Taiwan',
  'nationality_hong_kong': 'Hong Kong',
  'nationality_other': 'Other',
  'task_type_checkout_clean': 'Checkout Clean',
  'task_type_stayover_clean': 'Stayover Clean',
  'task_type_deep_clean': 'Deep Clean',
  'task_type_maintenance': 'Maintenance',
  'task_type_inspection': 'Inspection',
  'housekeeping_status_pending': 'Pending',
  'housekeeping_status_in_progress': 'In Progress',
  'housekeeping_status_completed': 'Completed',
  'housekeeping_status_verified': 'Verified',
  'priority_low': 'Low',
  'priority_medium': 'Medium',
  'priority_high': 'High',
  'priority_urgent': 'Urgent',
  'maintenance_status_pending': 'Pending',
  'maintenance_status_assigned': 'Assigned',
  'maintenance_status_in_progress': 'In Progress',
  'maintenance_status_paused': 'Paused',
  'maintenance_status_completed': 'Completed',
  'maintenance_status_cancelled': 'Cancelled',
  'maint_cat_electrical': 'Electrical',
  'maint_cat_plumbing': 'Plumbing',
  'maint_cat_hvac': 'HVAC',
  'maint_cat_furniture': 'Furniture',
  'maint_cat_appliance': 'Appliance',
  'maint_cat_structural': 'Structural',
  'maint_cat_safety': 'Safety',
  'maint_cat_other': 'Other',
  'inspection_status_pending': 'Pending Inspection',
  'inspection_status_in_progress': 'Inspecting',
  'inspection_status_completed': 'Completed',
  'inspection_status_action_required': 'Action Required',
  'inspection_type_checkout': 'Post-Checkout',
  'inspection_type_checkin': 'Pre-Check-in',
  'inspection_type_routine': 'Routine',
  'inspection_type_maintenance': 'Maintenance',
  'inspection_type_deep_clean': 'Deep Clean',
  'inspection_cat_bedroom': 'Bedroom',
  'inspection_cat_bathroom': 'Bathroom',
  'inspection_cat_amenities': 'Amenities',
  'inspection_cat_electronics': 'Electronics',
  'inspection_cat_safety': 'Safety',
  'inspection_cat_general': 'General',
  'lost_found_status_found': 'Found',
  'lost_found_status_stored': 'In Storage',
  'lost_found_status_claimed': 'Claimed',
  'lost_found_status_donated': 'Donated',
  'lost_found_status_disposed': 'Disposed',
  'lost_found_cat_electronics': 'Electronics',
  'lost_found_cat_clothing': 'Clothing',
  'lost_found_cat_jewelry': 'Jewelry',
  'lost_found_cat_documents': 'Documents',
  'lost_found_cat_money': 'Money',
  'lost_found_cat_bags': 'Bags/Luggage',
  'lost_found_cat_personal': 'Personal Items',
  'lost_found_cat_other': 'Other',
  'cancel_policy_free': 'Free Cancellation',
  'cancel_policy_flexible': 'Flexible',
  'cancel_policy_moderate': 'Moderate',
  'cancel_policy_strict': 'Strict',
  'cancel_policy_non_refundable': 'Non-refundable',
  'user_role_owner': 'Owner',
  'user_role_manager': 'Manager',
  'user_role_staff': 'Staff',
  'user_role_housekeeping': 'Housekeeping',
  'night_audit_status_draft': 'Draft',
  'night_audit_status_completed': 'Completed',
  'night_audit_status_closed': 'Closed',
  'notification_type_new_booking': 'New Booking',
  'notification_type_booking_confirmed': 'Booking Confirmed',
  'notification_type_booking_cancelled': 'Booking Cancelled',
  'notification_type_checkin_reminder': 'Check-in Reminder',
  'notification_type_checkout_reminder': 'Check-out Reminder',
  'notification_type_checked_in': 'Checked In',
  'notification_type_checked_out': 'Checked Out',
  'notification_type_general': 'General Notice',
  'message_status_draft': 'Draft',
  'message_status_sending': 'Sending',
  'message_status_sent': 'Sent',
  'message_status_delivered': 'Delivered',
  'message_status_failed': 'Failed',
  'msg_template_booking_confirm': 'Booking Confirmation',
  'msg_template_pre_arrival': 'Pre-arrival Info',
  'msg_template_checkout_reminder': 'Check-out Reminder',
  'msg_template_review_request': 'Review Request',
  'msg_template_custom': 'Custom',
  'report_group_daily': 'Daily',
  'report_group_weekly': 'Weekly',
  'report_group_monthly': 'Monthly',
  'report_type_occupancy': 'Room Occupancy',
  'report_type_revenue': 'Revenue',
  'report_type_expense': 'Expense',
  'report_type_kpi': 'KPI',
  'report_type_channel': 'Channels',
  'report_type_guest': 'Guests',
  'comparison_previous_period': 'Previous Period',
  'comparison_previous_year': 'Previous Year',
  'comparison_custom': 'Custom',
  'demographics_nationality': 'Nationality',
  'demographics_source': 'Booking Source',
  'demographics_room_type': 'Room Type',
  'declaration_dd10': 'ĐD10 - Vietnamese Guests',
  'declaration_na17': 'NA17 - Foreign Guests',
  'declaration_all': 'All',
  'declaration_dd10_desc': 'Accommodation management book (Decree 144/2021)',
  'declaration_na17_desc': 'Foreign guest temporary residence form (Circular 04/2015)',
  'declaration_all_desc': 'Both ĐD10 and NA17',
  'group_status_pending': 'Pending',
  'group_status_confirmed': 'Confirmed',
  'group_status_checked_in': 'Checked In',
  'group_status_checked_out': 'Checked Out',
  'group_status_cancelled': 'Cancelled',
  'minibar_charged': 'Charged',
  'minibar_uncharged': 'Not Charged',
  'guest_number': 'Guest #{guest}',
  'report_metric_occupancy': 'Occupancy',
  'report_metric_bookings': 'Bookings Count',
  'report_metric_guests': 'Guests Count',
  'month_label': 'Month {month}',
  'entry_type_income': 'Income',
  'entry_type_expense': 'Expense',
  'search_min_chars': 'Search query must be at least 2 characters',
  'guest_added_success': 'Guest added successfully',
  'guest_updated_success': 'Guest information updated',
  'error_no_network': 'No network connection',
  'error_phone_registered': 'Phone number already registered',
  'error_id_registered': 'ID/Passport number already registered',
  'error_phone_digits': 'Phone number must be 10-11 digits',
  'error_cannot_delete_guest': 'Cannot delete guest with booking history',
  'error_guest_not_found': 'Guest not found',
  'error_generic': 'An error occurred. Please try again.',
  'error_wrong_credentials': 'Wrong username or password',
  'error_folio_load': 'Cannot load folio: {error}',
  'error_charge_add': 'Cannot add charge: {error}',
  'error_charge_void': 'Cannot void charge: {error}',
  'error_no_booking_selected': 'No booking selected',
  'error_empty_cart': 'Cart is empty',
  'error_room_exists': 'Room number already exists',
  'error_cannot_delete_room': 'Cannot delete room with active bookings',
  'error_report_export': 'Report export error: {error}',
  'biometric_authenticate_login': 'Authenticate to login',
  'biometric_fingerprint': 'Fingerprint',
  'biometric_iris': 'Iris Scan',
  'biometric_generic': 'Biometrics',
  'date_today': 'Today',
  'date_tomorrow': 'Tomorrow',
  'date_yesterday': 'Yesterday',
  'date_in_days': 'In {count} days',
  'date_days_ago': '{count} days ago',
  'day_sunday': 'Sunday',
  'day_monday': 'Monday',
  'day_tuesday': 'Tuesday',
  'day_wednesday': 'Wednesday',
  'day_thursday': 'Thursday',
  'day_friday': 'Friday',
  'day_saturday': 'Saturday',
  'error_booking_conflict': 'Room is already booked for this period.',
  'error_cache': 'Cache error.',
  'error_offline': 'No network connection. Working offline.',
  'error_connection_timeout': 'Connection timed out. Please try again.',
  'error_no_connection': 'No network connection.',
  'error_request_cancelled': 'Request was cancelled.',
  'error_unknown': 'An error occurred. Please try again.',
  'error_invalid_data': 'Invalid data.',
  'error_session_expired': 'Session expired. Please login again.',
  'error_no_permission': 'You do not have permission for this action.',
  'error_not_found': 'Data not found.',
  'error_conflict': 'Data conflict.',
  'error_server': 'Server error. Please try again later.',

};

// Delegate
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['vi', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Extension for easy access
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
