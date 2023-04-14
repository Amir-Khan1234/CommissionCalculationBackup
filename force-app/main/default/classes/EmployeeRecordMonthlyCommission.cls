/************************************************ 
Batch Class Name :- EmployeeRecordMonthlyCommission
Created By : Samiteon Team 
Purpose :- It will create one record every month of financial year at date 1 for active user for which we have to calculate commission.

****************************/


public class EmployeeRecordMonthlyCommission implements Database.Batchable<sObject>,schedulable{
    
    /****************** This method query all the EoY sales Commission of financial year and pass to the execute method  *********************/
    public Database.QueryLocator start(Database.BatchableContext BC) {
        
        String listEoYSalesCommission = 'SELECT Id,Name,OwnerId, Bonus__c, Eligible_Margin__c, EoY_adjustment__c, Over_All_Margin_percent__c, Paid_Commission__c, CreatedDate, Total_Commission__c, Total_Margin__c, Employee__c, Commission_Master__c FROM EoY_Sales_Commission__c where createdDate = THIS_YEAR';
        return Database.getQueryLocator(listEoYSalesCommission);  
    }
    /******************* 
This method inserts monthly Commission record of user for whome we have to calculate commission.     
***************************/
    public void execute(Database.BatchableContext BC, list<EoY_Sales_Commission__c> listEoYSalesCommission){
        System.debug('listEoYSalesCommission ::'+listEoYSalesCommission);
        try{
            List<Monthly_Commission__c> listMonthlyCommission = new List<Monthly_Commission__c>();
            Map<String,String> eoySalesCommissionByEmployee = new Map<String,String>();
            for(EoY_Sales_Commission__c eoySalesCommission : listEoYSalesCommission){
                if(eoySalesCommission.Employee__c != null){
                    Monthly_Commission__c monthlyCommission = new Monthly_Commission__c();
                    monthlyCommission.Name = eoySalesCommission.Name;
                    monthlyCommission.Employee__c = eoySalesCommission.Employee__c;
                    monthlyCommission.EoY_Sales_Commission__c = eoySalesCommission.Id;
                    listMonthlyCommission.add(monthlyCommission);                    
                }
            }
            System.debug('listMonthlyCommission ::'+listMonthlyCommission);
            insert listMonthlyCommission; 
        }
        catch(DmlException e) {
            ExceptionUtils.createExceptionLogV2('Monthly_Commission__c',e.getMessage(),e.getStackTraceString());
        }
    }
    public static void execute(System.SchedulableContext bc){
        
    }
    public void finish(Database.BatchableContext BC){
        
    }
}