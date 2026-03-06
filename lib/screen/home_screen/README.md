# Homepage Implementation Guide

## 📁 File Structure

```
lib/screen/home_screen/
├── domain/
│   └── bloc/
│       ├── home_event.dart      # Events that trigger state changes
│       ├── home_state.dart      # Current state of the homepage
│       └── home_bloc.dart       # Business logic handler
└── presentation/
    ├── pages/
    │   └── home_screen.dart      # Main homepage screen
    └── widgets/
        ├── video_background.dart      # Video background with overlay
        ├── hero_section.dart          # Hero section with headline & CTAs
        ├── features_section.dart      # Features list
        ├── trust_indicators.dart      # Platform icons & "How it Works"
        └── floating_elements.dart     # Animated floating icons/bubbles
```

## 🔄 Code Flow Explanation

### 1. **Entry Point: `home_screen.dart`**

**What happens:**
- When user navigates to `/home`, `HomeScreen` widget is created
- `BlocProvider` creates a new `HomeBloc` instance
- Immediately dispatches `HomeInitialized` event
- `_HomeScreenContent` builds the UI

**Flow:**
```
User navigates to /home
  ↓
HomeScreen.build()
  ↓
BlocProvider creates HomeBloc
  ↓
HomeBloc receives HomeInitialized event
  ↓
State changes to HomeStatus.loading
  ↓
UI rebuilds with loading state
```

### 2. **BLoC Pattern (State Management)**

**BLoC = Business Logic Component**

**How it works:**
```
Event → BLoC → State → UI
```

**Example Flow:**
```
User clicks "Create Room" button
  ↓
Event: CreateRoomPressed
  ↓
HomeBloc._onCreateRoomPressed() handles it
  ↓
State updates (if needed)
  ↓
UI rebuilds automatically
```

**Files:**

**`home_event.dart`** - All possible events:
- `HomeInitialized` - When homepage first loads
- `CreateRoomPressed` - User clicks "Create Room"
- `JoinRoomPressed` - User clicks "Join Room"
- `VideoLoaded` - Video successfully loaded
- `VideoError` - Video failed to load

**`home_state.dart`** - Current state:
- `status` - Loading, loaded, or error
- `isVideoLoaded` - Whether video is ready
- `videoError` - Error message if video fails

**`home_bloc.dart`** - Event handlers:
- `_onHomeInitialized()` - Sets status to loading
- `_onVideoLoaded()` - Updates state when video loads
- `_onVideoError()` - Handles video errors
- `_onCreateRoomPressed()` - TODO: Navigate to create room
- `_onJoinRoomPressed()` - TODO: Navigate to join room

### 3. **Video Background Flow**

**`video_background.dart`** - How video loads:

```
Widget created
  ↓
initState() called
  ↓
If videoPath provided:
  ↓
_initializeVideo() called
  ↓
VideoPlayerController.asset() loads video
  ↓
await controller.initialize()
  ↓
If successful:
  - Set looping = true
  - Set volume = 0 (muted)
  - Play video
  - Dispatch VideoLoaded event to BLoC
  ↓
If error:
  - Dispatch VideoError event to BLoC
  ↓
Fallback: Show gradient background
```

**Key Features:**
- **Lazy Loading**: Video only loads if path is provided
- **Fallback**: Beautiful gradient if no video or error
- **Overlay**: 0.4 opacity black overlay for text readability
- **Optimized**: Muted, looping, autoplay

### 4. **UI Components Flow**

**Main Screen Structure:**
```
Scaffold
  └── VideoBackground (background layer)
      └── Stack
          ├── FloatingElements (animated icons/bubbles)
          └── SafeArea
              └── SingleChildScrollView
                  └── Column
                      ├── HeroSection
                      ├── FeaturesSection
                      ├── TrustIndicators
                      └── Bottom CTA Button
```

**Component Details:**

**`hero_section.dart`:**
- Displays headline: "Watch Together, Anywhere"
- Subtitle: "Sync Your Screen, Share the Vibe"
- Two CTA buttons: "Start Watching" (orange) and "Create Room" (outlined)

**`features_section.dart`:**
- Lists 3 features with icons
- Each feature has: icon, title, description
- Responsive font sizes

**`trust_indicators.dart`:**
- Platform icons: YouTube, Netflix, Twitch, Local Files
- "How it Works" 3-step process:
  1. Create Room
  2. Invite Friends
  3. Watch in Sync

**`floating_elements.dart`:**
- 8 animated elements (4 sync icons, 4 chat bubbles)
- Uses AnimationController for smooth movement
- Pulses and drifts around screen edges

### 5. **State Updates & UI Rebuilds**

**How BLoC updates UI:**

```dart
BlocBuilder<HomeBloc, HomeState>(
  builder: (context, state) {
    // This rebuilds whenever state changes
    return Widget(...);
  },
)
```

**Example:**
```
Video starts loading
  ↓
VideoLoaded event dispatched
  ↓
BLoC updates state: isVideoLoaded = true
  ↓
All BlocBuilder widgets rebuild
  ↓
UI shows video instead of gradient
```

## 🐛 Debugging Guide

### **Common Issues & Solutions:**

#### 1. **Video Not Showing**
**Check:**
- Is video file at `assets/videos/home_background.mp4`?
- Is `videoPath` uncommented in `home_screen.dart`?
- Check console for video errors
- Verify video format (MP4, H.264)

**Debug:**
```dart
// In video_background.dart, add print statements:
print('Video path: ${widget.videoPath}');
print('Video initialized: $_isInitialized');
print('Controller value: ${_controller?.value.isInitialized}');
```

#### 2. **BLoC Not Updating**
**Check:**
- Is `BlocProvider` wrapping the widget tree?
- Are you using `BlocBuilder` to listen to state?
- Is event being dispatched correctly?

**Debug:**
```dart
// Add listener to see state changes:
BlocListener<HomeBloc, HomeState>(
  listener: (context, state) {
    print('State changed: ${state.status}');
    print('Video loaded: ${state.isVideoLoaded}');
  },
  child: YourWidget(),
)
```

#### 3. **UI Not Responsive**
**Check:**
- Are you using `MediaQuery.of(context).size.width`?
- Are font sizes using responsive values?
- Test on different screen sizes

**Debug:**
```dart
// Print screen size:
print('Screen width: ${MediaQuery.of(context).size.width}');
print('Screen height: ${MediaQuery.of(context).size.height}');
```

#### 4. **Animations Not Working**
**Check:**
- Are AnimationControllers disposed properly?
- Are animations repeating?
- Check `floating_elements.dart` for controller setup

**Debug:**
```dart
// In floating_elements.dart:
print('Controllers created: ${_controllers.length}');
print('Animations running: ${_controllers.every((c) => c.isAnimating)}');
```

### **Debugging Tools:**

1. **Flutter DevTools:**
   - Open DevTools → Widget Inspector
   - See widget tree and properties
   - Check BLoC state in real-time

2. **Print Statements:**
   ```dart
   // In BLoC:
   print('Event received: $event');
   print('Current state: $state');
   
   // In widgets:
   print('Widget built: ${widget.runtimeType}');
   ```

3. **BLoC Observer (Optional):**
   ```dart
   // Add to main.dart:
   Bloc.observer = SimpleBlocObserver();
   
   class SimpleBlocObserver extends BlocObserver {
     @override
     void onChange(BlocBase bloc, Change change) {
       super.onChange(bloc, change);
       print('${bloc.runtimeType} $change');
     }
   }
   ```

## 📊 Data Flow Diagram

```
┌─────────────────────────────────────────┐
│         User Interaction                 │
│  (Clicks button, navigates, etc.)       │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         Event Created                    │
│  (CreateRoomPressed, VideoLoaded, etc.)  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         HomeBloc                         │
│  - Receives event                       │
│  - Processes business logic             │
│  - Updates state                        │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         State Updated                   │
│  (status, isVideoLoaded, videoError)    │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         BlocBuilder Rebuilds            │
│  - Listens to state changes             │
│  - Rebuilds UI automatically            │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         UI Updates                      │
│  (New content displayed to user)        │
└─────────────────────────────────────────┘
```

## 🔍 Key Files to Check When Debugging

1. **`home_screen.dart`** - Main entry point, check BLoC setup
2. **`home_bloc.dart`** - Check event handlers, see if events are processed
3. **`home_state.dart`** - Check current state values
4. **`video_background.dart`** - Check video loading logic
5. **Router** (`app_router.dart`) - Check if `/home` route is correct

## 💡 Tips for Easy Debugging

1. **Use meaningful print statements:**
   ```dart
   print('[HomeScreen] Widget built');
   print('[HomeBloc] Event: $event');
   print('[VideoBackground] Initializing video...');
   ```

2. **Check BLoC state in DevTools:**
   - Open Flutter DevTools
   - Go to "BLoC" tab
   - See all events and state changes

3. **Test components individually:**
   - Wrap widgets in `BlocProvider.value` for testing
   - Create mock states for testing

4. **Follow the event flow:**
   - Start from user action
   - Trace through event → BLoC → state → UI
   - Add print statements at each step

## 🎯 Quick Reference

**To add a new feature:**
1. Add event in `home_event.dart`
2. Add state property in `home_state.dart` (if needed)
3. Add handler in `home_bloc.dart`
4. Use `BlocBuilder` or `BlocListener` in UI
5. Dispatch event from UI

**To debug video:**
1. Check `video_background.dart` initialization
2. Check BLoC state: `isVideoLoaded`, `videoError`
3. Verify video file exists and format is correct
4. Check console for video player errors

**To debug UI:**
1. Check if `BlocBuilder` is listening to correct state
2. Verify state values are updating
3. Check responsive breakpoints
4. Test on different screen sizes
