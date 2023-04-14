/************************************************************************* 
Batch Class Name :- CommissionMasterRecordTypeBases
Created By : Samiteon Team
Purpose :- It will create one record for financial year for each sales profile .
************************************************************************/
public class CommissionMasterRecordTypeBases implements Database.Batchable<sObject>,Schedulable{  
    
    /******************************************************************************* 
It will query the all the record type of commission master and pass to the execute method  
********************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext BC) {
        
        String commissionMasterRecordtype = 'Select Id,Name from RecordType Where SobjectType=\'Commission_Master__c\'';
        return Database.getQueryLocator(commissionMasterRecordtype);   
    }
    /********************************************************************************* 
It will create commission master record on profile bases.
*********************************************************************************/
    public void execute(Database.BatchableContext BC, List<RecordType> commissionMasterRecordtype){
        System.debug('Entry: commissionMasterRecordtype ::'+commissionMasterRecordtype);
        Map<string, Target_for_EoY_adjustment__mdt > targetEoYAdjustmentByProfile = new Map<string, Target_for_EoY_adjustment__mdt>();
        Map<string, Commission_under_target__mdt > commissionUnderTargetByProfile = new Map<string, Commission_under_target__mdt>();
        Map<string, Percentage_Less_then_retroactive_EOY_adj__mdt  > percentageLessThenRetroactiveByProfile = new Map<string, Percentage_Less_then_retroactive_EOY_adj__mdt>();
        
        /******************************************
Target for EoY adjustment metadata.
******************************************/
        
        for(Target_for_EoY_adjustment__mdt targetEoy :TargetForEoYAdjustmentMetadataSelector.getEoYAdjustmentTarget()){
            
            targetEoYAdjustmentByProfile.put(targetEoy.Profile_Type__c , targetEoy);
        }
        
        /******************************************
Commission under target metadata.
******************************************/
        
        for(Commission_under_target__mdt commissionUnderTarget :CommissionUnderTargerMetadataSelector.getCommissionPercentUnderTarget()){
            
            commissionUnderTargetByProfile.put(commissionUnderTarget.Profile_Type__c , commissionUnderTarget);
        }
        
        /******************************************
Percentage less than retroactive EoY adjustment metadata.
******************************************/
        
        for(Percentage_Less_then_retroactive_EOY_adj__mdt percentageLessRectroActive :PercentUnderRetEoYAdjMetaDataSelector.getTargetUnderEOYAdjustment()){
            
            percentageLessThenRetroactiveByProfile.put(percentageLessRectroActive.Profile_Type__c , percentageLessRectroActive);
        }
        //targetEoYAdjustmentByProfile = datafactory.getsObjectsByFieldId(TargetForEoYAdjustmentMetadataSelector.getEoYAdjustmentTarget(), 'Profile_Type__c');
        //commissionUnderTargetByProfile = datafactory.getsObjectsByFieldId(CommissionUnderTargerMetadataSelector.getCommissionPercentUnderTarget(), 'Profile_Type__c');
        //percentageLessThenRetroActiveByProfile = datafactory.getsObjectsByFieldId(PercentUnderRetEoYAdjMetaDataSelector.getTargetUnderEOYAdjustment(), 'Profile_Type__c');
        Map<String,commission_master__c> commissionMasters =  new Map<String,commission_master__c>();
        for(RecordType recordTypeForProfile : commissionMasterRecordtype){
            commission_master__c commissionmasterInstance = new commission_master__c();
            commissionmasterInstance.recordTypeId = recordTypeForProfile.id;
            if(targetEoYAdjustmentByProfile.containskey(recordTypeForProfile.name) || commissionUnderTargetByProfile.containskey(recordTypeForProfile.name) || percentageLessThenRetroActiveByProfile.containskey(recordTypeForProfile.name))
            { 
                if(targetEoYAdjustmentByProfile.containskey(recordTypeForProfile.name)){
                    commissionmasterInstance.Target_for_EoY_adjustment__c =targetEoYAdjustmentByProfile.get(recordTypeForProfile.name).Commission_Percentage__c;
                }
                if(commissionUnderTargetByProfile.containskey(recordTypeForProfile.name)){
                    commissionmasterInstance.Commission_percent_under_target__c =commissionUnderTargetByProfile.get(recordTypeForProfile.name).Commission_Percentage__c;
                }
                if(percentageLessThenRetroActiveByProfile.containskey(recordTypeForProfile.name)){
                    commissionmasterInstance.Percent_below_retroactive_EoY_Adj__c =percentageLessThenRetroactiveByProfile.get(recordTypeForProfile.name).Commission_Percentage__c;   
                }
            }
            commissionMasters.put(recordTypeForProfile.name,commissionmasterInstance);   
        }
        try{
            System.debug('commissionMasters.values() :'+commissionMasters.values());
            insert commissionMasters.values();
        }
        catch(DmlException e) {
            ExceptionUtils.createExceptionLogV2('CommissionMasterRecordTypeBases',e.getMessage(),e.getStackTraceString());   
        }
        
        /**********************************************************
after DML all the commission master next are to make the commision tier,Gp percent target,EoY Gp target Bonus.
***********************************************************/
        
        List<Commission_Tier__c> commissionTierList = new List<Commission_Tier__c>();
        List<GP_percent_target__c> gpPercentTargetList = new List<GP_percent_target__c>();
        List<EoY_GP_Target_Bonus__c> EoyPercenttargetList = new List<EoY_GP_Target_Bonus__c>();
        for(Tier_Levels__mdt tierLevel : TierLevelSelector.getTierLevel()){
            System.debug('Tier_Levels__mdt :'+tierLevel);
            Commission_Tier__c tierLevelInstance = new Commission_Tier__c();
            If(commissionMasters.containsKey(tierLevel.Profile_Type__c)){
                tierLevelInstance.lower_Amount__c = tierLevel.lower_limit__c;
                tierLevelInstance.upper_Amount__c = tierLevel.upper_limit__c;
                tierLevelInstance.Profile_Type__c = tierLevel.Profile_Type__c;
                tierLevelInstance.tier_type__c = tierLevel.tier_type__c;
                tierLevelInstance.commission_percentage__c= tierLevel.commission_percentage__c;
                //System.debug('tierLevel.Profile_Type__c :'+tierLevel.Profile_Type__c);
                tierLevelInstance.commission_master__c= commissionMasters.get(tierLevel.Profile_Type__c).id;  
                commissionTierList.add(tierLevelInstance); 
                system.debug('commission Tier Record  ====>'+tierLevelInstance);
            }           
        }
        system.debug('commission Tier ALL Record  ====>'+commissionTierList);
        for(GP_Percentage_target__mdt GpPercent : GPPercentTargetMetadataSelector.getGpPercentTargetMetadata()){
            System.debug('GP_Percentage_target__mdt :'+GpPercent);
            GP_percent_target__c GpPercentInstance = new GP_percent_target__c();
            if(commissionMasters.containsKey(GpPercent.Profile_Type__c)){
                GpPercentInstance.type__c = GpPercent.product_type__c;
                GpPercentInstance.Target_Percent__c = GpPercent.commission_percentage__c;
                GpPercentInstance.Profile_Type__c = GpPercent.Profile_Type__c;
                //System.debug('GpPercent.Profile_Type__c :'+GpPercent.Profile_Type__c);
                GpPercentInstance.commission_master__c= commissionMasters.get(GpPercent.Profile_Type__c).id; 
                gpPercentTargetList.add(GpPercentInstance);            
            }            
        }
        
        for(EOY_Bonus__mdt EoYBonus : EoYBonusSelector.getEoyBonusMetadata()){
            System.debug('EOY_Bonus__mdt :'+EoYBonus);
            EoY_GP_Target_Bonus__c EoyPercentTargetInstance = new EoY_GP_Target_Bonus__c();
            if(commissionMasters.containsKey(EoYBonus.Profile_Type__c)){
                EoyPercentTargetInstance.amount__c = EoYBonus.amount__c;
                EoyPercentTargetInstance.Bonus__c = EoYBonus.Bonus__c;
                EoyPercentTargetInstance.Profile_Type__c = EoYBonus.Profile_Type__c;
                //System.debug('EoYBonus.Profile_Type__c :'+EoYBonus.Profile_Type__c);
                EoyPercentTargetInstance.commission_master__c= commissionMasters.get(EoYBonus.Profile_Type__c).id;   
                system.debug('Eoy sales commission Record : '+EoyPercentTargetInstance);
                EoyPercenttargetList.add(EoyPercentTargetInstance);           
            }
        }
        try{
            System.debug('commissionTierList :'+JSON.serializePretty(commissionTierList));
            System.debug('gpPercentTargetList :'+JSON.serializePretty(gpPercentTargetList));
            System.debug('Eoy sales commission Record :'+EoyPercenttargetList.size() +'EoyPercenttargetList :'+JSON.serializePretty(EoyPercenttargetList));
            insert commissionTierList;
            insert gpPercentTargetList;
            insert EoyPercenttargetList;
            
        }
        catch(DmlException e) {
            ExceptionUtils.createExceptionLogV2('Commission_Tier__c',e.getMessage(),e.getStackTraceString());
        }
    }
    public static void execute(System.SchedulableContext bc){
        
    }
    public void finish(Database.BatchableContext BC){
    }
}