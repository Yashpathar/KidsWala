# Kids Fashion Rental Wear — Complete Project Workflow

## System overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        ANGULAR ADMIN PANEL                               │
│  Login → Dashboard → Masters → Booking → Reports → Invoice/WhatsApp      │
└─────────────────────────────────────────────────────────────────────────┘
                                    │ JWT + REST
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                   ASP.NET CORE 8 API (Dapper)                            │
│  Auth │ Masters (Category/Size/Color/Product) │ Booking │ Reports        │
└─────────────────────────────────────────────────────────────────────────┘
                                    │ Stored Procedures
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              SQL Server — DB_A6B32D_LabelManagement                      │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1 — Environment setup

| Step | Action | Script / Path |
|------|--------|----------------|
| 1.1 | Create database objects | `Database/KidsFashionRentalDB.sql` |
| 1.2 | Add master tables | `Database/Masters_Migration.sql` |
| 1.3 | Configure API connection | `Backend/.../appsettings.json` |
| 1.4 | Run API | `dotnet run` → https://localhost:7001/swagger |
| 1.5 | Run Angular | `npm start` → http://localhost:4200 |

**Login:** `admin` / `123456`

---

## Phase 2 — Master data workflow (setup once, maintain ongoing)

Masters must be created **before** products. Booking uses products.

```
Category Master ──┐
Size Master     ──┼──► Product Master ──► Add Booking
Color Master    ──┘
```

### 2.1 Category Master

| Field | Purpose |
|-------|---------|
| CategoryName | Kurta, Blazer, Sherwani, etc. |
| Description | Optional notes |
| CompanyID | Multi-branch filter |

**UI:** `/masters/category` — Add / Edit / Delete / View popup

**API:** `GET/POST/PUT/DELETE /api/masters/category`

### 2.2 Size Master

| Field | Purpose |
|-------|---------|
| SizeName | 28, 30, 32… |
| SizeCode | S, M, L (optional) |
| SortOrder | Display order |

**UI:** `/masters/size`

**API:** `/api/masters/size`

### 2.3 Color Master

| Field | Purpose |
|-------|---------|
| ColorName | Navy Blue, Cream Gold… |
| ColorCode | Hex for UI swatch |

**UI:** `/masters/color`

**API:** `/api/masters/color`

### 2.4 Product Master

| Field | Source |
|-------|--------|
| ProductCode | Unique SKU (e.g. BL-02) |
| ProductName | Display name |
| CategoryID | Dropdown → Category Master |
| SizeID | Dropdown → Size Master |
| ColorID | Dropdown → Color Master |
| RentAmount / DepositAmount | Pricing |
| StandardRentalDays / ExtraChargePerDay | Late return rules |
| ProductImage | Upload API |
| AvailableQuantity | Stock count |

**UI:** `/masters/product`

**API:** `/api/masters/product`

---

## Phase 3 — Booking workflow

```
┌──────────────┐    ┌──────────────┐    ┌─────────────────┐
│ Select       │    │ Check        │    │ Payment split   │
│ Customer     │───►│ Availability │───►│ 50% advance     │
│ + Dates      │    │ (no overlap) │    │ at booking      │
└──────────────┘    └──────────────┘    └─────────────────┘
                           │
                    If booked → RED alert
                    Show conflict customer/dates
```

### 3.1 Booking statuses

| Status | When |
|--------|------|
| Booked | Created, advance paid |
| Delivered | Product handed to customer |
| Returned | On time return |
| Late Returned | After return date + extra charges |
| Completed | Payment & refund settled |
| Cancelled | Booking cancelled |

### 3.2 Payment flow

| Stage | Customer pays | Example (Rent ₹500, Deposit ₹1000) |
|-------|-----------------|-------------------------------------|
| Booking | 50% rent | ₹250 |
| Delivery | Remaining rent + deposit | ₹250 + ₹1000 = ₹1250 |
| Return | Deposit refund − extra days | ₹1000 − extra = refund |

### 3.3 Extra day logic

```
ExtraDays = ActualReturnDate − ReturnDate (if positive)
ExtraCharge = ExtraDays × ExtraChargePerDay
Refund = Deposit − ExtraCharge
Profit = TotalRent + ExtraCharge − Discounts
```

---

## Phase 4 — Operations & reports

| Report | Route | Purpose |
|--------|-------|---------|
| Today Delivery | `/reports/delivery` | Deliveries due today |
| Today Return | `/reports/return` | Returns due + extra charges |
| Invoice | `/invoice/:id` | Print / WhatsApp bill |

---

## Phase 5 — API architecture (every module)

```
Controller → IService → Service → IRepository → Repository → Dapper → SP
```

### Master endpoints

| Method | Endpoint |
|--------|----------|
| GET | `/api/masters/category` |
| GET | `/api/masters/category/{id}` |
| POST | `/api/masters/category` |
| PUT | `/api/masters/category` |
| DELETE | `/api/masters/category/{id}` |
| GET | `/api/masters/size` |
| GET | `/api/masters/color` |
| GET | `/api/masters/product` |
| POST | `/api/masters/product` |
| PUT | `/api/masters/product` |
| DELETE | `/api/masters/product/{id}` |

---

## Phase 6 — Role-based access (planned extension)

| Role | Masters | Booking | Reports | Payments |
|------|---------|---------|---------|----------|
| Super Admin | Full | Full | Full | Full |
| Admin | Full | Full | View | Partial |
| Accountant | View | View | Full | Full |

---

## Recommended daily operator flow

1. **Morning:** Open Dashboard → check Today Deliveries.
2. **Delivery:** Mark bookings Delivered → collect remaining rent + deposit.
3. **New rental:** Add Booking → verify product availability → collect advance.
4. **Returns:** Process return → system calculates extra days → refund deposit.
5. **Evening:** Run Today Return report → send WhatsApp reminders for tomorrow.

---

## Database dependency order

```
tblCompany → tblRole → tblUsers
         → tblCategory, tblSize, tblColor
         → tblProducts (FK to masters)
         → tblCustomers
         → tblBookings → tblBookingDetails, tblPayments, tblNotifications
```

---

## Files reference

| Layer | Location |
|-------|----------|
| SQL (base) | `Database/KidsFashionRentalDB.sql` |
| SQL (masters) | `Database/Masters_Migration.sql` |
| API | `Backend/KidsFashionRental.API/` |
| UI | `Frontend/kids-fashion-rental/` |
| This workflow | `docs/PROJECT_WORKFLOW.md` |
