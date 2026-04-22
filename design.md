# Estate Manager Mobile App - Design Plan

## Overview
A comprehensive open-source estate management platform for property owners to manage multiple estates, track tenant payments, manage complaints, and automate administrative workflows. The app follows Apple Human Interface Guidelines for a native iOS experience.

---

## Screen List

### Authentication & Onboarding
1. **Splash Screen** - App branding and initial load
2. **Login Screen** - Gmail OAuth login with phone verification option
3. **Verification Screen** - Email/SMS code verification
4. **Role Selection Screen** - Choose between Estate Owner or Tenant role

### Estate Owner Screens
5. **Dashboard (Owner)** - Overview of all estates, quick stats, recent activities
6. **Estates List** - Browse and manage linked estates
7. **Estate Detail** - Single estate overview with tabs (tenants, payments, complaints)
8. **Tenant Management** - List of tenants in an estate with actions
9. **Tenant Detail** - Individual tenant info, payment history, complaints
10. **Payment Tracking** - View all payments, filter by estate/tenant/status
11. **Payment Detail** - Single payment record with receipt
12. **Complaint Management** - List of all complaints with status
13. **Complaint Detail** - View complaint details, add notes, mark resolved
14. **Admin Settings** - Customize estate details, notification preferences
15. **Profile Screen** - Owner profile, account settings, logout

### Tenant Screens
16. **Dashboard (Tenant)** - Payment status, upcoming payments, complaints
17. **Payment History** - View all payments with receipts
18. **Make Payment** - Submit payment with amount, date, method
19. **Payment Receipt** - View/download payment receipt
20. **Complaints** - Submit and track complaints
21. **Complaint Form** - Create new complaint with description and attachments
22. **Complaint Detail** - View complaint status and admin responses
23. **Tenant Profile** - Personal info, contact details, settings

---

## Primary Content and Functionality

### Authentication Flow
- **Login Screen**: Gmail OAuth button + phone number input field
- **Verification**: Code input (email or SMS), resend button, timer
- **Role Selection**: Two large buttons (Estate Owner / Tenant)

### Estate Owner Dashboard
- **Header**: Welcome message with estate count badge
- **Quick Stats Cards**: Total tenants, pending payments, active complaints
- **Recent Activity Feed**: Latest payments, complaints, tenant additions
- **Floating Action Button**: Add new estate
- **Bottom Tab Navigation**: Dashboard, Estates, Payments, Complaints, Profile

### Estates Management
- **Estates List**: Card-based layout showing estate name, location, tenant count, status
- **Estate Detail Tabs**:
  - Overview: Basic info, address, total units, occupancy rate
  - Tenants: List of tenants with quick actions (view, message, remove)
  - Payments: Recent payments, outstanding amounts
  - Complaints: Active and resolved complaints

### Payment Tracking
- **Payment List**: Filterable by estate, tenant, status, date range
- **Payment Card**: Tenant name, amount, date, status (paid/pending/overdue)
- **Payment Detail**: Full details, receipt preview, download option
- **Auto-Receipt**: PDF receipt with estate details, tenant info, amount, date

### Complaint Management
- **Complaint List**: Status badges (open/in-progress/resolved), priority levels
- **Complaint Detail**: Description, attachments, timeline of updates, admin notes
- **Admin Response**: Add notes, change status, assign priority

### Tenant Dashboard
- **Payment Status**: Next payment due, amount, days remaining
- **Recent Payments**: Last 3 payments with status
- **Active Complaints**: Count and quick access
- **Quick Actions**: Make payment, file complaint

### Payment Submission (Tenant)
- **Payment Form**: Amount field, payment date, optional note
- **Confirmation**: Review before submitting
- **Receipt**: Immediate receipt generation and download

### Complaint Filing (Tenant)
- **Complaint Form**: Category dropdown, description textarea, photo upload
- **Submission**: Confirmation with reference number
- **Tracking**: Real-time status updates with admin responses

---

## Key User Flows

### Estate Owner - Add New Estate
1. Tap "+" button on dashboard
2. Enter estate details (name, address, units count)
3. Set up payment terms (due date, amount)
4. Save estate
5. System generates unique code for tenant invitations
6. Dashboard updates with new estate

### Estate Owner - Track Payment
1. Navigate to Payments tab
2. Filter by estate or tenant
3. Tap payment to view details
4. See payment status, amount, date
5. Download receipt if needed
6. Mark as confirmed/processed

### Estate Owner - Manage Complaint
1. Navigate to Complaints tab
2. View list of complaints with status
3. Tap complaint to view details
4. Add admin notes and response
5. Update status (open → in-progress → resolved)
6. Tenant receives notification of update

### Tenant - Make Payment
1. Open app, view dashboard
2. Tap "Make Payment" button
3. Enter payment amount and date
4. Confirm submission
5. Receive instant receipt
6. Owner receives notification
7. Payment appears in owner's tracking

### Tenant - File Complaint
1. Tap "File Complaint" button
2. Select complaint category
3. Write description and add photos
4. Submit complaint
5. Receive confirmation with reference number
6. Track status in complaints list
7. Receive notifications on updates

---

## Color Choices

| Element | Color | Usage |
|---------|-------|-------|
| **Primary** | `#0a7ea4` (Teal) | Buttons, highlights, active states |
| **Background** | `#ffffff` (White) / `#151718` (Dark) | Screen backgrounds |
| **Surface** | `#f5f5f5` (Light Gray) / `#1e2022` (Dark Gray) | Cards, elevated surfaces |
| **Foreground** | `#11181C` (Dark) / `#ECEDEE` (Light) | Primary text |
| **Muted** | `#687076` (Gray) / `#9BA1A6` (Light Gray) | Secondary text |
| **Success** | `#22C55E` (Green) | Payment confirmed, resolved status |
| **Warning** | `#F59E0B` (Amber) | Pending payments, in-progress |
| **Error** | `#EF4444` (Red) | Overdue payments, open complaints |
| **Border** | `#E5E7EB` (Light) / `#334155` (Dark) | Dividers, card borders |

### Brand Identity
- **Primary Accent**: Teal (#0a7ea4) - represents trust and property management
- **Success State**: Green (#22C55E) - payments confirmed, issues resolved
- **Alert State**: Red (#EF4444) - overdue payments, urgent complaints
- **Neutral**: Gray tones - secondary information, disabled states

---

## Layout Principles

### Mobile Portrait (9:16) & One-Handed Usage
- **Touch targets**: Minimum 44pt height for interactive elements
- **Bottom navigation**: Primary actions within thumb reach
- **Top content**: Secondary information at top, scrollable
- **Card-based layout**: Vertical scrolling, clear separation
- **Floating Action Buttons**: Bottom-right for primary actions
- **Modal sheets**: Bottom-up presentation for secondary flows

### Navigation Structure
- **Tab Bar**: 5 main sections (Dashboard, Estates, Payments, Complaints, Profile)
- **Nested Navigation**: Each tab has its own stack for detail screens
- **Back Navigation**: Standard iOS back button behavior
- **Deep Linking**: Support for direct access to specific payments/complaints

---

## Interaction Patterns

### Feedback & Haptics
- **Button Press**: Scale 0.97 + light haptic feedback
- **List Item Selection**: Opacity change + subtle haptic
- **Success Actions**: Success haptic + green confirmation
- **Error States**: Error haptic + red alert

### Loading States
- **Skeleton Loaders**: Show content placeholders while loading
- **Pull-to-Refresh**: Refresh payment/complaint lists
- **Infinite Scroll**: Load more items in long lists

### Forms & Input
- **Text Fields**: Clear labels, placeholder text, validation feedback
- **Date Pickers**: Native iOS date picker for payment dates
- **File Upload**: Camera or photo library for complaint attachments
- **Keyboard Handling**: Proper scrolling when keyboard appears

---

## Accessibility
- **Color Contrast**: WCAG AA compliant (4.5:1 for text)
- **Text Sizing**: Support system font scaling
- **VoiceOver**: Proper labels and hints for all interactive elements
- **Dark Mode**: Full support with theme-aware colors
