public class EoYSalesCommissionSelector {
     public static List<EoY_Sales_Commission__c> EoysalesCommissionsByUser(set<id> userIds){
        return [SELECT Id, OwnerId, Bonus__c, Eligible_Margin__c, EoY_adjustment__c, Over_All_Margin_percent__c, Paid_Commission__c, CreatedDate, Total_Commission__c, Total_Margin__c, Employee__c, Commission_Master__c, Name FROM EoY_Sales_Commission__c where Employee__c in: userIds and CreatedDate = THIS_YEAR];
    }
    public static Map<Id,EoY_Sales_Commission__c> GetEoysalesCommissions(set<id> salesCommissionId){
        Map<Id,EoY_Sales_Commission__c> eoySales = new Map<Id,EoY_Sales_Commission__c>([SELECT Id, OwnerId, Bonus__c, Eligible_Margin__c, 
                                                                                  EoY_adjustment__c, Over_All_Margin_percent__c, 
                                                                                  Paid_Commission__c, CreatedDate, Total_Commission__c, 
                                                                                  Total_Margin__c,Total_Margin_Without_Split__c, Employee__c, Commission_Master__c,Commission_Master__r.recordtype.name, Name 
                                                                                  FROM EoY_Sales_Commission__c where id in: salesCommissionId 
                                                                                  and CreatedDate = THIS_YEAR ]);
        return eoySales;
    }
     public static list<EoY_Sales_Commission__c> GetEoysalesCommissionsByUserId(id userId){
        return [SELECT Id, OwnerId, Bonus__c, Eligible_Margin__c,EoY_adjustment__c, Over_All_Margin_percent__c, 
                                                                                  Paid_Commission__c, CreatedDate, Total_Commission__c, 
                                                                                  Total_Margin__c, Employee__c, Commission_Master__c,Commission_Master__r.recordtype.name, Name 
                                                                                  FROM EoY_Sales_Commission__c where  employee__c =: userId order by CreatedDate desc ];
    }
}