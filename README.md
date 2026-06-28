# NeoLog - NICU Digital Companion

A cross-platform clinical management app for neonatologists managing preterm babies in the NICU. Built with Flutter (frontend) and Node.js/Express (backend).

## Features

- **Patient Management** — Register and track NICU babies with complete demographics
- **Daily Logs** — Structured clinical logs with vitals, respiratory support, feeds, systemic exam, and management plan
- **Growth Charts** — Fenton 2013 preterm growth charts with percentile plotting for weight, head circumference, and length
- **Screening Trackers** — ROP, IVH (head USS), 2D Echo, Hearing (OAE/AABR), and Newborn Blood Spot
- **Medication Tracking** — Current and past medications with dosing details
- **Clinical Events Timeline** — Procedures, complications, diagnoses, transfusions, surgeries
- **Investigation Results** — Lab results with interpretation flagging
- **Discharge Summary Generator** — Auto-compiles all clinical data into an editable, exportable PDF
- **Offline-First** — Works without internet using Hive local storage
- **Dark Mode** — Full dark theme support

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Frontend | Flutter (Dart) |
| State Management | Riverpod |
| Navigation | GoRouter |
| Local Storage | Hive |
| Charts | fl_chart |
| PDF Export | pdf + printing |
| Backend | Node.js + Express |
| Database | PostgreSQL + Prisma ORM |
| Auth | JWT + bcrypt |
| CI/CD | GitHub Actions |
| Hosting | GitHub Pages (Flutter Web) |

## Project Structure

```
neolog/
├── app/                    # Flutter project
│   ├── lib/
│   │   ├── core/           # Constants, theme, router, utils, widgets
│   │   ├── features/       # Feature modules (auth, babies, daily_log, etc.)
│   │   └── services/       # API, storage, auth services
│   ├── web/                # Flutter web template
│   └── test/               # Tests
├── backend/                # Node.js API
│   ├── src/
│   │   ├── routes/         # Express route handlers
│   │   ├── middleware/      # Auth and error handling
│   │   ├── services/       # Business logic
│   │   └── config/         # Database config
│   └── prisma/             # Database schema
└── .github/workflows/      # CI/CD pipeline
```

## Quick Start

### Prerequisites

- Flutter SDK (stable channel)
- Node.js 18+
- PostgreSQL (for backend)

### Flutter App

```bash
cd app
flutter pub get
flutter run -d chrome    # Web preview
flutter run              # Connected device
```

### Demo Mode

The app supports offline demo mode. On the login screen, tap "Try Demo Mode" to log in without a backend.

### Backend

```bash
cd backend
cp .env.example .env     # Edit with your DB credentials
npm install
npx prisma migrate dev
npm run dev
```

### Deploy to GitHub Pages

Push to `main` branch — GitHub Actions automatically builds and deploys Flutter Web:

```bash
git add .
git commit -m "feat: your changes"
git push origin main
```

The app will be live at `https://[username].github.io/neolog/`

## Clinical Logic

- **Gestational Age** — CGA = GA at birth + postnatal age, displayed as weeks+days
- **ROP Screening** — Per AIIMS guidelines: first exam at 4 weeks of life OR 31 weeks CGA (whichever is later) for babies ≤34 weeks or ≤2000g
- **IVH Screening** — Head USS at 72 hours, Day 7, and Day 28
- **Echo Schedule** — Day 3, 7, 28 for babies ≤30 weeks GA
- **Growth Charts** — Fenton 2013 preterm growth chart (22-50 weeks) with P3/P10/P50/P90/P97 percentile lines

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/auth/register | Create account |
| POST | /api/auth/login | Sign in |
| GET | /api/babies | List patients |
| POST | /api/babies | Register baby |
| GET | /api/babies/:id | Patient details |
| PUT | /api/babies/:id | Update patient |
| GET/POST | /api/babies/:id/logs | Daily logs |
| GET/POST | /api/babies/:id/growth | Growth data |
| GET/POST | /api/babies/:id/rop | ROP screenings |
| GET/POST | /api/babies/:id/ivh | IVH screenings |
| GET/POST | /api/babies/:id/echo | Echo reports |
| GET/POST | /api/babies/:id/hearing | Hearing screens |
| GET/POST | /api/babies/:id/nbs | Newborn blood spots |
| GET/POST | /api/babies/:id/events | Clinical events |
| GET/POST | /api/babies/:id/medications | Medications |
| GET/POST | /api/babies/:id/investigations | Lab results |
| GET | /api/babies/:id/discharge-summary | Auto-generate summary |

## License

Private — for clinical use only.
