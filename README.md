# KidsWala — Kids Fashion Rental Wear Full Stack Project

Children's traditional wear **rental booking management system** with ASP.NET Core 8 Web API, Angular 19, SQL Server, Dapper, JWT, and premium purple admin UI.

## Project Structure

```
Rantel Cloth WEB/
├── Database/                    # SQL scripts (tables + stored procedures)
├── Backend/KidsFashionRental.API/   # .NET 8 Web API
└── Frontend/kids-fashion-rental/    # Angular 19 SPA
```

## Complete Workflow

See **[docs/PROJECT_WORKFLOW.md](docs/PROJECT_WORKFLOW.md)** for the full system flow.

**Master setup order:** Category → Size → Color → Product → Booking

| Master | Route |
|--------|-------|
| Category | `/masters/category` |
| Size | `/masters/size` |
| Color | `/masters/color` |
| Product | `/masters/product` |

**Full script (recommended):** `Database/KidsFashionRentalDB_Full.sql` — everything in one file.

Or run separately: `KidsFashionRentalDB.sql` then `Masters_Migration.sql`.

### Separate API controllers (each has own Service + Repository)

| Controller | Route |
|------------|-------|
| CategoryController | `/api/category` |
| SizeController | `/api/size` |
| ColorController | `/api/color` |
| ProductController | `/api/product` |

## Modules Included

| Module | Description |
|--------|-------------|
| Dashboard | KPI cards, monthly income chart, booking status chart |
| Add Booking | Customer + product + payment flow (50% advance) |
| Booking List | Search, filter, invoice link, delete |
| Today Delivery Report | Filter by date, print |
| Today Return Report | Extra days, refund, profit |
| Invoice / WhatsApp | Print bill, send WhatsApp message |
| Product Availability | Real-time overlap check API |
| Upload APIs | Image + document upload |

## Step 1 — Database Setup

1. Open **SQL Server Management Studio** (or Azure Data Studio).
2. Connect to your server:
   - `SQL5053.site4now.net`
3. Run the full script:
   - `Database/KidsFashionRentalDB.sql`
4. This creates tables, sample data, and all stored procedures in `DB_A6B32D_LabelManagement`.

**Default login users** (after seed):

| Username | Password | Role |
|----------|----------|------|
| admin | 123456 | Super Admin |
| bookingadmin | 123456 | Admin |

> Update passwords via BCrypt in production.

## Step 2 — Backend API Setup

```powershell
cd "d:\Rantel Cloth WEB\Backend\KidsFashionRental.API"
dotnet restore
dotnet run --launch-profile https
```

- Swagger: https://localhost:7001/swagger
- Connection string is in `appsettings.json`:

```json
"DefaultConnection": "Data Source=SQL5053.site4now.net;Initial Catalog=DB_A6B32D_LabelManagement;..."
```

## Step 3 — Angular Frontend Setup

```powershell
cd "d:\Rantel Cloth WEB\Frontend\kids-fashion-rental"
npm install --legacy-peer-deps
npm start
```

- App URL: http://localhost:4200
- API URL: `src/environments/environment.ts` → `https://localhost:7001/api`

## API Endpoints (Main)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | JWT login |
| GET | `/api/dashboard/counts` | Dashboard KPIs |
| GET | `/api/dashboard/charts` | Charts data |
| GET | `/api/booking` | Booking list |
| POST | `/api/booking` | Create booking |
| GET | `/api/booking/check-availability` | Product availability |
| POST | `/api/booking/process-return` | Return + extra charge |
| GET | `/api/report/today-delivery` | Delivery report |
| GET | `/api/report/today-return` | Return report |
| POST | `/api/upload/image` | Upload product image |
| POST | `/api/upload/document` | Upload document |

## Booking Payment Flow

1. **Booking time** — Customer pays **50% of rent** (advance).
2. **Delivery time** — Remaining rent + full deposit.
3. **Return time** — Deposit refund minus extra day charges.

### Extra Day Example

- Rent ₹500, Deposit ₹1000, Standard 4 days, Extra ₹150/day
- Return 2 days late → Extra ₹300
- Refund = ₹1000 − ₹300 = **₹700**
- Final profit = **₹800**

## Architecture Pattern

```
Controller → IService → Service → IRepository → Repository → Dapper → Stored Procedure
```

Same pattern as your `BatchRepository` sample.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| API connection error | Run SQL script, verify connection string |
| CORS error | API allows `http://localhost:4200` |
| Login fails | Use `admin` / `123456` after DB seed |
| SSL certificate | Trust dev cert: `dotnet dev-certs https --trust` |

## Production Checklist

- [ ] Change JWT secret in `appsettings.json`
- [ ] Hash all user passwords with BCrypt
- [ ] Update `environment.prod.ts` API URL
- [ ] Publish API to IIS / Azure
- [ ] Build Angular: `ng build --configuration production`

---

**Designed for:** Kids Fashion Rental Wear — Kurta, Blazer, Sherwani, Indo Western rental shop.
