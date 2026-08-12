namespace KidsFashionRental.API.Model;

public class BookingListModel
{
    public int BookingID { get; set; }
    public string BookingNo { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public DateTime BookingDate { get; set; }
    public DateTime DeliveryDate { get; set; }
    public DateTime ReturnDate { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal TotalRentAmount { get; set; }
    public decimal DepositAmount { get; set; }
    public decimal ExtraChargePerDay { get; set; }
    public decimal AdvanceAmount { get; set; }
    public decimal RemainingAmount { get; set; }
    public string BookingStatus { get; set; } = string.Empty;
    public string PaymentStatus { get; set; } = string.Empty;
    public int ExtraDays { get; set; }
    public decimal ExtraChargeAmount { get; set; }
    public decimal DamageDeductionAmount { get; set; }
    public decimal FinalRefundAmount { get; set; }
    public decimal FinalProfitAmount { get; set; }
    public int? CompanyID { get; set; }
}

public class TodayReturnReportModel
{
    public int BookingID { get; set; }
    public string BookingNo { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public DateTime ReturnDate { get; set; }
    public decimal DepositAmount { get; set; }
    public decimal ExtraChargePerDay { get; set; }
    public int ExtraDays { get; set; }
    public decimal ExtraChargeAmount { get; set; }
    public decimal DamageDeductionAmount { get; set; }
    public decimal FinalRefundAmount { get; set; }
    public decimal FinalProfitAmount { get; set; }
    public string BookingStatus { get; set; } = string.Empty;
    public DateTime? ActualReturnDate { get; set; }
}

public class BookingDetailItemModel
{
    public int ProductID { get; set; }
    public string ProductCode { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public string Size { get; set; } = string.Empty;
    public string Color { get; set; } = string.Empty;
    public decimal RentAmount { get; set; }
    public decimal DepositAmount { get; set; }
    public decimal DiscountPercent { get; set; }
    public decimal FinalRentAmount { get; set; }
    public bool IsFullSet { get; set; }
    public string? TopCode { get; set; }
    public string? TopSize { get; set; }
    public string? BottomCode { get; set; }
    public string? BottomSize { get; set; }
}

public class BookingCreateModel
{
    public int CompanyID { get; set; }
    public int BranchID { get; set; }
    public int CustomerID { get; set; }
    public int BookingCreatedBy { get; set; }
    public DateTime BookingDate { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public DateTime DeliveryDate { get; set; }
    public DateTime ReturnDate { get; set; }
    public int RentDays { get; set; }
    public decimal TotalRentAmount { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal DepositAmount { get; set; }
    public decimal AdvanceAmount { get; set; }
    public decimal RemainingAmount { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal ExtraChargePerDay { get; set; }
    public int ExtraDays { get; set; }
    public decimal ExtraChargeAmount { get; set; }
    public string BookingStatus { get; set; } = "Booked";
    public string PaymentStatus { get; set; } = "Partial";
    public string? Notes { get; set; }
    public List<BookingDetailItemModel> Items { get; set; } = [];
}

public class BookingUpdateModel
{
    public int BookingID { get; set; }
    public DateTime DeliveryDate { get; set; }
    public DateTime ReturnDate { get; set; }
    public int RentDays { get; set; }
    public decimal TotalRentAmount { get; set; }
    public decimal DepositAmount { get; set; }
    public decimal AdvanceAmount { get; set; }
    public decimal RemainingAmount { get; set; }
    public decimal TotalAmount { get; set; }
    public string BookingStatus { get; set; } = string.Empty;
    public string PaymentStatus { get; set; } = string.Empty;
    public string? Notes { get; set; }
}

public class BookingByIdModel
{
    public int BookingID { get; set; }
}

public class ReturnProcessModel
{
    public int BookingID { get; set; }
    public DateTime ActualReturnDate { get; set; }
    /// <summary>Deducted from deposit for product damage / issues at return.</summary>
    public decimal DamageDeductionAmount { get; set; }
    public string? ReturnNotes { get; set; }
}

public class AvailabilityRequestModel
{
    public string ProductCode { get; set; } = string.Empty;
    public DateTime DeliveryDate { get; set; }
    public DateTime ReturnDate { get; set; }
    public int? ExcludeBookingID { get; set; }
}

public class AvailabilityResponseModel
{
    public int Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public string? CustomerName { get; set; }
    public DateTime? deliveryDate { get; set; }
    public DateTime? returnDate { get; set; }
    public DateTime? nextAvailableDate { get; set; }
}

public class PaymentCreateModel
{
    public int CompanyID { get; set; }
    public int BookingID { get; set; }
    public string PaymentType { get; set; } = string.Empty;
    public string PaymentMode { get; set; } = string.Empty;
    public decimal PaymentAmount { get; set; }
    public string? TransactionNo { get; set; }
    public string? Notes { get; set; }
    public int CreatedBy { get; set; }
}

public class CustomerModel
{
    public int CustomerID { get; set; }
    public int CompanyID { get; set; }
    public int? BranchID { get; set; }
    public string? BranchName { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string ContactNo1 { get; set; } = string.Empty;
    public string? ContactNo2 { get; set; }
    public string? Address { get; set; }
    public string? City { get; set; }
    public string? Notes { get; set; }
}

public class ProductModel
{
    public int ProductID { get; set; }
    public int? CompanyID { get; set; }
    public int? BranchID { get; set; }
    public string? BranchName { get; set; }
    public string ProductCode { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public string CategoryName { get; set; } = string.Empty;
    public string Size { get; set; } = string.Empty;
    public string Color { get; set; } = string.Empty;
    public string? AgeGroup { get; set; }
    public decimal RentAmount { get; set; }
    public decimal DepositAmount { get; set; }
    public decimal DiscountPercent { get; set; }
    public int StandardRentalDays { get; set; }
    public decimal ExtraChargePerDay { get; set; }
    public string? ProductImage { get; set; }
    public bool IsAvailable { get; set; }
    public DateTime? NextAvailableDate { get; set; }
    public bool IsFullSet { get; set; }
    public string? TopCode { get; set; }
    public string? TopSize { get; set; }
    public string? BottomCode { get; set; }
    public string? BottomSize { get; set; }
}

public class DashboardCountsModel
{
    public int TotalCompanies { get; set; }
    public int TotalBranches { get; set; }
    public int TotalUsers { get; set; }
    public int TotalBookings { get; set; }
    public int TodayDeliveries { get; set; }
    public int TodayReturns { get; set; }
    public decimal PendingPayments { get; set; }
    public decimal PendingDeposit { get; set; }
    public decimal RefundDepositAmount { get; set; }
    public int AvailableProducts { get; set; }
    public int OverdueProducts { get; set; }
    public decimal TotalIncome { get; set; }
    public decimal TotalExpenses { get; set; }
    public decimal TotalDamageCuts { get; set; }
    public decimal NetProfit { get; set; }
}

public class TopProductModel
{
    public string ProductName { get; set; } = string.Empty;
    public int Total { get; set; }
}

public class TodayDeliveryDashModel
{
    public string BookingNo { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public DateTime DeliveryDate { get; set; }
    public decimal PendingAmount { get; set; }
    public string PaymentStatus { get; set; } = string.Empty;
    public string DeliveryStatus { get; set; } = string.Empty;
}

public class TodayReturnDashModel
{
    public int BookingID { get; set; }
    public string BookingNo { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public string CategoryName { get; set; } = string.Empty;
    public DateTime ReturnDate { get; set; }
    public decimal DepositAmount { get; set; }
    public string BookingStatus { get; set; } = string.Empty;
}

public class DashboardSummaryModel
{
    public DashboardCountsModel Counts { get; set; } = new();
    public List<ChartDataModel> MonthlyIncome { get; set; } = [];
    public List<ChartDataModel> BookingStatus { get; set; } = [];
    public List<TopProductModel> TopProducts { get; set; } = [];
    public List<TodayDeliveryDashModel> TodayDeliveries { get; set; } = [];
    public List<TodayReturnDashModel> TodayReturns { get; set; } = [];
}

public class ChartDataModel
{
    public string MonthLabel { get; set; } = string.Empty;
    public string StatusName { get; set; } = string.Empty;
    public decimal Income { get; set; }
    public int Total { get; set; }
}

public class ReportFilterModel
{
    public int? CompanyID { get; set; }
    public int? BranchID { get; set; }
    public int? FilterUserID { get; set; }
    public DateTime? ReportDate { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public string? Search { get; set; }
    public string? Status { get; set; }
}
