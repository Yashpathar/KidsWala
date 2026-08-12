using KidsFashionRental.API.Model;

using System.Security.Claims;



namespace KidsFashionRental.API.Common;



public static class ControllerHelper

{

    public static int? GetUserId(ClaimsPrincipal user) =>

        int.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : null;



    public static string? GetRoleName(ClaimsPrincipal user) =>

        user.FindFirstValue(ClaimTypes.Role);



    public static int GetRoleId(ClaimsPrincipal user)

    {

        if (int.TryParse(user.FindFirstValue("RoleID"), out var rid) && rid > 0) return rid;

        return 0;

    }



    public static int GetCompanyId(ClaimsPrincipal user, int? fromQuery = null)
    {
        if (IsPlatformScope(user))
        {
            if (fromQuery is > 0) return fromQuery.Value;
            return 0;
        }

        if (int.TryParse(user.FindFirstValue("CompanyID"), out var cid) && cid > 0) return cid;
        return 0;
    }

    public static int GetBranchId(ClaimsPrincipal user, int? fromQuery = null)
    {
        if (IsPlatformScope(user) || IsCompanyScope(user))
        {
            if (fromQuery is > 0) return fromQuery.Value;
            return 0;
        }

        if (int.TryParse(user.FindFirstValue("BranchID"), out var bid) && bid > 0) return bid;
        return 0;
    }



    public static void ApplyCompanyId(CategoryModel model, int companyId)

    {

        if (model.CompanyID is null or 0) model.CompanyID = companyId;

    }



    public static void ApplyCompanyId(SizeModel model, int companyId)

    {

        if (model.CompanyID is null or 0) model.CompanyID = companyId;

    }



    public static void ApplyCompanyId(ColorModel model, int companyId)

    {

        if (model.CompanyID is null or 0) model.CompanyID = companyId;

    }



    public static void ApplyCompanyId(ProductMasterModel model, int companyId)

    {

        if (model.CompanyID <= 0) model.CompanyID = companyId;

    }



    public static string GetDataScope(ClaimsPrincipal user) =>

        user.FindFirstValue("DataScope") ?? DataScope.CompanyAll;



    public static bool IsPlatformScope(ClaimsPrincipal user) =>

        string.Equals(GetDataScope(user), DataScope.Platform, StringComparison.OrdinalIgnoreCase);



    public static bool IsCompanyScope(ClaimsPrincipal user) =>

        string.Equals(GetDataScope(user), DataScope.CompanyAll, StringComparison.OrdinalIgnoreCase);



    public static bool IsBranchAllScope(ClaimsPrincipal user) =>
        string.Equals(GetDataScope(user), DataScope.BranchAll, StringComparison.OrdinalIgnoreCase);

    public static bool IsBranchOwnScope(ClaimsPrincipal user)
    {
        var s = GetDataScope(user);
        return string.Equals(s, DataScope.BranchOwnOnly, StringComparison.OrdinalIgnoreCase)
            || string.Equals(s, DataScope.OwnBookingsOnly, StringComparison.OrdinalIgnoreCase);
    }

    public static int? GetFilterUserId(ClaimsPrincipal user) =>
        IsBranchOwnScope(user) ? GetUserId(user) : null;



    public static void ApplyReportFilter(ClaimsPrincipal user, ReportFilterModel filter, int? companyIdFromQuery = null, int? branchIdFromQuery = null)

    {

        var scope = GetDataScope(user);

        if (scope == DataScope.Platform)

        {

            filter.CompanyID = companyIdFromQuery is > 0 ? companyIdFromQuery : null;

            filter.BranchID = branchIdFromQuery is > 0 ? branchIdFromQuery : null;

            filter.FilterUserID = null;

            return;

        }



        filter.CompanyID = GetCompanyId(user, companyIdFromQuery);

        if (IsBranchOwnScope(user))
        {
            filter.BranchID = GetBranchId(user);
            filter.FilterUserID = GetUserId(user);
        }
        else if (IsBranchAllScope(user))
        {
            filter.BranchID = GetBranchId(user);
            filter.FilterUserID = null;
        }
        else if (IsCompanyScope(user))
        {
            filter.BranchID = branchIdFromQuery is > 0 ? branchIdFromQuery : null;
            filter.FilterUserID = null;
        }

    }



    public static bool CanUseBookingOps(ClaimsPrincipal user) => true;



    public static bool CanUseMasters(ClaimsPrincipal user) =>

        IsCompanyScope(user) || IsPlatformScope(user) || IsBranchAllScope(user);



    public static bool CanManagePlatform(ClaimsPrincipal user) => IsPlatformScope(user);

}


