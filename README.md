# 🎓 G'echo - University Social Platform

A comprehensive Flutter-based social platform designed specifically for university students and clubs, featuring secure authentication, content sharing, interactive engagement, and administrative controls with Firebase backend.

## 🌟 Features

### 📱 **Mobile App (Students & Clubs)**
- 🔐 **Secure Authentication** - University-controlled login system with admin approval
- 📸 **Photo Sharing** - Upload and share photos with captions and tags using Cloudinary
- ✍️ **Blog Posts** - Write and publish text-only blog posts with rich content
- 🏠 **Feed** - Instagram-style seamless feed with full-width posts
- 🔍 **Explore** - Discover content in an optimized grid layout with blog previews
- 👤 **Profile** - User profiles with role-based tabs (Photos | Blogs | Analytics)
- ❤️ **Interactive Engagement** - Like posts with animated heart button
- 💬 **Real-time Comments** - Comment on posts with live updates and role badges
- 🎯 **Interactive Post Details** - Full-screen bottom sheet with swipe-to-close
- 🏷️ **Tags** - Organize content with hashtags and categories
- 🎯 **Domain Validation** - Students must use @gla.ac.in emails
- 🔔 **Admin Priority Posts** - Admins can pin important announcements

### 🌐 **Admin Panel**
- 👨‍💼 **Registration Management** - Three-tab system (Active | Rejected | Expired)
- ✅ **User Approval System** - Review pending registrations with detailed information
- 🔍 **Universal Search** - Search across all registration tabs by name or email
- 📋 **Request Monitoring** - Track registration requests with expiry management
- 🗑️ **Bulk Operations** - Delete all rejected or expired requests
- 👥 **User Management** - Monitor and restrict users across different roles
- 🚫 **User Restrictions** - Temporarily restrict users with custom duration and reason
- 📊 **Analytics Dashboard** - View comprehensive statistics:
  - User counts by role (Students, Clubs, Admins, Total)
  - Post counts by role (Club Posts, Admin Posts, Total)
  - Real-time data with pull-to-refresh
- 🔍 **User Management Tab** - Search and manage all users with restriction controls

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point with Firebase initialization
├── firebase_options.dart        # Firebase configuration
├── models/
│   ├── user_model.dart         # University user data model with restrictions
│   ├── post_model.dart         # Post data model with priority support
│   └── comment_model.dart      # Comment data model with role badges
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart   # Multi-role authentication with restriction check
│   │   └── registration_screen.dart # User registration requests
│   ├── admin/
│   │   └── approval_requests_screen.dart # Three-tab approval system
│   ├── home/
│   │   └── home_screen.dart    # Main navigation hub
│   ├── feed/
│   │   └── feed_screen.dart    # Instagram-style seamless feed
│   ├── explore/
│   │   └── explore_screen.dart # Grid content discovery with blog previews
│   ├── create/
│   │   └── create_post_screen.dart # Post creation (photo/blog)
│   └── profile/
│       ├── profile_screen.dart # User profiles with role-based tabs
│       ├── analytics_tab.dart  # Admin analytics dashboard
│       └── user_management_tab.dart # User management interface
├── services/
│   ├── auth_service.dart       # Authentication & role management
│   ├── registration_service.dart # Registration workflow with status
│   ├── post_service.dart       # Post management with Cloudinary
│   ├── comment_service.dart    # Comment management with permissions
│   ├── admin_service.dart      # Admin operations and statistics
│   └── image_service.dart      # Cloudinary image handling
└── widgets/
    ├── post_card.dart          # Instagram-style post display
    ├── post_grid_item.dart     # Grid layout with blog preview
    ├── post_detail_bottom_sheet.dart # Interactive post detail view
    └── comments_bottom_sheet.dart # Comment section widget

firebase.json                   # Firebase project configuration
firestore.rules                 # Database security rules
storage.rules                   # Storage security rules
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.7+) - **Updated for compatibility**
- Dart SDK (3.7.0+)
- Firebase project with:
  - Firestore Database
  - Firebase Storage
  - Firebase Authentication
  - Firebase Hosting (optional)
- Cloudinary account for image storage
- Node.js & Firebase CLI (for deployment)

### 📱 Mobile App Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/RohanP-57/gecho.git
   cd gecho
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add your `google-services.json` to `android/app/`
   - Update `lib/firebase_options.dart` with your config
   - Deploy Firestore security rules:
     ```bash
     firebase login
     firebase use your-project-id
     firebase deploy --only firestore:rules
     ```

4. **Configure Environment Variables**
   Create a `.env` file in the project root:
   ```env
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_API_KEY=your_api_key
   CLOUDINARY_API_SECRET=your_api_secret
   ```

5. **Run the mobile app**
   ```bash
   flutter run lib/main.dart
   ```

### 🔧 Troubleshooting

#### Common Issues & Solutions

**1. "Entrypoint isn't within the current project"**
- Ensure you're running from the project root directory
- Use relative path: `flutter run lib/main.dart`
- In IDE configuration, set Dart entrypoint to `lib/main.dart` (not absolute path)

**2. Firestore Index Errors**
- ✅ **Fixed**: Removed `orderBy` clauses that required indexes
- Client-side sorting implemented for better performance
- No manual index creation needed

**3. Permission Denied Errors**
- ✅ **Fixed**: Updated Firestore security rules
- All authenticated users can now create posts
- Proper role-based access control implemented

**4. Flutter Version Compatibility**
- ✅ **Fixed**: Updated `pubspec.yaml` to use Dart SDK ^3.7.0
- Compatible with Flutter 3.29.2 and above

**5. Icon Rendering Issues**
- Run `flutter clean` and `flutter pub get`
- Restart the app completely
- Material Design icons are properly configured

### 📱 Mobile App Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd university-portal
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add your `google-services.json` to `android/app/`
   - Add your `GoogleService-Info.plist` to `ios/Runner/`
   - Update `lib/firebase_options.dart` with your config

4. **Configure Google Sign-In**
   - Enable Google Sign-In in Firebase Console
   - Add your SHA-1 fingerprint for Android
   - Configure OAuth consent screen in Google Cloud Console

5. **Run the mobile app**
   ```bash
   flutter run
   ```

### 🌐 Web Admin Panel Setup

1. **Install Firebase CLI**
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**
   ```bash
   firebase login
   ```

3. **Initialize Firebase Hosting**
   ```bash
   firebase init hosting
   ```

4. **Configure Google Sign-In for Web**
   - Add your domain to authorized domains in Firebase Console
   - Update web OAuth client ID in Google Cloud Console

5. **Deploy Admin Panel**
   ```bash
   chmod +x deploy_admin.sh
   ./deploy_admin.sh
   ```

### 🔧 Environment Configuration

Create a `.env` file (optional) for environment-specific settings:
```env
FIREBASE_PROJECT_ID=your-project-id
ADMIN_EMAIL_DOMAIN=@gla.ac.in
STUDENT_EMAIL_DOMAIN=@gla.ac.in
```

## 🔥 Firebase Setup

### 📊 Firestore Collections

The app uses role-based collections for better security:

- **admin_users** - Administrator accounts
- **student_users** - Student profiles and data  
- **club_users** - Club profiles and data
- **registration_requests** - Pending access requests with expiry
- **posts** - Global posts collection (photos and blogs)

### � Security Rules

Updated Firestore security rules provide:
- **Role-based access control** - Different permissions for admin/student/club users
- **Authentication requirements** - All operations require valid authentication
- **Registration workflow** - Secure approval process for new users
- **Content permissions** - Proper read/write access for posts and comments

### 📁 Storage Structure

- **Cloudinary Integration** - All images stored in Cloudinary for optimization
- **Automatic image processing** - Resizing and format optimization
- **CDN delivery** - Fast global image delivery
- **Secure uploads** - Authenticated upload process

## 🆕 Recent Updates & Fixes

### ✅ **Version 3.0 - Interactive Engagement & Enhanced UI**

**🎨 UI/UX Improvements:**
- **Instagram-Style Feed**: Seamless full-width posts with no card borders
- **Interactive Post Details**: Full-screen bottom sheet with swipe-to-close gesture
- **Animated Like Button**: Heart animation with red fill when liked
- **Blog Content Preview**: First 3 lines of blog content visible in explore grid
- **Role-Based Tabs**: Profile tabs based on user role (Photos | Blogs | Analytics)
- **Expandable Text**: Inline "Read more/Show less" for long captions

**💬 Comment System:**
- **Real-time Comments**: Live comment updates with StreamBuilder
- **Role Badges**: Visual badges for Student 🎓, Club 🏛️, Admin 👨‍💼
- **Comment Ownership**: Users can delete their own comments
- **Admin Moderation**: Admins can delete any comment
- **Comment Input**: Fixed bottom input field with send button

**👥 User Management:**
- **User Restrictions**: Admins can temporarily restrict users
- **Restriction Reasons**: Custom reason and duration for restrictions
- **Login Restriction Check**: Shows dialog with reason and duration on login
- **User Management Tab**: Search and manage all users with restriction controls

**📊 Analytics Dashboard:**
- **User Statistics**: Students, Clubs, Admins, Total Users count
- **Post Statistics**: Club Posts, Admin Posts, Total Posts (students excluded)
- **Pull-to-Refresh**: Real-time data updates
- **Color-Coded Cards**: Visual distinction for different metrics

**🔧 Registration System:**
- **Three-Tab System**: Active (Green), Rejected (Orange), Expired (Red)
- **Universal Search**: Search across all tabs by name or email
- **Bulk Delete**: Delete all rejected or expired requests
- **Rejection Metadata**: Shows who rejected, when, and why
- **Status Tracking**: Single collection with status field

### ✅ **Version 2.0 - Major Stability Update**

**🔧 Critical Fixes:**
- **Firestore Index Issues**: Removed complex queries requiring manual indexes
- **Permission Errors**: Updated security rules for proper access control
- **Flutter Compatibility**: Fixed Dart SDK version compatibility (3.8.1 → 3.7.0)
- **Icon Rendering**: Resolved Material Design icon display issues
- **Entrypoint Configuration**: Fixed IDE configuration for proper app launching

**🚀 Performance Improvements:**
- **Client-side Sorting**: Moved data sorting from Firestore to client for better performance
- **Optimized Queries**: Simplified Firestore queries to avoid index requirements
- **Image Optimization**: Enhanced Cloudinary integration for faster loading
- **Memory Management**: Improved app performance and stability

**🔐 Security Enhancements:**
- **Updated Firestore Rules**: More permissive rules for authenticated users
- **Role-based Collections**: Separate collections for different user types
- **Secure File Handling**: Added sensitive files to .gitignore
- **Authentication Flow**: Improved user authentication and role management

**📱 User Experience:**
- **Priority Posts**: Admins can pin important announcements
- **Registration Workflow**: Streamlined approval process with expiry management
- **Error Handling**: Better error messages and user feedback
- **UI Improvements**: Enhanced interface for better usability


## 🎯 Features in Detail

### 🔐 Authentication & Access Control
- **Google Sign-In Integration** - Seamless authentication with university accounts
- **Domain Validation** - Students must use @gla.ac.in email addresses
- **Club Flexibility** - Clubs can use any university email domain
- **Admin Approval System** - All users must be pre-approved by university administration
- **Registration Requests** - Students and clubs can request access through the app

### 📸 Photo Posts
- Upload images from gallery with university content guidelines
- Add captions and tags relevant to university life
- Automatic image optimization for mobile and web
- Grid and feed display optimized for student engagement

### ✍️ Blog Posts
- Rich text content for academic and club announcements
- Optional cover images for enhanced visual appeal
- Tag support for categorizing university content
- Full-screen reading view optimized for mobile devices

### 👤 User Profiles
- **Student Profiles** - Display student ID, department, and year (no posting)
- **Club Profiles** - Show club name, type with Photos and Blogs tabs
- **Admin Profiles** - Full access with Photos, Blogs, and Analytics tabs
- **Profile Grid** - Posts displayed in grid layout with click-to-view
- **Post Statistics** - Dynamic post count by type
- **Interactive Details** - Click posts to open full-screen bottom sheet

### ❤️ Interactions
- **Like System**: Animated heart button with red fill when liked
- **Real-time Comments**: Live comment updates with role badges
- **Comment Ownership**: Users can delete their own comments
- **Admin Moderation**: Admins can delete any comment
- **Interactive Post Details**: Full-screen bottom sheet with swipe-to-close
- **Tag System**: Organize university content with hashtags

### 🌐 Web Admin Panel
- **Registration Management** - Three-tab system (Active | Rejected | Expired)
- **Universal Search** - Search across all tabs by name or email
- **Bulk Operations** - Delete all rejected or expired requests
- **User Management** - Search and restrict users with custom duration
- **Analytics Dashboard** - Comprehensive statistics with pull-to-refresh
- **Content Moderation** - Monitor posts and comments for university guidelines

## 📦 Dependencies

### Core Dependencies
- `firebase_core: ^3.15.2` - Firebase initialization
- `firebase_auth: ^5.7.0` - Authentication system
- `cloud_firestore: ^5.6.12` - Firestore database
- `firebase_storage: ^12.4.10` - File storage

### Image & Media
- `image_picker: ^1.2.0` - Image selection from gallery/camera
- `cached_network_image: ^3.4.1` - Optimized image caching
- `cloudinary_public: ^0.21.0` - Cloudinary integration for image storage

### UI & Navigation
- `cupertino_icons: ^1.0.8` - iOS-style icons
- Material Design Icons - Built-in Flutter icons

### Utilities
- `intl: ^0.19.0` - Date formatting and internationalization
- `uuid: ^4.5.1` - Unique ID generation
- `http: ^1.5.0` - HTTP requests
- `crypto: ^3.0.7` - Cryptographic functions
- `flutter_dotenv: ^5.2.1` - Environment variables

### Development
- `flutter_lints: ^5.0.0` - Code analysis and linting
- `flutter_test` - Testing framework

## 🛠️ Development

### Development Environment
- **Flutter Version**: 3.29.2 (Channel stable)
- **Dart Version**: 3.7.0+
- **Target Platforms**: Android, iOS
- **IDE Support**: VS Code, Android Studio, IntelliJ IDEA

### Adding New Features

1. **Models** - Create data models in `lib/models/` following existing patterns
2. **Services** - Add business logic in `lib/services/` with proper error handling
3. **Screens** - Build UI screens in `lib/screens/` with responsive design
4. **Widgets** - Create reusable components in `lib/widgets/`
5. **Security** - Ensure new features respect role-based access control

### 🧪 Testing & Quality Assurance

```bash
# Run all tests
flutter test

# Analyze code quality
flutter analyze

# Check for linting issues
flutter pub run flutter_lints

# Performance profiling
flutter run --profile
```

### 🔧 Development Workflow

1. **Local Development**
   ```bash
   flutter run --debug
   flutter hot-reload  # r key during development
   flutter hot-restart # R key during development
   ```

2. **Firebase Emulator (Optional)**
   ```bash
   firebase emulators:start --only firestore,auth,storage
   ```

3. **Code Quality Checks**
   ```bash
   flutter clean
   flutter pub get
   flutter analyze
   flutter test
   ```

## 🚀 Deployment

### 📱 Mobile App Deployment

1. **Android Release**
   ```bash
   flutter build apk --release
   flutter build appbundle --release
   ```

2. **iOS Release**
   ```bash
   flutter build ios --release
   ```

### 🔥 Firebase Deployment

1. **Deploy Firestore Rules**
   ```bash
   firebase login
   firebase use your-project-id
   firebase deploy --only firestore:rules
   ```

2. **Deploy Storage Rules**
   ```bash
   firebase deploy --only storage
   ```

3. **Full Firebase Deployment**
   ```bash
   firebase deploy
   ```

## 🔧 Configuration Files

### Important Configuration Files
- `pubspec.yaml` - Flutter dependencies and project configuration
- `firebase.json` - Firebase project configuration
- `firestore.rules` - Database security rules (excluded from git)
- `storage.rules` - Storage security rules (excluded from git)
- `.env` - Environment variables (excluded from git)
- `serviceAccountKey.json` - Firebase service account (excluded from git)

### Security & Privacy
The following files are excluded from version control for security:
- `serviceAccountKey.json`
- `firestore.rules`
- `firestore.indexes.json`
- `storage.rules`
- `.env` files
- `google-services.json`
- `GoogleService-Info.plist`

## 🎯 University-Specific Features

### Authentication System
- **Multi-role Support**: Admin, Student, Club user types
- **Domain Validation**: Students must use @gla.ac.in emails
- **Approval Workflow**: All users require admin approval
- **Registration Requests**: Self-service registration with admin review

### Content Management
- **Priority Posts**: Admins can pin important announcements for 2 days
- **Role-based Posting**: Different permissions for different user types
- **Content Moderation**: Admin oversight of user-generated content
- **Tag System**: Organize content by categories and topics

### Administrative Features
- **Registration Management**: Three-tab system with universal search
- **User Restrictions**: Temporarily restrict users with custom duration and reason
- **Analytics Dashboard**: Comprehensive statistics (users, posts, engagement)
- **User Management Tab**: Search and manage all users with restriction controls
- **Content Oversight**: Monitor posts and user interactions
- **Bulk Operations**: Delete all rejected or expired requests efficiently

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow Flutter/Dart coding standards
4. Test with university email domains
5. Ensure Firebase rules compatibility
6. Submit a pull request with detailed description

### Code Standards
- Follow Flutter/Dart conventions and linting rules
- Maintain role-based access control
- Test on both Android and iOS platforms
- Ensure Firestore security rule compliance
- Document new features and API changes

### Recent Contributions
- Fixed Firestore index and permission errors
- Updated Flutter/Dart compatibility
- Enhanced security rules and access control
- Improved error handling and user experience
- Added comprehensive documentation

## 📄 License

This project is developed for educational purposes and university use.

## 🆘 Support & Troubleshooting

### For Students & Clubs
- Submit registration requests through the app
- Contact university IT support for account issues
- Check with student services for approval status

### For Developers
- Check the troubleshooting section above for common issues
- Create issues in the GitHub repository
- Follow the contribution guidelines
- Test with university email domains

### For Administrators
- Use the admin panel for user management
- Contact IT support for deployment assistance
- Review security rules before making changes

### Common Issues & Solutions

1. **App won't start**: Check Flutter/Dart version compatibility
2. **Login issues**: Verify Firebase authentication configuration
3. **Permission errors**: Ensure Firestore rules are deployed
4. **Image upload fails**: Check Cloudinary configuration
5. **Build errors**: Run `flutter clean` and `flutter pub get`

### Getting Help
- 📧 **Email**: Contact university IT support
- 🐛 **Bug Reports**: Create GitHub issues
- 💡 **Feature Requests**: Submit through GitHub discussions
- 📚 **Documentation**: Check this README and code comments

---

**🎓 G'echo - Connecting University Students & Clubs**

*Built with Flutter & Firebase for GLA University*

**Latest Update**: Version 3.0 - Interactive engagement with Instagram-style UI and enhanced admin controls