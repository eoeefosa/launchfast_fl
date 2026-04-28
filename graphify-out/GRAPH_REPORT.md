# Graph Report - lib  (2026-04-28)

## Corpus Check
- Corpus is ~30,725 words - fits in a single context window. You may not need a graph.

## Summary
- 766 nodes · 989 edges · 30 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Profile Editing & Auth Widgets|Profile Editing & Auth Widgets]]
- [[_COMMUNITY_Data Models & Providers|Data Models & Providers]]
- [[_COMMUNITY_UI Utilities & Static Data|UI Utilities & Static Data]]
- [[_COMMUNITY_Store Detail Components|Store Detail Components]]
- [[_COMMUNITY_Settings & Shell Navigation|Settings & Shell Navigation]]
- [[_COMMUNITY_Core Themes & Form Fields|Core Themes & Form Fields]]
- [[_COMMUNITY_Checkout Process|Checkout Process]]
- [[_COMMUNITY_Notifications Management|Notifications Management]]
- [[_COMMUNITY_Repositories & Base Screens|Repositories & Base Screens]]
- [[_COMMUNITY_Item Detail Interaction|Item Detail Interaction]]
- [[_COMMUNITY_Profile Display|Profile Display]]
- [[_COMMUNITY_Hero Animations & Empty States|Hero Animations & Empty States]]
- [[_COMMUNITY_Main Entry & App Configuration|Main Entry & App Configuration]]
- [[_COMMUNITY_Login & Authentication Screens|Login & Authentication Screens]]
- [[_COMMUNITY_Reusable Auth Components|Reusable Auth Components]]
- [[_COMMUNITY_Home Screen & Menu Lists|Home Screen & Menu Lists]]
- [[_COMMUNITY_Search & Global Providers|Search & Global Providers]]
- [[_COMMUNITY_Cart Screen & Logic|Cart Screen & Logic]]
- [[_COMMUNITY_External Services (Ably, API)|External Services (Ably, API)]]
- [[_COMMUNITY_Detailed Item Options|Detailed Item Options]]
- [[_COMMUNITY_Application Router|Application Router]]
- [[_COMMUNITY_Order Tracking & Rider Info|Order Tracking & Rider Info]]
- [[_COMMUNITY_Menu Grouping & Categorization|Menu Grouping & Categorization]]
- [[_COMMUNITY_Item Detail Layouts|Item Detail Layouts]]
- [[_COMMUNITY_Order & Store Entity Models|Order & Store Entity Models]]
- [[_COMMUNITY_Cart & Menu Item Models|Cart & Menu Item Models]]
- [[_COMMUNITY_Color Mapping Utilities|Color Mapping Utilities]]
- [[_COMMUNITY_Rider Data Model|Rider Data Model]]
- [[_COMMUNITY_User Profile Model|User Profile Model]]
- [[_COMMUNITY_Menu Item Model|Menu Item Model]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 68 edges
2. `package:go_router/go_router.dart` - 26 edges
3. `package:provider/provider.dart` - 24 edges
4. `package:flutter_animate/flutter_animate.dart` - 19 edges
5. `../../models/menu_item.dart` - 18 edges
6. `../../providers/auth_provider.dart` - 15 edges
7. `../../providers/cart_provider.dart` - 15 edges
8. `dart:io` - 11 edges
9. `package:flutter/cupertino.dart` - 11 edges
10. `../../providers/store_provider.dart` - 10 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities

### Community 0 - "Profile Editing & Auth Widgets"
Cohesion: 0.04
Nodes (52): ../../../auth/widgets/constants.dart, ../../../auth/widgets/custom_button.dart, BottomSheetScaffold, build, _buildTextField, dispose, EditProfileSheet, _EditProfileSheetState (+44 more)

### Community 1 - "Data Models & Providers"
Cohesion: 0.05
Nodes (45): ../../constants/static_data.dart, dart:convert, setupLocator, copyWith, NotificationItem, toJson, _typeFromString, AuthProvider (+37 more)

### Community 2 - "UI Utilities & Static Data"
Cohesion: 0.04
Nodes (45): app_colors.dart, StaticData, MenuRepository, build, Container, dispose, GestureDetector, initState (+37 more)

### Community 3 - "Store Detail Components"
Cohesion: 0.04
Nodes (44): ../../constants/app_colors.dart, build, Builder, _buildMenuItemCard, _buildStatBadge, Container, Divider, Scaffold (+36 more)

### Community 4 - "Settings & Shell Navigation"
Cohesion: 0.05
Nodes (42): dart:io, build, Padding, ProfileSettingsTile, SizedBox, _AnimatedIcon, BottomNavigationBarItem, build (+34 more)

### Community 5 - "Core Themes & Form Fields"
Cohesion: 0.05
Nodes (30): AppColors, copyWith, Store, AppTextField, build, TextFormField, AlertDialog, build (+22 more)

### Community 6 - "Checkout Process"
Cohesion: 0.06
Nodes (35): _appBar, _bottomBar, build, _buildOrderSummary, _buildPaymentTile, CheckoutScreen, _CheckoutScreenState, Container (+27 more)

### Community 7 - "Notifications Management"
Cohesion: 0.06
Nodes (33): AlertDialog, AppBar, build, Center, _ClearAllDialog, Column, Container, _DismissBackground (+25 more)

### Community 8 - "Repositories & Base Screens"
Cohesion: 0.06
Nodes (30): AuthRepository, OrderRepository, _AndroidScrollView, AppBar, build, Center, CupertinoNavigationBar, CustomScrollView (+22 more)

### Community 9 - "Item Detail Interaction"
Cohesion: 0.06
Nodes (30): components/item_detail_dialogs.dart, components/item_detail_footer.dart, components/item_detail_scroll_body.dart, _addSoupIfNeeded, build, dispose, _handleAddToCart, initState (+22 more)

### Community 10 - "Profile Display"
Cohesion: 0.06
Nodes (28): build, Container, Padding, ProfileHeader, _RoleBadge, _showEditModal, SizedBox, build (+20 more)

### Community 11 - "Hero Animations & Empty States"
Cohesion: 0.06
Nodes (28): dart:ui, build, ItemDetailCloseButton, ItemDetailHero, Material, SizedBox, Align, _BrowseButton (+20 more)

### Community 12 - "Main Entry & App Configuration"
Cohesion: 0.07
Nodes (29): build, main, MyApp, ScreenUtilInit, _textTheme, build, Expanded, launchUrl (+21 more)

### Community 13 - "Login & Authentication Screens"
Cohesion: 0.08
Nodes (28): action, _authenticate, AuthPrompt, BackButton, build, dispose, ForgotPasswordButton, LoginScreen (+20 more)

### Community 14 - "Reusable Auth Components"
Cohesion: 0.07
Nodes (22): AuthPrompt, build, Row, BackButton, build, IconButton, Align, build (+14 more)

### Community 15 - "Home Screen & Menu Lists"
Cohesion: 0.08
Nodes (24): _AnimatedMenuList, _AnimatedMenuListState, build, _CategoryHeaderDelegate, dispose, Function, _handleAddItem, HomeScreen (+16 more)

### Community 16 - "Search & Global Providers"
Cohesion: 0.09
Nodes (20): NotificationProvider, _saveNotifications, ThemeProvider, build, _buildHistory, _buildResults, Center, Container (+12 more)

### Community 17 - "Cart Screen & Logic"
Cohesion: 0.1
Nodes (20): AnimatedSwitcher, AppBar, build, _buildAppBar, _CartBody, CartScreen, CupertinoNavigationBar, _getAccentColor (+12 more)

### Community 18 - "External Services (Ably, API)"
Cohesion: 0.1
Nodes (19): api_service.dart, dart:async, AblyService, addNotificationListener, addOrderListener, addRoleListener, addStoreListener, _cancelAllSubscriptions (+11 more)

### Community 19 - "Detailed Item Options"
Cohesion: 0.12
Nodes (16): AnimatedContainer, build, Column, GestureDetector, ItemDetailAddonOption, ItemDetailAnimatedCheckbox, ItemDetailMeatOption, ItemDetailOptionsSection (+8 more)

### Community 20 - "Application Router"
Cohesion: 0.12
Nodes (15): package:launchfast/screens/auth/forgot_password_screen.dart, package:launchfast/screens/auth/login_screen.dart, package:launchfast/screens/auth/register_screen.dart, package:launchfast/screens/notifications_screen.dart, package:launchfast/screens/stores_screen.dart, package:launchfast/screens/tabs/home_screen.dart, package:launchfast/screens/tabs/orders_screen.dart, package:launchfast/screens/tabs/profile_screen.dart (+7 more)

### Community 21 - "Order Tracking & Rider Info"
Cohesion: 0.14
Nodes (13): ActiveOrderTracker, build, _CallButton, Container, CupertinoButton, _getStatusDescription, _getStatusText, IconButton (+5 more)

### Community 22 - "Menu Grouping & Categorization"
Cohesion: 0.2
Nodes (9): build, _CategoryGroup, Function, MenuGroupedList, Opacity, SizedBox, SliverFillRemaining, SliverList (+1 more)

### Community 23 - "Item Detail Layouts"
Cohesion: 0.22
Nodes (8): item_detail_header.dart, item_detail_hero.dart, item_detail_options.dart, build, Function, ItemDetailScrollBody, SingleChildScrollView, SizedBox

### Community 24 - "Order & Store Entity Models"
Cohesion: 0.29
Nodes (6): cart_item.dart, copyWith, fromString, Order, store.dart, user.dart

### Community 25 - "Cart & Menu Item Models"
Cohesion: 0.29
Nodes (6): dart:math, CartItem, FormatException, _mapsEqual, sameSlotAs, menu_item.dart

### Community 26 - "Color Mapping Utilities"
Cohesion: 0.67
Nodes (2): argbToHex, hexToArgb

### Community 27 - "Rider Data Model"
Cohesion: 1.0
Nodes (1): Rider

### Community 28 - "User Profile Model"
Cohesion: 1.0
Nodes (1): UserProfile

### Community 29 - "Menu Item Model"
Cohesion: 1.0
Nodes (1): MenuItem

## Knowledge Gaps
- **638 isolated node(s):** `setupLocator`, `package:get_it/get_it.dart`, `package:launchfast/screens/auth/forgot_password_screen.dart`, `package:launchfast/screens/auth/login_screen.dart`, `package:launchfast/screens/auth/register_screen.dart` (+633 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Rider Data Model`** (2 nodes): `rider.dart`, `Rider`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `User Profile Model`** (2 nodes): `user.dart`, `UserProfile`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Menu Item Model`** (2 nodes): `menu_item.dart`, `MenuItem`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Core Themes & Form Fields` to `Profile Editing & Auth Widgets`, `Data Models & Providers`, `UI Utilities & Static Data`, `Store Detail Components`, `Settings & Shell Navigation`, `Checkout Process`, `Notifications Management`, `Repositories & Base Screens`, `Item Detail Interaction`, `Profile Display`, `Hero Animations & Empty States`, `Main Entry & App Configuration`, `Login & Authentication Screens`, `Reusable Auth Components`, `Home Screen & Menu Lists`, `Search & Global Providers`, `Cart Screen & Logic`, `Detailed Item Options`, `Order Tracking & Rider Info`, `Menu Grouping & Categorization`, `Item Detail Layouts`?**
  _High betweenness centrality (0.563) - this node is a cross-community bridge._
- **Why does `package:go_router/go_router.dart` connect `Reusable Auth Components` to `Store Detail Components`, `Settings & Shell Navigation`, `Checkout Process`, `Notifications Management`, `Item Detail Interaction`, `Profile Display`, `Hero Animations & Empty States`, `Login & Authentication Screens`, `Search & Global Providers`, `Application Router`?**
  _High betweenness centrality (0.086) - this node is a cross-community bridge._
- **Why does `package:provider/provider.dart` connect `Store Detail Components` to `Profile Editing & Auth Widgets`, `Settings & Shell Navigation`, `Checkout Process`, `Notifications Management`, `Repositories & Base Screens`, `Item Detail Interaction`, `Main Entry & App Configuration`, `Login & Authentication Screens`, `Home Screen & Menu Lists`, `Search & Global Providers`, `Cart Screen & Logic`?**
  _High betweenness centrality (0.066) - this node is a cross-community bridge._
- **What connects `setupLocator`, `package:get_it/get_it.dart`, `package:launchfast/screens/auth/forgot_password_screen.dart` to the rest of the system?**
  _638 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Profile Editing & Auth Widgets` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Data Models & Providers` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
- **Should `UI Utilities & Static Data` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._