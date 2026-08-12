# ClosetAI Privacy Policy

_Last updated: 2026-08-11_

This policy describes what data ClosetAI ("the App") collects, how it is used, and the choices available to you. It reflects the App's actual implementation and does not describe features that do not exist.

## 1. Account Information

When you register, ClosetAI collects your name, email address, and password. Passwords are never stored in plain text — they are hashed (bcrypt) before being saved. Optional profile fields include phone number, gender, height, weight, and preferred style, which you may provide to personalize recommendations.

Authentication uses short-lived access tokens and longer-lived refresh tokens. Tokens are stored on your device using secure, encrypted local storage and are never logged in plain text by the App or its backend.

## 2. Wardrobe and Clothing Images

Photos of your clothing that you upload are stored using Cloudinary, a third-party image hosting service, and referenced by the App's database. Clothing metadata you provide or that our AI detects (category, color, brand, size, season, occasion, laundry status) is stored in our database and associated with your account.

## 3. AI Processing

When you use AI clothing detection or AI outfit recommendation, the relevant image or wardrobe/context data is sent to our configured AI provider (Google Gemini and/or OpenAI, depending on configuration) to generate a response. This data is used only to produce the requested recommendation or detection result and is not used by ClosetAI to train models.

## 4. Data Storage

All account, wardrobe, outfit, calendar, laundry, trip, packing, analytics, subscription, and notification records are stored in MongoDB Atlas, a cloud database provider, using industry-standard access controls and encryption in transit.

## 5. Notifications and Reminders

ClosetAI can send local device notifications for laundry status, planned outfits, trip and packing reminders, subscription status, and smart AI-driven reminders. These are generated and scheduled based on your own data and preferences; you can manage or disable them from the App's notification settings, and the App requests platform notification permission before scheduling any alerts.

## 6. Subscription and Payment Information

If you purchase a premium subscription, payment is processed through Razorpay. ClosetAI's backend stores the resulting order ID, payment ID, transaction status, and subscription plan/period — it does not store your card, UPI, or bank details, which are handled entirely by Razorpay. Payment signatures are verified server-side before any subscription is activated.

## 7. Analytics

ClosetAI computes usage statistics (e.g. most/least worn clothing, wear frequency, laundry and category breakdowns) from your own wardrobe and wear-history data to display inside the App. This is derived entirely from data you already provided and is not shared with third-party advertising or analytics networks — the App does not integrate any third-party ad SDK or cross-app tracking.

## 8. Third Parties We Use

- **Cloudinary** — clothing image storage and delivery
- **MongoDB Atlas** — application database
- **Google Gemini / OpenAI** (as configured) — AI clothing detection and outfit recommendations
- **Razorpay** — subscription payment processing
- **A weather data provider** — to factor current conditions into outfit recommendations
- **An SMTP provider** — to deliver password-reset OTP emails

We do not sell your personal data, and we do not use Firebase or any Firebase-based analytics/crash reporting in this App.

## 9. Data Deletion and Your Rights

You may delete your account at any time from the App's profile settings, which permanently removes your account record and revokes your authentication tokens so no further sign-ins are possible. To request deletion of associated wardrobe, outfit, or history records beyond your account record, contact us using the details below. You may also contact us to request a copy of your data or ask questions about this policy.

## 10. Contact

For privacy questions or data requests, contact: support@closetai.app

## 11. Changes to This Policy

We may update this policy as the App's features change. Material changes will be reflected in the "Last updated" date above.
