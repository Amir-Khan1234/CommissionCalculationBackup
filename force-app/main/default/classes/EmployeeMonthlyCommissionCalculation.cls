/******* 
Batch Class Name :- EmployeeMonthlyCommissionCalculation
Created By :Samiteon Team 
Purpose :- Based on the monthly commission records updated by MarginCalculationByInvoiceDetail, 
This method will caluculate the monthly commission for reps every month.
*******/

public class EmployeeMonthlyCommissionCalculation implements Database.Batchable<sObject>{
    
    /******* 
    It will query all the monthly commission pass to the execute method       
    *******/ 
    public Database.QueryLocator start(Database.BatchableContext BC) {
        try {
            String query = 'Select Id,Employee__r.Profile.Name,Eligible_Margin__c,Cumulative_Tile_Margin__c,Cumulative_Eligible_Margin__c,Total_Invoice_Tile_Margin__c,Total_Sale__c,Cumulative_Ancillary_Margin__c,Cumulative_Total_Sale__c,Cumulative_Total_Margin__c,Total_Invoice_Ancillary_Margin__c,Previous_Total_Sale__c,Previous_Total_Margin__c,Previous_Tile_Margin__c,Previous_Eligible_Margin__c,Previous_Ancillary_Margin__c,EoY_Sales_Commission__r.Commission_Master__c,Employee__c,Paid_Commission__c,Total_Commission__c,Tile_Sale__c,Ancillary_Sale__c,EoY_Sales_Commission__c,Tile_Margin_Percent__c,Tile_Margin__c,Target_Met__c,Price__c,Not_Elligible_Margin__c,Margin__c,Month__c,Ancillary_Margin__c,Ancillary_Margin_Percent__c,Cost__c,Date__c from Monthly_Commission__c where(name like \'%Feb%\' or name like\'%mar%\') AND( createdDate = LAST_Month OR createdDate=THIS_MONTH) Order by CreatedDate ASC';
            return Database.getQueryLocator(query);   
        }
        catch(DmlException e) {
            ExceptionUtils.createExceptionLogV2('EmployeeMonthlyCommissionCalculation',e.getMessage(),e.getStackTraceString());
            return null;
        } 
    }
    
    /*******
    It will calculate monthly commission 
    *******/
    public void execute(Database.BatchableContext BC, list<Monthly_Commission__c> monthlyCommissions){
        Set<id> commissionMasterIds = new Set<Id>();
        Map<String,Map<Id,List<Monthly_Commission__c>>> monthlyCommissionsByUserByProfileName = new Map<String,Map<Id,List<Monthly_Commission__c>>>();
        Map<Id,Commission_Master__c> commissionMasterById = new Map<Id,Commission_Master__c>();
        Map<Id,List<Commission_Tier__c>> commissionTierByCommissionMaster = new Map<Id,List<Commission_Tier__c>>();
        Map<Id,Map<String,Decimal>> targetByTypeByCommissionMaster = new Map<Id,Map<String,Decimal>>();
        Map<Id,List<EoY_GP_Target_Bonus__c>> eoyGpTargetBonusByCommissionMaster = new Map<Id,List<EoY_GP_Target_Bonus__c>>(); 
        List<Monthly_Commission__c> monthlyCommissionsToBeUpdated = new List<Monthly_Commission__c>();
        
        for(Monthly_Commission__c monthlyCommission : monthlyCommissions){
            commissionMasterIds.add(monthlyCommission.EoY_Sales_Commission__r.Commission_Master__c);
            monthlyCommission.Total_Sale__c = monthlyCommission.Tile_Sale__c + monthlyCommission.Ancillary_Sale__c;
            monthlyCommission.Margin__c = monthlyCommission.Total_Invoice_Ancillary_Margin__c + monthlyCommission.Total_Invoice_Tile_Margin__c;
            monthlyCommission.Cumulative_Total_Margin__c = monthlyCommission.Margin__c + monthlyCommission.Previous_Total_Margin__c;
            monthlyCommission.Cumulative_Ancillary_Margin__c = monthlyCommission.Total_Invoice_Ancillary_Margin__c + monthlyCommission.Previous_Ancillary_Margin__c;
            monthlyCommission.Cumulative_Tile_Margin__c = monthlyCommission.Total_Invoice_Tile_Margin__c + monthlyCommission.Previous_Tile_Margin__c;
            monthlyCommission.Cumulative_Total_Sale__c = monthlyCommission.Total_Sale__c + monthlyCommission.Previous_Total_Sale__C;
            monthlyCommission.Cumulative_Eligible_Margin__c = monthlyCommission.Eligible_Margin__c + monthlyCommission.Previous_Eligible_Margin__c;
            if(monthlyCommissionsByUserByProfileName.containsKey(monthlyCommission.employee__r.profile.name)){
                if(monthlyCommissionsByUserByProfileName.get(monthlyCommission.employee__r.profile.name).containskey(monthlyCommission.Employee__c)){
                    monthlyCommissionsByUserByProfileName.get(monthlyCommission.employee__r.profile.name).get(monthlyCommission.Employee__c).add(monthlyCommission);
                }
                else{
                    monthlyCommissionsByUserByProfileName.get(monthlyCommission.employee__r.profile.name).put(monthlyCommission.Employee__c,new List<Monthly_Commission__c>{monthlyCommission});  
                }
            }
            else{
                monthlyCommissionsByUserByProfileName.put(monthlyCommission.employee__r.profile.name,new Map<id,List<Monthly_Commission__c>>{monthlyCommission.Employee__c => new List<Monthly_Commission__c>{monthlyCommission}});
            }
            
        }
        
        commissionMasterById = CommissionMasterSelector.getCommissionMasterById(commissionMasterIds);
        commissionTierByCommissionMaster = DataFactory.getsObjectsByFieldId(CommissionTierSelector.getCommissionTierByCommissionMasters(commissionMasterIds),'Commission_Master__c');
        eoyGpTargetBonusByCommissionMaster = DataFactory.getsObjectsByFieldId(EoYGPBonusTargetSelector.getEoYGPBonusTargetByCommissionMasters(commissionMasterIds),'Commission_Master__c');        
        
        System.debug('\n----'+GPPercentTargetSelector.getGPPercentTargetByCommissionMasters(commissionMasterIds));
        
        for(GP_Percent_Target__c gpPercentTarget : GPPercentTargetSelector.getGPPercentTargetByCommissionMasters(commissionMasterIds)){
            if(targetByTypeByCommissionMaster.containsKey(gpPercentTarget.Commission_Master__c)){
                targetByTypeByCommissionMaster.get(gpPercentTarget.Commission_Master__c).put(gpPercentTarget.Type__c,gpPercentTarget.Target_Percent__c);
            }
            else{
                targetByTypeByCommissionMaster.put(gpPercentTarget.Commission_Master__c,new Map<String,Decimal>{gpPercentTarget.Type__c => gpPercentTarget.Target_Percent__c});
            }
        }
        
        Map<Id,List<Monthly_Commission__c>> monthlyCommissionsByUser = new Map<Id,List<Monthly_Commission__c>>();
        for(String profileName : monthlyCommissionsByUserByProfileName.keySet()){
            if(profileName == CommissionCalculatorConstants.REPTYPEAD){
                monthlyCommissionsByUser = monthlyCommissionsByUserByProfileName.get(profileName);
                monthlyCommissionsToBeUpdated.addAll(EmployeeMonthlyCommissionAnDCalculation.monthlyCommissionByUserCalculation(monthlyCommissionsByUser,commissionMasterById,commissionTierByCommissionMaster));
            }
        }
        
        if(!monthlyCommissionsToBeUpdated.isEmpty()){
            update monthlyCommissionsToBeUpdated;
        }
    }
    
    public void finish(Database.BatchableContext BC){
        
    }
}