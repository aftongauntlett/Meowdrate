# Pet animation assets

`PetView` (lib/features/pet/widgets/pet_view.dart) looks for a Lottie
animation per mood and falls back to a placeholder emoji if the file is
missing, so the app runs fine before these are added.

Drop in files with these exact names to replace the placeholders:

- `idle.json`
- `happy.json`
- `thirsty.json`

Any free, appropriately-licensed cute character Lottie animation works —
e.g. search LottieFiles for a small creature/pet with idle, happy, and
tired/thirsty-looking loops. No code changes needed once the files are here.
