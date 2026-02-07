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
  'phone_must_be_10': 'Số điện thoại phải có 10 số',
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
  'phone_must_be_10': 'Phone number must have 10 digits',
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
