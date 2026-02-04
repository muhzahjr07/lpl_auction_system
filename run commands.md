cmd /c "cd server && npm.cmd install"

cd server
node seed.js

cd server
node index.js

cmd /c "ngrok http 5000"

cd mobile_app
flutter pub get
flutter run

cd mobile_app
flutter run -d edge