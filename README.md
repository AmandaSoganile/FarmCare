# FarmCare

FarmCare is an app designed to help farmers record animal vaccinations and feeding schedules

## Description

- FarmCare is a solution designed to modernize traditional livestock management
- FarmCare allows farmers to track vaccinations and feeding schedules effortlessly
- Users can easily add new livestock to their registry by specifying names, breeds, and critical health data
-  Users can access individual animal profiles to review comprehensive health histories
- Compatible on macOS 26.0+ and iOS 26.0+
- SwiftUI is used to create the app
- Supabase is used for authentication
- SwiftData is used for local data persistence

## Requirements

- Xcode 15.0 or later
- iOS 18.6+ / macOS 18.6+
- Swift 5.9+

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
│   ├── CContentView.swift
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
├── Constants.swift
│   └──Supabase.swift
└── Resources/
    └── Assets.xcassets
```

## Features

- Feature 1: **Secure Authentication**: Users can experience peace of mind with a secure sign-in and sign-up process, ensuring all personal and livestock data is encrypted and safely stored
- Feature 2: **Livestock Dashboard & Health Alerts**: Users gain a high-level overview of their entire herd, organized by category. The dashboard features an integrated "at-a-glance" tracker for upcoming vaccinations and immediate alerts for any missed doses.
- Feature 3: **Detailed Health Monitoring**: Users can access individual animal profiles to review comprehensive health histories. They can also log
real-time observations, such as changes in feeding habits or behavioral notes, to ensure proactive care

## Notes

- **Known Issues**: Does not show an alert for what is incorrect when password or username has been entered incorrectly

Health indicator is not accurate 

- **Future Improvements**: 
   Multi-Species Management: Users will be able to effortlessly manage more diverse livestock, moving from just cows, pigs, andchickens to many more, tailored to  the unique needs of each species

   Fully-Functional Settings Page: Users will be able to access different settings and customise their experience on their app.
- **Architecture**: MVVM



## Contact

Amanda - [@AmandaSoganile](www.linkedin.com/in/amanda-soganile-8237ba365) - soganileamanda@gmail.com

Project Link: [https://github.com/AmandaSoganile/FarmCare](https://github.com/AmandaSoganile/FarmCare)
