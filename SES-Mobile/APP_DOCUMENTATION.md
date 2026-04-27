# VeilNote — Smart Emergency Safety App
### Complete Product Documentation

---

## 1. WHAT IS VEILNOTE?

VeilNote is a personal safety application designed for people who may find themselves in dangerous or threatening situations. Unlike conventional SOS apps that require you to visibly pull out your phone and press a button, VeilNote is built around **discretion** — the ability to call for help silently, without alerting the person posing the threat.

The app combines:
- Silent emergency alerting
- Background audio recording as evidence
- A disguised interface (looks like a normal Notes app)
- Keyword-based covert triggering
- Telegram-powered real-time alerts to trusted contacts

---

## 2. WHO IS IT FOR?

VeilNote is built for anyone who may face situations where they cannot openly ask for help:

| Person | Situation |
|--------|-----------|
| Women traveling alone | Unsafe cab ride, street harassment |
| Domestic abuse survivors | Cannot openly call for help at home |
| Students / Young adults | Unsafe social situations, parties |
| Workers in risky jobs | Night shifts, cash handling |
| Elderly individuals | Medical emergencies, home break-ins |
| Anyone in distress | Kidnapping, robbery, assault in progress |

---

## 3. CORE FEATURES OVERVIEW

### 3.1 Emergency Alert System
When triggered (by any method), the app:
1. Captures your **live GPS location**
2. Sends an **emergency alert** to all your saved contacts
3. Notifies via **Telegram** (if set up) or **SMS fallback**
4. Records the **event in history** for later review

### 3.2 Multiple Trigger Methods
Four ways to silently call for help:

| Trigger | How | When to Use |
|---------|-----|-------------|
| SOS Button | Tap the big button on Home screen | Quick, visible press when alone |
| Volume Button | Press volume down 3 times fast | Phone in pocket, can't look at screen |
| Alert Keyword | Type a secret word in Notes | Phone in hand, threat watching you |
| Manual keyword trigger | Type the configured alert word | Discreet text-based trigger |

### 3.3 Stealth Mode (Notes Disguise)
The app can disguise itself as a plain Notes application. When enabled:
- Opening the app shows a blank notes screen
- No visible buttons, branding, or emergency UI
- All actions happen invisibly through secret keywords

### 3.4 Evidence Collection
- Records ambient audio before/during an emergency
- Stores recordings in a protected Evidence vault
- Audio analysed by backend AI for threat detection
- Evidence files retained for legal use

### 3.5 Telegram Integration
Sends real-time alerts with location directly to contacts via Telegram — faster and more reliable than SMS.

---

## 4. HOW TO SET UP THE APP

### Step 1 — Register & Login
- Create an account with your name, email, phone number
- Login to access the app

### Step 2 — Grant Permissions (Policy Screen)
The app requires three permissions to function correctly:
- **Location** — to send your GPS position during emergencies
- **Microphone** — to record audio evidence
- **Background Activity** — to detect volume button triggers even when screen is off

### Step 3 — Add Emergency Contacts
Go to Home → "Add Guardian"
- Enter contact's name, phone number, relationship
- Optionally add their **Telegram Chat ID** for direct Telegram alerts
- Set a priority (1–10) — higher priority contacts are notified first

### Step 4 — Set Up Telegram (Recommended)
See Section 6 for full Telegram setup guide.

### Step 5 — Configure Stealth Mode (Optional but Powerful)
Go to Home → Stealth Mode card
- Enable "Stealth Protection"
- Set a secret **Unlock Phrase** (e.g., `opensesame`) — this exits the disguise
- Set keywords:
  - **Alert Keyword** — silently triggers emergency (e.g., `helpme`)
  - **Record Start Keyword** — starts background audio recording (e.g., `recstart`)
  - **Record Stop Keyword** — stops recording and saves evidence (e.g., `recstop`)

### Step 6 — Choose Mode
On the Home screen, toggle between:
- **Active Protection** — real alerts sent to contacts
- **Practice Mode** — everything works but no real alerts (use to learn the app)

---

## 5. HOW EACH TRIGGER WORKS

### 5.1 SOS Button (Manual)
- **Where:** Large circular button on the Home screen
- **What happens:** Immediately grabs GPS and sends alert to all contacts
- **Best for:** Situations where you have a moment to openly use your phone

### 5.2 Volume Button Trigger (Protect Mode)
- **How:** Press the **volume down** button **3 times** within 3 seconds
- **What happens:**
  1. App records 10 seconds of ambient audio
  2. Grabs GPS location simultaneously
  3. Uploads audio to backend for AI threat detection
  4. If threat words or distress sounds are detected → Alert sent
  5. Two short vibrations confirm trigger activated
- **Best for:** Phone is in your pocket or bag, you cannot look at the screen
- **Note:** 400ms gap required between each press to avoid accidental triggers from holding the button

### 5.3 Stealth Keyword Triggers (Inside Notes Screen)
Once the phone is open and the Notes disguise is active:

**Alert Keyword** — type your configured keyword anywhere in the notes
- App silently sends emergency alert with your GPS
- Keyword is removed from the text automatically
- A very short vibration confirms it (imperceptible to bystanders)

**Record Start Keyword** — type your configured start keyword
- Background audio recording begins silently
- No recording indicator, no sound
- Recording continues for up to 10 minutes or until stop keyword

**Record Stop Keyword** — type your configured stop keyword
- Recording stops and saves
- File stored in Evidence vault
- Queued for upload to backend

### 5.4 Unlock Phrase (Exit Disguise)
- Type your secret phrase at the end of text in the Notes screen
- App instantly exits stealth mode and shows real home screen
- Phrase is cleared from the notes automatically

---

## 6. TELEGRAM INTEGRATION — COMPLETE GUIDE

### Why Telegram?
Telegram provides a **fast, encrypted, reliable** message channel directly to your emergency contacts. Unlike SMS:
- Delivered instantly (no carrier delays)
- Works over internet / WiFi
- Contains live GPS link, not just text
- Free internationally
- Cannot be blocked by call screening

---

### 6.1 Setting Up Your Own Telegram (User Setup)

**You need to do this once so the bot knows who YOU are.**

1. Open the app → Go to **Settings** tab
2. Scroll to the **Telegram** section
3. Tap **"Open Bot"** — this opens Telegram with the bot `@ABSES2711MYBot`
4. In Telegram, send the message: `/start`
5. The bot will reply with a message containing your **Chat ID** (a number)
6. Come back to the app → Tap **"Verify"**
7. The app fetches your Chat ID from the bot and saves it
8. The status indicator turns **green** — you're connected

> If "Verify" doesn't work, make sure you actually sent `/start` to the bot in Telegram and wait a few seconds before tapping Verify.

---

### 6.2 Setting Up Telegram for Your Emergency Contacts

**Each contact who wants to receive Telegram alerts must do the following:**

1. Open Telegram on their phone
2. Search for `@ABSES2711MYBot`
3. Open the bot and send: `/start`
4. The bot replies with their **unique Chat ID**
5. They share this Chat ID number with you
6. You enter it when adding them as a contact in the app (or edit existing contact)

Once set up, when you trigger an emergency:
- They receive a Telegram message instantly
- Message includes: alert text, your name, GPS coordinates, timestamp

> Contacts **without** a Telegram Chat ID will receive an SMS instead (fallback).

---

### 6.3 What Telegram Alert Looks Like for Contacts
When an emergency is triggered, your contact receives a Telegram message:

```
🚨 EMERGENCY ALERT

[Your Name] has triggered an emergency alert.

📍 Location: [Latitude], [Longitude]
🕐 Time: [Timestamp]
⚠️ Trigger: Manual / Volume / Keyword

Stay alert and contact them immediately.
```

---

### 6.4 Telegram Troubleshooting

| Problem | Solution |
|---------|----------|
| "Verify" button does nothing | Open Telegram, send /start to bot again, then retry |
| Status still shows "SMS Only" | Check internet connection and retry Verify |
| Contact not getting Telegram alerts | Make sure their Chat ID is entered correctly in the app |
| Bot doesn't respond | Check if Telegram is installed and you have internet |

---

## 7. EVIDENCE VAULT

### 7.1 What Is It?
A password-protected section of the app that stores all recorded audio evidence. Only accessible by entering your Evidence Phrase.

### 7.2 How Evidence Gets Stored
Evidence recordings are collected in three ways:

1. **Manual Recording** — Go to Home → Evidence → Start recording manually
2. **Stealth Recording** — Type the Record Start keyword in Notes → audio records silently → type Record Stop keyword → saved to vault
3. **Protect Mode (Volume Button)** — 10-second recording automatically captured with every volume button trigger

### 7.3 Accessing Evidence
- Home → Evidence card
- Enter your Evidence Phrase
- See all recordings listed by date (newest first)
- Play any recording to review
- Delete recordings you no longer need

### 7.4 Setting Up Evidence Access
First time:
- App asks you to create a new Evidence Phrase
- This is separate from the Stealth Unlock Phrase

Subsequent access:
- Enter your phrase to unlock and view recordings

> Evidence recordings are stored in **AAC audio format** (M4A), compatible with all common audio players.

---

## 8. PRACTICE MODE

### 8.1 What Is It?
A safe simulation mode where all triggers work normally but **no real alerts are sent** and no contacts are notified.

### 8.2 How to Enable
Home screen → Toggle "Active Protection" to **"Practice Mode"**

### 8.3 What You Can Practice
- Pressing volume button 3 times
- Typing keywords in stealth mode
- Pressing the SOS button
- Entering / exiting the Notes disguise

### 8.4 Practice Mode Screen
Dedicated screen with:
- Step-by-step visual guide of the volume button trigger
- Interactive simulator to test the 3-press sequence
- See what happens at each stage (listening, analyzing, result)

> Always test new keyword configurations in Practice Mode first before switching to Active Protection.

---

## 9. REAL-WORLD USE CASES

### Case 1: Unsafe Cab / Ride-Share
> You're in a cab late at night and the driver starts behaving strangely. You can't call someone openly.

**What to do:**
- Open your phone, pretend to type a note
- Type your **Alert Keyword** → Emergency alert sent silently
- Type your **Record Start Keyword** → Audio recording begins
- Your contacts get your GPS location immediately via Telegram
- Audio of the cab conversation is saved as evidence

---

### Case 2: Domestic Situation
> You're at home and cannot safely make a call or visibly use the app.

**What to do:**
- App is open as Notes (stealth active, looks like normal notepad)
- Type your alert keyword quietly
- Alert sent to trusted contacts with your home GPS location
- Contacts can call police or come to your location

---

### Case 3: Street Robbery / Assault in Progress
> Someone grabs your bag. Your phone is in your pocket.

**What to do:**
- Before any confrontation: **Press volume down 3 times** while phone is in pocket
- 10-second recording captures the incident audio
- If threat is detected → Alert sent automatically to all contacts
- No need to look at your phone at all

---

### Case 4: Feeling Watched / Followed
> You're walking home and feel you're being followed. Not yet a threat but you want contacts on alert.

**What to do:**
- Open phone, appears to be typing
- Open the Notes (Stealth) screen
- Type **Record Start Keyword** → silent recording begins
- Type **Alert Keyword** → contacts notified, GPS shared
- Evidence recording running in background

---

### Case 5: Medical Emergency (Alone)
> You feel unwell, dizzy, or are having a health episode and cannot speak clearly.

**What to do:**
- Press volume down 3 times or tap SOS button
- Contacts alerted with exact GPS location
- They can dispatch help or emergency services to your exact location

---

### Case 6: Campus / Workplace Threat
> There is a threatening person on campus or at your workplace and you cannot call out loud.

**What to do:**
- Type keyword silently
- All contacts notified simultaneously
- Audio recording captures the situation for evidence

---

### Case 7: Child / Teen Safety
> A teenager uses the app in case they feel unsafe at a party or event.

**What to do:**
- App disguised as Notes — no one knows it's a safety app
- Parents added as emergency contacts with Telegram set up
- Any suspicious situation → Type keyword → Parents alerted immediately with location

---

## 10. WHY TRIGGERS DON'T WORK WHEN THE APP IS FULLY CLOSED

### The Technical Reality

This is one of the most important limitations to understand, and it has a real, fundamental technical reason — not a bug or oversight.

---

### 10.1 Volume Button Trigger (Protect Mode)

**Why it stops working when the app is fully killed:**

The volume button trigger relies on a **platform channel** — a direct native bridge between Flutter and the Android system. This bridge uses an `EventChannel` registered as `ses.volume_button`.

When the app is **running in the background** (minimized, screen off), this channel remains active and the app listens for volume events.

When the app is **fully killed** (swiped away from recent apps), the Dart VM is destroyed. The `EventChannel` listener is unregistered. There is no process alive to receive or act on the hardware button event.

**Why Android won't let us fix this easily:**

Android (especially Android 8+) introduced **Doze Mode** and **Background Execution Limits** specifically to prevent apps from running unlimited background code. These are battery and privacy protections built into the OS. Apps cannot:
- Register system-wide hardware button listeners from a killed state
- Start Dart/Flutter processes when the phone receives a button event
- Keep a persistent EventChannel alive when the app is fully closed

To truly work when closed, the app would need a persistent **Foreground Service** (which shows a permanent notification — like how a music player shows a notification while playing). This is possible but would require the user to always keep that notification running, which many users disable.

**In short:** The volume trigger requires the app's Dart process to be alive. A killed app has no process. Android does not allow arbitrary app resurrection from hardware button events.

---

### 10.2 Keyword Trigger (Stealth Notes)

**Why it requires the app to be open:**

The keyword detection happens inside `StealthNotesScreen` — a Flutter widget that monitors the text input field in real-time. When you type, each character change fires a listener, which checks for keyword patterns.

This is **entirely UI-driven**. There is no background service intercepting keystrokes system-wide.

Even if we tried to run a background keyword watcher:
- Android does not allow apps to read input from other apps' text fields
- System-wide keylogger access is blocked for security reasons
- Background services that do heavy processing are killed by Android's battery optimizer

**Why this is actually a security feature, not just a limitation:**
If any app could listen to all keystrokes in the background, that would be spyware. Android correctly prevents this. VeilNote's keyword detection only works when you have opened the app yourself.

---

### 10.3 What DOES Work When App Is Closed?

| Feature | App Minimized | App Killed |
|---------|:---:|:---:|
| Volume Button Trigger | ✅ Works | ❌ Does not work |
| Keyword Trigger | ❌ App must be open | ❌ Does not work |
| SOS Button | ❌ App must be visible | ❌ Does not work |
| Telegram Alerts (receive) | ✅ Via Telegram app | ✅ Via Telegram app |
| Evidence upload retry | ✅ On next open | ✅ On next open |

---

### 10.4 Best Practice for Maximum Protection

To ensure the volume button trigger always works:
1. **Never fully close the app** — minimize it instead (press Home, not swipe away)
2. Keep the app running in the background at all times when you're in an uncertain situation
3. On Android, go to **Battery Settings → VeilNote → Don't optimize** to prevent the system from killing it
4. Some phones (Xiaomi, Samsung, OnePlus) have aggressive background kill policies — check manufacturer-specific battery settings and whitelist the app

---

## 11. SETTINGS REFERENCE

### Telegram Section
| Setting | What It Does |
|---------|-------------|
| Status Indicator | Shows if Telegram is connected (green) or SMS only |
| Open Bot | Opens Telegram with @ABSES2711MYBot |
| Verify | Fetches your chat ID from bot and saves it |

### Stealth Keywords Section
| Setting | What It Does |
|---------|-------------|
| Alert Keyword | Word that silently triggers emergency when typed in Notes |
| Record Start Keyword | Word that starts background audio recording |
| Record Stop Keyword | Word that stops recording and saves to Evidence |

> Keywords must all be different from each other and from your Unlock Phrase.

---

## 12. PRIVACY & SECURITY

- All sensitive data (phrases, keywords, tokens) stored in **encrypted secure storage** on your device
- Audio recordings stored locally and only uploaded when needed for threat analysis
- Evidence vault requires a separate phrase — even if someone accesses the main app, they cannot view recordings
- Stealth mode shows a plain notes interface — no visible indication you are using a safety app
- Backend communication uses JWT token authentication
- Telegram messages are end-to-end encrypted

---

## 13. QUICK REFERENCE CARD

```
EMERGENCY SITUATIONS — WHAT TO DO:

Phone in pocket, threat nearby:
→ Volume Down × 3 (within 3 seconds)

Phone in hand, pretending to type:
→ Open Notes (stealth) → Type Alert Keyword

Can use phone openly:
→ Tap SOS button on Home screen

Want to record secretly:
→ Type Record Start Keyword → [record] → Type Record Stop Keyword

Need to open real app from Notes:
→ Type your Unlock Phrase at end of text

SETUP CHECKLIST:
□ Emergency contacts added (with phone numbers)
□ Telegram connected (Settings → Telegram → Verify)
□ Contacts have set up Telegram with the bot
□ Stealth mode enabled with keywords configured
□ Tested everything in Practice Mode
□ Battery optimization disabled for VeilNote
□ App running in background (minimized, not killed)
```

---

*VeilNote — Safety that works silently, when it matters most.*
