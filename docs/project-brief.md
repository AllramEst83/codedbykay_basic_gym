# Project Brief: FlexFlow Fitness Tracker

## Project Overview
FlexFlow is a high-fidelity mobile fitness application designed for users who balance diverse workout routines, specifically gym-based strength training and outdoor running. The app emphasizes a "snappy" user experience with a vibrant, "Kinetic Pastel" aesthetic, utilizing fluid animations and rounded UI elements to make fitness tracking feel approachable and energetic.

## Core Objectives
- **Comprehensive Tracking**: Support granular tracking for gym sets/reps and endurance-based running metrics (time/distance).
- **Visual Progress**: Provide clear, data-driven insights through historical logs and volume graphs.
- **Fluid UX**: Maintain a high-performance feel with consistent navigation and satisfying interaction feedback.
- **Customization**: Allow users to personalize their experience via themes and language settings.

## Design System: Kinetic Pastel
- **Visual Style**: Soft pastel color palette, high border-radius (ROUND_FULL), and clean typography (Plus Jakarta Sans).
- **Color Mode**: Supports both Light and Dark modes with specialized surface treatments.
- **Component Strategy**: Uses a shared library for Top App Bars and Bottom Navigation to ensure a unified feel across all flows.

## Functional Requirements & Screen Map

### 1. Workout Calendar (Home)
- **Purpose**: The central scheduling hub.
- **Features**: 
  - Month, Week, and Day views.
  - Activity markers on the calendar grid.
  - Quick-start cards for "Today's Workouts" with category badges (Strength, Cardio).

### 2. Active Session Tracker
- **Purpose**: Real-time workout execution.
- **Features**:
  - Live timer and exercise progress (e.g., "Exercise 3 of 6").
  - Dynamic input for weight and reps.
  - Satisfying checkmark interactions for completed sets.
  - Integrated rest period countdowns.

### 3. Workout Management
- **Purpose**: Library and routine organization.
- **Features**:
  - Categorization by workout type (Gym, Running, Yoga).
  - Recent updates list for quick editing of existing routines.
  - Global "Add" action for creating new workout templates.

### 4. Workout History & Progress
- **Purpose**: Retrospective analysis and motivation.
- **Features**:
  - Summary metrics (Duration, Calories).
  - Weekly volume bar chart.
  - Historical list with rich media (workout images) and fallback icons.

### 5. Settings & Profile
- **Purpose**: User personalization.
- **Features**:
  - Profile management (Avatar, Name, Email).
  - Preference toggles for App Theme and Language.
  - Notification controls for reminders and social activity.

