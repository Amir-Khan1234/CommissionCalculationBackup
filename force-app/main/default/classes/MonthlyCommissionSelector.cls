public class MonthlyCommissionSelector {
    public static List<Monthly_Commission__c> getMonthlyCommissionByEmployee(){
        return [Select Id,Name,Employee__c,EoY_Sales_Commission__c,Ancillary_Margin__c,Ancillary_Margin_Percent__c,Cost__c,Date__c,Eligible_Margin__c,
                Margin__c,Month__c,Not_Elligible_Margin__c,Price__c,Target_Met__c,Tile_Margin__c,Tile_Margin_Percent__c from Monthly_Commission__c
                where createdDate = LAST_YEAR];                                 	
    }
    public static List<Monthly_Commission__c> getMonthlyCommissionByEmployeeAndBreakDown(set<id> monthlyCommissionIds){
        return [Select Id,CreatedDate, Ancillary_Margin_Percent__c, Ancillary_Margin__c, Cost__c, Date__c, Eligible_Margin__c, Margin__c, Month__c, 
                Not_Elligible_Margin__c, Price__c, Target_Met__c, Tile_Margin_Percent__c, Tile_Margin__c, EoY_Sales_Commission__c, Employee__c, Tile_Sale__c, 
                Ancillary_Sale__c, Total_Invoice_Ancillary_Margin__c, Total_Invoice_Tile_Margin__c, Paid_Commission__c, Total_Commission__c, Previous_Eligible_Margin__c, 
                Previous_Tile_Margin__c, Previous_Ancillary_Margin__c, Previous_Total_Margin__c, Cumulative_Tile_Margin__c, Cumulative_Ancillary_Margin__c, 
                Cumulative_Eligible_Margin__c, Cumulative_Total_Margin__c, Payable_Commission__c, Previous_Total_Sale__c, Cumulative_Total_Sale__c, 
                Total_Sale__c  from Monthly_Commission__c where createdDate = THIS_YEAR AND Id in: monthlyCommissionIds];                                 	
    }
    public static List<Monthly_Commission__c> getMonthlyCommissionByEoySalesCommission(Set<id> eoySaelsCommissions){
        return [Select Id,name,CreatedDate, Ancillary_Margin_Percent__c, Ancillary_Margin__c,Actual_Commission_Earned__c, Cost__c, Date__c, Eligible_Margin__c, Margin__c, Month__c, 
                Not_Elligible_Margin__c, Price__c, Target_Met__c, Tile_Margin_Percent__c, Tile_Margin__c, EoY_Sales_Commission__c, Employee__c, Tile_Sale__c, 
                Ancillary_Sale__c, Total_Invoice_Ancillary_Margin__c, Total_Invoice_Tile_Margin__c, Paid_Commission__c, Total_Commission__c, Previous_Eligible_Margin__c, 
                Previous_Tile_Margin__c, Previous_Ancillary_Margin__c, Previous_Total_Margin__c, Cumulative_Tile_Margin__c, Cumulative_Ancillary_Margin__c, 
                Cumulative_Eligible_Margin__c, Cumulative_Total_Margin__c, Payable_Commission__c, Previous_Total_Sale__c, Cumulative_Total_Sale__c, 
                Total_Sale__c  from Monthly_Commission__c where createdDate = THIS_YEAR AND eoy_sales_commission__c in: eoySaelsCommissions];                                 	
    }
}