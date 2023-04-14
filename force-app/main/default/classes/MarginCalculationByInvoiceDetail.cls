public class MarginCalculationByInvoiceDetail implements  Database.Batchable<sObject>,Schedulable{
    
    /******************************************************
	 * Batch Class Name : MarginCalculationByInvoiceDetail
	 * Created By : Samiteon Team
	 * Purpose :  Class fetches the daily loaded Invoice details 
	 * and send them to it's helper class for further process.
	*******************************************************/
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'Select Id,Invoice__c,Invoice_Header__c,Opportunity__c,Invoice_Date__c,Item_cost__c,Item_Group__c,Item_Price__c,Account__c,Gross_Margin__c,Gross_Margin_percent__c from Invoice_Detail__c where CreatedDate = today';
        return Database.getQueryLocator(query);   
    }
    
    public void execute(Database.BatchableContext BC, List<Invoice_Detail__c> invoiceDetails){
        MarginCalculationByInvoiceDetailHelper marginCalculations = new MarginCalculationByInvoiceDetailHelper();
        marginCalculations.commissionCalculator(invoiceDetails);
        
    }
    
    public void finish(Database.BatchableContext BC){
        
    }
    
    public void execute(SchedulableContext sc){
        
        MarginCalculationByInvoiceDetail marginCalculationByInvoiceDetail= new MarginCalculationByInvoiceDetail(); 
        database.executeBatch(marginCalculationByInvoiceDetail);
        
    }
}