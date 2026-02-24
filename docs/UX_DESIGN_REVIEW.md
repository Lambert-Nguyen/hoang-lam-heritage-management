
UX Workflow Review: Non-Technical User Perspective
Scenario: Your Mom (Owner/Manager) — First Day
Opening the App for the First Time
What works well:

Splash screen → Login is clean and standard
Biometric setup prompt after first login is smart — your mom can use Face ID next time instead of remembering passwords
Vietnamese-first localization is perfect for the target audience
Potential issue:

There's no registration flow — accounts must be created by someone else (likely via Django admin or staff management screen). This is actually correct for a hotel management app — you don't want random people signing up. But it means you will need to create her account first and hand her credentials.
Scenario: Daily Morning Flow (Your Mom opens the app)
Step 1: Dashboard
The dashboard shows the right things at a glance:

How many rooms available/occupied
Today's revenue
Who's checking in today, who's checking out
Room status grid with color coding
This is well-designed. A non-technical user can look at this and immediately understand the state of the business.

One concern: The dashboard has a LOT of information (stats row + revenue card + occupancy widget + room grid + upcoming checkouts + upcoming checkins). On a phone screen, this could feel overwhelming. Consider whether your mom would actually scroll through all of this or just want to see "who's coming today, who's leaving today."

Scenario: Your Sister Finds a Walk-in Guest and Wants to Create a Booking
The Current Flow:
Navigate to Bookings tab (bottom nav)
Tap "Create Booking" button
Fill out the booking form:
Select room
Select or create guest
Set check-in / check-out dates
Enter number of guests
Set nightly rate
Select payment method
Enter deposit amount
Add special requests / notes
Select booking source
Submit
Issues I See:
1. Room Selection Before Availability Check
The form asks to "select room" — but does your sister know which rooms are available? She'd need to either:

Go back to the dashboard to check the room grid first
Or the form should show only available rooms filtered by date
If the room picker doesn't filter by the selected dates, this is a major UX problem. Your sister would have to mentally track which rooms are free.

2. Guest Creation is Inline
If the guest is new (walk-in), your sister needs to create a guest profile. The question is: does this happen inside the booking form or does she need to navigate away to the guest management screen first?

Looking at the flow, there's a "select or create guest" step — if this is a bottom sheet or dialog within the booking form, that's good. If she has to leave the form, fill out guest details separately, then come back — that's disruptive.

3. Too Many Fields for a Walk-in
For a walk-in guest, your sister just needs:

Which room
Guest name + phone (maybe ID)
How many nights
Payment
But the form asks for: booking source, special requests, internal notes, deposit amount, nightly rate, payment method. That's 9+ fields. For a walk-in at midnight, this is too much friction.

Recommendation: Consider a "Quick Booking" mode for walk-ins that only requires essential fields, with optional fields collapsed/hidden.

Scenario: After the Booking is Created — What Next?
The Lifecycle Gap
Here's where I see a workflow design concern:


Booking Created (pending)
    → Confirmed
        → Check In
            → [Guest stays, charges accumulate on Folio]
                → Check Out
                    → Payment settled
Questions a non-technical user would have:

"The guest is standing in front of me — how do I check them in?"

From the booking detail screen, there should be a prominent "Check In" button
From the dashboard's "Upcoming Check-ins" list, there should be a quick action
This seems to exist — good
"The guest wants to buy a drink from the minibar — how do I charge them?"

Navigate to... Folio? Minibar POS? Where?
The Folio screen exists at room_folio_screen.dart and the Minibar POS at minibar_pos_screen.dart
But neither is accessible from the bottom nav. The user needs to find these through room details or booking details
This could be confusing for a non-technical user
"The guest is leaving — how do I check them out?"

From booking detail → "Check Out" button
But does it warn about unpaid charges on the folio?
Does it generate a receipt automatically?
"How do I see the receipt / bill?"

There's a receipt_preview_screen.dart — but is it accessible from the checkout flow?
Major UX Concerns
1. Navigation Depth Problem
The 4-tab bottom nav (Home, Bookings, Finance, Settings) covers the basics, but many critical daily features are buried deep:

Feature	How to Access	Depth
Room status	Home → Room grid	1 tap
Create booking	Bookings → + button	2 taps
Check in guest	Bookings → Find booking → Detail → Check In	3-4 taps
Add minibar charge	??? → Room → Folio → Add	3-4+ taps
Housekeeping tasks	Not in bottom nav at all	Unknown
Lost & Found	Not in bottom nav	Unknown
Night Audit	Not in bottom nav	Unknown
Housekeeping, Minibar POS, and Room Inspections have no direct bottom-nav entry point. For a housekeeping staff member, they'd need to navigate through some menu to find their tasks every time.

2. Role-Based Navigation Missing
Your mom (owner) and your sister (staff) see the same bottom navigation:

Home, Bookings, Finance, Settings
But housekeeping staff also sees this same nav — yet they can't manage bookings and shouldn't need the Finance tab. The nav doesn't adapt to the user's role, which means:

Housekeeping staff sees Finance tab but can't use it (confusing)
Staff sees Finance tab but can't access it (frustrating)
Recommendation: The bottom nav or home screen should adapt based on role. A housekeeping user should see: Home, Tasks, Inspections, Settings.

3. No Quick Actions / FAB Menu
The most common daily actions should be 1-tap away:

Quick check-in
Quick booking
Quick charge
Mark room as cleaned
Currently, each requires navigating through multiple screens.

4. The Booking Calendar vs. Booking List
There are two booking views — list and calendar. But the calendar view (booking_calendar_screen.dart) is a separate route, not a toggle on the bookings tab. This means your mom might not even discover it exists.

5. Finance Tab for Daily Revenue
Your mom probably just wants to see "how much money did we make today." The Finance tab seems to show a list of entries rather than a summary-first view. The dashboard has a revenue card, but if she taps it, does it go to a detailed breakdown?

What's Well Designed
Room status color coding (green=available, red=occupied, yellow=cleaning) — visual and intuitive
Biometric login — perfect for daily use, no password remembering
Vietnamese-first — correct for the target audience
Booking sources (Walk-in, OTA, Phone) — reflects real hotel operations
Payment methods (MoMo, VNPay, Bank Transfer, Cash) — covers Vietnamese payment ecosystem perfectly
Session auto-logout — good security for a shared device
Dashboard as home — showing occupancy and today's activity first is the right choice
Guest management — storing guest ID details, history — professional
Folio system — tracking itemized charges per booking is industry-standard
Summary of Recommendations
Priority	Issue	Recommendation
High	Booking form too complex for walk-ins	Add "Quick Booking" mode with minimal fields
High	Housekeeping/Minibar not in main nav	Add a "More" tab or role-based nav
High	Room selection doesn't clearly show availability	Filter rooms by date in booking form
Medium	Check-in/out requires too many taps	Add quick actions on dashboard cards
Medium	Same nav for all roles	Adapt bottom nav based on user role
Medium	Calendar view is hidden	Add list/calendar toggle on Bookings tab
Low	Dashboard info-dense	Consider collapsible sections or priority ordering
Low	No onboarding	Add first-time usage tips for non-tech users
The "Mom Test" Verdict
Your mom could use this app daily for checking room status and seeing revenue. The dashboard gives her what she needs at a glance.

But if she needs to do something (create a booking, check someone in, handle a minibar charge), she'd likely get lost navigating through multiple screens. The app feels designed like a comprehensive admin panel rather than a daily operations tool.

The biggest gap: there's no task-oriented shortcut layer. A non-technical user thinks in terms of "a guest just arrived" or "someone wants to buy water" — not "navigate to bookings, find the booking, open details, tap check-in."

Want me to design and implement any of these improvements?