# FarmCare

The new FarmCare API and iOS connection instructions are in
[backend/README.md](backend/README.md). It includes local PostgreSQL, account
verification, password recovery, and animal sync. Existing Supabase support is
retained during migration. Build the app with Xcode 26+ and an iOS 26 simulator.

FarmCare is an app designed to help farmers record animal vaccinations and feeding schedules

## Description

- FarmCare is a solution designed to modernize traditional livestock management
- FarmCare allows farmers to track vaccinations and feeding schedules effortlessly
- Users can easily add new livestock to their registry by specifying names, breeds, and critical health data
- Users can access individual animal profiles to review comprehensive health histories
- Native iPhone/iPad app targeting iOS 26.0+; development requires a Mac with Xcode
- SwiftUI is used to create the app
- Supabase is used for authentication and account-scoped animal storage
- SwiftData is used for local data persistence

## Requirements

- Xcode 26 or later
- iOS 26.0+ simulator or device
- Supabase project with email/password authentication

## Continue in Xcode

Read [HANDOVER.md](HANDOVER.md) for the current state and next steps. The modest UI refresh is described in [UI_UPDATE.md](UI_UPDATE.md), and the proposed custom API is in [API_DESIGN.md](API_DESIGN.md). The custom API has not been implemented.

## Backend update

See [SETUP.md](SETUP.md) for the database migration, local configuration, account isolation, syncing behavior, and Mac verification steps. See [VALIDATION.md](VALIDATION.md) for completed checks and limitations. Feeding/vaccination histories and remaining settings are still future work.

## Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/AmandaSoganile/FarmCare.git
   cd FarmCare
   ```

2. **Open the project**
   - Open `FarmCare.xcodeproj` in Xcode

2. **Install dependencies** (if using SPM, CocoaPods, or Carthage)
   - For Swift Package Manager: Dependencies should resolve automatically
   - For CocoaPods: Run `pod install`
   - For Carthage: Run `carthage update`

4. **Configure signing**
   - Select your development team in the project settings
   - Update the bundle identifier if needed

5. **Build and run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run the project

## Project Structure

```
YourProject/
├── App/
│   └── FarmCareApp.swift
├── Animals Views/
│   ├──AddNewAnimal.swift
│   ├──AnimalCategories.swift
│   ├──AnimalProfile.swift
│   ├──SingleAnimalRow.swift
│   └── SingleAnimalSpecies.swift
├── Main Views/
│   ├── ContentView.swift
│   ├── HomePage.swift
│   ├── Settings.swift
│   ├── TabsView.swift
│   └── VaccinationRow.swift
├── Models/
│   ├── AnimalCategoryModel.swift
│   ├── AnimalModel.swift
│   ├── AuthViewModel.swift
│   └── SummaryCardModel.swift
├── User Authentication Models/
│   ├── CustomTextField.swift
│   ├── SignIn.swift
│   └──SignUp.swift
├── Utilities/
│   ├──Constants.swift
│   └──Supabase.swift
└── Resources/
    └── Assets.xcassets
```

## Features

- Feature 1: **Account Authentication**: Email/password signup and signin, email-confirmation handling, session restoration, and logout. Database access policies isolate animal records by account.
- Feature 2: **Livestock Dashboard & Health Alerts**: Users gain a high-level overview of their entire herd, organized by category. The dashboard features an integrated "at-a-glance" tracker for upcoming vaccinations and immediate alerts for any missed doses.
- Feature 3: **Detailed Health Monitoring**: Users can access individual animal profiles to review comprehensive health histories. They can also log
real-time observations, such as changes in feeding habits or behavioral notes, to ensure proactive care

## Notes

- **Known Issues**: Full Xcode and hosted Supabase verification is pending; see SETUP.md. Local animal records from the previous shared store require an explicit ownership import.

Vaccination schedule badges describe due dates, not a medical health assessment.

- **Future Improvements**: 
   Multi-Species Management: Users will be able to effortlessly manage more diverse livestock, moving from just cows, pigs, andchickens to many more, tailored to  the unique needs of each species

   Fully-Functional Settings Page: Users will be able to access different settings and customise their experience on their app.
- **Architecture**: MVVM



## Contact

Amanda - [@AmandaSoganile](www.linkedin.com/in/amanda-soganile-8237ba365) - soganileamanda@gmail.com

Project Link: [https://github.com/AmandaSoganile/FarmCare](https://github.com/AmandaSoganile/FarmCare)
