public without sharing class MyCommissionController {
    @AuraEnabled
    public static User getLoggedInUser(){
        try{
            return UserSelector.getUsersByUserIds(new Set<Id>{userInfo.getUserId()}).values()[0];
        }
        catch(DmlException e){
            System.debug('Exp===>'+e.getMessage());
            ExceptionUtils.createExceptionLogV2('MyCommissionController',e.getMessage(),e.getStackTraceString());
            return NULL;
        }
    }
    @AuraEnabled(cacheable = true)
    public static MCCommissionData getMonthlyBreakDown(user userDetail){
        try{
            system.debug('User Detail==>'+userDetail.id);
            MCCommissionData myCommissionData = new MCCommissionData();
            myCommissionData.EOYsalesCommission = EoYSalesCommissionSelector.GetEoysalesCommissionsByUserId(userDetail.id);
            myCommissionData.monthlyCommission = MonthlyCommissionSelector.getMonthlyCommissionByEoySalesCommission(DataFactory.getFieldIdFromsObjects(myCommissionData.EOYsalesCommission , 'Id'));
            myCommissionData.monthlyBreakDown =  MonthlyBreakdownSelector.getMonthlyBreakDownByMonthlyCommission(DataFactory.getFieldIdFromsObjects(myCommissionData.monthlyCommission , 'Id'));
            
            
            system.debug('myCommissionData.monthlyBreakDown==>'+ myCommissionData.monthlyBreakDown);
            system.debug('myCommissionData.monthlyCommission==>'+ myCommissionData.monthlyCommission);
            system.debug('myCommissionData.EOYsalesCommission==>'+ myCommissionData.EOYsalesCommission);
            return myCommissionData;
        }
        catch(DmlException e){
           ExceptionUtils.createExceptionLogV2('MyCommissionController',e.getMessage(),e.getStackTraceString());
            return new MCCommissionData();
        }
    }  
    class MCCommissionData{
        
        @AuraEnabled public  list<monthly_breakDown__c> monthlyBreakDown{get;set;}
        @AuraEnabled public  list<monthly_commission__c> monthlyCommission{get;set;}
        @AuraEnabled public  list<EOY_sales_commission__c> EOYsalesCommission{get;set;}
    }
    
}