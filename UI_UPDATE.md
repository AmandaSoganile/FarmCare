# Small FarmCare UI refresh

The original branding, green palette, animal artwork, three-tab organization, and core animal fields remain familiar.

Implemented:

- Consistent rounded cards, system-adaptive backgrounds, and readable text hierarchy.
- Dashboard totals, species counts, compact vaccination rows, and useful empty states. Vaccination rows open the animal profile.
- A modal Add form grouped into Animal details, Feeding, and Vaccination schedule, with Cancel and validation. Adding from a species list selects that species automatically.
- The Add tab returns to the previous tab behind the sheet, avoiding a blank screen after dismissal.
- Animal list search by name or breed, stable alphabetical display, and deletion against the visible filtered list.
- Profile cards, accessible vaccination schedule badges, and explicit Save/Cancel for notes. The old frequency-based health dot is removed; a vaccination schedule label does not claim to diagnose animal health.
- Vaccination dates compare calendar days: a dose due today is not overdue; it becomes overdue the next day.
- A compact sync status and Retry action. Tap the status for the complete error message.
- Shared green styling on welcome/auth screens. Appearance follows the system by default and can be changed in Settings.
- Settings no longer presents nonfunctional privacy/terms/help labels as completed features. Notification preferences are marked Planned.

Verification completed: Swift source syntax parsing, asset JSON/plist validation, unchanged database tests, and package integrity checks. Xcode compilation, real layout rendering, VoiceOver, Dynamic Type, dark mode, and simulator/device interaction tests have not been run here.

Mac checks before acceptance:

1. Build with Xcode 26 and configure the existing Supabase connection using SETUP.md.
2. Try Home, Add, and Animals. Open and dismiss Add repeatedly from each tab.
3. Add cattle, pigs, and chickens, including an animal weighing under 40 kg; test invalid and missing weights/fields.
4. Search and delete within a species list, including multiple selected rows. Check the correct records were deleted.
5. Open vaccination rows, edit/save/cancel notes, and retry a failed sync.
6. Test Settings appearance in light, dark, and system modes. Check the smallest supported iPhone, iPad, landscape, and larger accessibility text sizes.
7. Verify vaccination labels for yesterday, today, 7 days ahead, and 8 days ahead, including around midnight.

Backend replacement is proposed in API_DESIGN.md and has not been implemented in this update.
