# Tuition Manager

A mobile-first tuition management web app starter built with HTML, CSS, JavaScript and Supabase.

## Included in this project

- Professional responsive login and registration screens
- Email + password login
- Registration flow with email OTP verification
- Same-page password reset: enter email + new password + confirm password, request OTP, verify OTP, then save the new password
- First-login tuition name setup
- Teacher dashboard
- Student management for Classes 1–12
- Daily attendance register
- Cash and manually verified online/UPI fee records, monthly dues and printable receipts
- Teacher-uploaded UPI QR image in Settings
- PWA manifest, service worker, install prompt and Android install icons
- Class and timetable records
- Homework/test planning
- Basic reports and CSV exports
- Supabase Row Level Security policies for private per-teacher data

## 1. Design ideas to make the app look premium

- Keep the dashboard clean and easy to scan, with clear summary cards for students, attendance, fees collected and pending dues.
- Use consistent spacing, readable typography, rounded cards and clear button labels.
- Keep the layout mobile-first so teachers can use the main workflows comfortably on a phone, while remaining responsive on desktop.
- Use clear success, warning and error states; avoid clutter and unnecessary pop-ups.
- Use simple hover/focus feedback and lightweight transitions without slowing down the app.
- Keep forms short, group related fields together, and make fee status and payment method easy to recognize.

## 2. Most useful features for a tuition teacher

- Manage students for Classes 1–12 and keep each tuition teacher's records isolated.
- Record daily attendance and review attendance history.
- Track monthly fees, paid amounts and pending dues; view the six-month fee-collection trend on the dashboard.
- Record cash or online/UPI payments, show the teacher's uploaded QR, and print a receipt after the teacher verifies the payment.
- Use reports and CSV exports to review and keep a local copy of records.
- Manage classes/timetable and homework/test plans from the same app.
- Use email OTP for account registration and password recovery; normal sign-in uses email and password.
- Install the website on a phone as a PWA after deploying it to an HTTPS host.

## 3. Selected colour and design

- **Theme:** Emerald Green.
- **Appearance:** Light mode.
- **Design direction:** professional, clean, friendly and easy to read, with green primary actions and neutral light backgrounds.
- **Priority:** improve design and useful features while preserving existing workflows.
- Keep status colours (such as warning, error and success) distinct from the main brand colour for clarity.

## 1. Create a Supabase project

1. Sign in at https://supabase.com and create a project.
2. Open **Project Settings → API** (or the project's API keys page).
3. Copy the **Project URL** and the **publishable/anon key**.
4. Open `app.js` and replace:
   - `https://YOUR_PROJECT_ID.supabase.co`
   - `YOUR_SUPABASE_ANON_KEY`
5. Do not put a `service_role` key in browser code.

## 2. Create database tables and privacy rules

1. In Supabase, open **SQL Editor**.
2. Open `supabase_schema.sql` from this folder.
3. Copy the whole SQL file into a new SQL query and run it.
4. Confirm the tables exist under **Table Editor** and RLS is enabled.

## 3. Configure email OTP signup

1. In Supabase, open **Authentication → Providers → Email** and enable Email.
2. Enable email confirmation so new teachers must verify their email before first use.
3. To send an 8-digit code rather than a link, open **Authentication → Email Templates → Confirm signup** and make the template include `{{ .Token }}` as the code. The app expects an 8-digit email OTP, matching the Supabase project setting.
4. Supabase's built-in email delivery is rate-limited and intended for testing. For multiple teachers, configure a custom SMTP provider in **Authentication → SMTP Settings** and follow that provider's sender/domain verification requirements.
5. After signup verification, teachers log in using email + password; OTP is not requested on every login. Forgot password stays on the same login page and uses email + new password + confirm password + 8-digit OTP. In **Authentication → Email Templates → Reset Password**, make sure the email template includes `{{ .Token }}` so the user receives a numeric OTP; a link-only template will not work with the OTP form. Test with a real account before relying on it.
6. The SQL schema includes a migration-safe `email` column for teacher profiles. Run the updated `supabase_schema.sql` in SQL Editor so existing projects also get that column.
7. Set allowed redirect URLs to your local/deployed site origin and test signup, code verification, login, logout, and password reset.

Twilio is not required for this email-based flow.

## 4. Authentication settings

- Enable Email provider and email confirmation.
- Confirm both **Confirm signup** and **Reset Password** email templates contain `{{ .Token }}` to send numeric codes rather than relying only on links.
- Configure custom SMTP before inviting many teachers; the built-in service has low sending limits.
- Set allowed redirect URLs for your local/deployed site origin.
- Test with a test account before entering real student data.

## 5. Test locally

Because this is a static website, no Python server is required. You can:
- Open `index.html` in a browser for a quick visual check (Supabase features need the keys and auth configuration), or
- Use VS Code's Live Server extension to serve the folder locally.

## 6. Free-tier hosting

You can deploy the static files to a provider such as Netlify or another static host with a free tier:
1. Create a Git repository and upload `index.html`, `styles.css`, `app.js`, and `supabase_schema.sql` (README optional).
2. Import the repository in your hosting provider.
3. Use the site root as the publish directory. There is no build command.
4. Add the final deployed origin to Supabase Authentication's allowed redirect URLs.
5. Test on both phone and desktop.

Free-tier limits and availability can change. A custom domain is generally separate from free hosting.

## Security notes

- This browser app must use only the Supabase publishable/anon key; never use the service-role secret in frontend files.
- RLS policies are included to isolate each teacher's records.
- The app has no student login.
- Before production, test policies with two separate teacher accounts to confirm one teacher cannot read another teacher's rows.
- Do not enter real student data until authentication, RLS, backups and deployment have been tested.
- Export buttons create CSVs on the device. Set up a separate database backup plan in Supabase for recovery.
- This starter currently records homework/tests but does not yet implement per-student marks entry/report-card generation. Those can be added as a later feature.


## Online fee QR setup

1. Open **Settings → Online fee QR code** and upload a clear PNG, JPG or WebP image.
2. At fee collection, choose **Online / UPI** to show the QR; choosing Cash hides it.
3. Verify payment in your bank/UPI app before confirming. The app does not automatically verify UPI transactions.
4. Run the updated `supabase_schema.sql` in Supabase SQL Editor before using this version; it adds the profile QR field and permits cash/online methods.


## Install on an Android phone

1. Deploy this folder to an HTTPS static host (for example, Netlify). `localhost` works as a secure context on the computer itself, but a phone opening the computer's LAN IP over plain HTTP generally cannot install this PWA reliably.
2. Add the deployed HTTPS URL to Supabase Authentication's allowed redirect URLs.
3. Open the deployed site in Chrome on Android and sign in. If the **Install app** button appears, tap it. Otherwise open Chrome's ⋮ menu and choose **Install app** or **Add to Home screen** if offered.
4. The app needs internet access for Supabase login and records. The service worker caches the app shell, not the Supabase backend or data.

## QR payment behavior and limitations

- Upload the teacher's QR image under **Settings → Online fee QR code**. The image is compressed and stored in that teacher's `teacher_profiles.payment_qr_data` row.
- Choose **Online / UPI** while recording a fee. The app requires the teacher to tick the confirmation after checking the UPI/bank app.
- This is manual verification, not automatic payment-gateway verification. Never mark a payment received based only on a student's screenshot.
- Run the updated `supabase_schema.sql` or the supplied migration in Supabase before recording online payments.

## Troubleshooting Supabase network errors

If the browser console shows `ERR_NAME_NOT_RESOLVED` or `ERR_CONNECTION_RESET` for the project hostname, check that the project is active and the Project URL in `app.js` exactly matches **Supabase → Project Settings → API**. Test the URL from another network or disable VPN/proxy/DNS filtering if appropriate. Do not publish service-role keys.

## V11 Emerald refresh
- Updated the visual theme to Emerald Green with a light, clean workspace.
- Refined dashboard surfaces, primary actions, navigation states, and responsive card styling without removing existing pages.
- Added a six-month fee-collection trend on the dashboard, calculated from the payments already loaded for the signed-in teacher.
- Updated the PWA service-worker cache version so browsers can pick up the refreshed assets.
- Existing registration/login, 8-digit email OTP reset flow, students, attendance, fees/QR, classes, homework/tests, reports, and settings remain in the project.

Validation performed for this build: JavaScript syntax check, required-flow/source checks, responsive-style checks, RLS/schema presence checks, and ZIP integrity check. Live Supabase/Gmail flows still require testing with the owner's configured account and network.

- Added the three requested planning sections: design ideas, most useful teacher features, and selected Emerald Green / Light Mode design.


## V13 Colourful design + future-feature additions
- Preserved the Emerald Green primary theme and Light Mode, with colourful accent treatments for dashboard stats, collection trend and reminder tiles.
- Added an in-dashboard Smart Reminders panel for current pending-fee follow-ups and unfinished homework/tests. This is an in-app dashboard summary only; it does not send automatic notifications.
- Added a downloadable JSON backup for currently loaded students, payments, attendance, classes and homework/tests. This is an export backup, not an automatic cloud backup or restore tool; keep the file private.
- Updated PWA manifest theme/background colours and bumped the service-worker cache to v9 so clients can fetch the updated assets.
- Existing attendance calendar/register, monthly reports, CSV export, QR fee flow, student management, classes, homework/tests, OTP auth and multi-tenant Supabase design remain in place.
- Validation performed: JavaScript syntax check, static feature checks and ZIP integrity. Live Supabase/email OTP/payment behavior and real-device PWA installation were not end-to-end tested.
