public class MarginCalculationByInvoiceDetailHelper {
    
    /************************************************
	* Batch Class Name : MarginCalculationByInvoiceDetailHelper
	* Created By : Samiteon Team 
	=> we'll be segregating our data and passing them 
	to different methods.  

	=> Evalute the invoice detail margins, get split details and
	get commission structures
	and store the all data in different Maps

	=>With all this data we'll finally 
	calculate the amount (accroding to profile) on which the final 
	monthly commission will be calculated

	* NOTE :- Edit at your own risk.

	*************************************************/
    
    Map<String,Map<Id,InvoiceMargins>> calculatedMarginsByOpportunityIdByMonth = new Map<String,Map<Id,InvoiceMargins>>();
    Map<String,Map<Id,InvoiceMargins>> calculatedMarginsByAccountIdByMonth = new Map<String,Map<Id,InvoiceMargins>>();
    Map<String,Map<Id,List<SplitDetails>>> splitsByOpportunityIdByProfileName = new Map<String,Map<Id,List<SplitDetails>>>();
    Map<String,Map<Id,List<SplitDetails>>> splitsByAccountIdByProfileName = new Map<String,Map<Id,List<SplitDetails>>>();
    Map<String, Map<id,monthly_commission__c>> monthlyCommissionByIdByProfileName = new Map<String,Map<id,monthly_commission__c>>();
    Map<Id,List<Monthly_Breakdown__c>> monthlyBreakdownsByOpportunity = new Map<Id,List<Monthly_Breakdown__c>>();
    Map<Id,List<Monthly_Breakdown__c>> monthlyBreakdownsByAccount = new Map<Id ,List<Monthly_Breakdown__c>>();
    Map<Id,Monthly_Commission__c> monthlyCommissionsById = new Map<Id,Monthly_Commission__c>();
    Map<Id,Commission_Master__c> commissionMasterById = new Map<Id,Commission_Master__c>();
    Map<Id,List<Commission_Tier__c>> commissionTiersByCommissionMaster = new Map<Id,List<Commission_Tier__c>>();
    Map<Id,Map<String,Decimal>> targetByTypeByCommissionMaster = new Map<Id,Map<String,Decimal>>();
    Map<Id,List<EoY_GP_Target_Bonus__c>> eoyGPBonusTarget = new Map<Id,List<EoY_GP_Target_Bonus__c>>();
    List<Monthly_Breakdown__c> monthlyBreakdownsToBeUpserted = new List<Monthly_Breakdown__c>();
    set<String> profileNames = new set<String>(); 
    Set<Id> opportunityIds = new Set<Id>();
    Set<Id> accountIds = new Set<Id>();    
    
    public void commissionCalculator(List<Invoice_detail__c> invoicesDetails){   
        
        /************************************************************
* This is the base method that further calls other methods
* in the class to perform all the necessory tasks that
* will create a final monthly commissions data that will be
* updated in the end.
************************************************************/
        
        Set<Id> commissionMasters = new Set<Id>();     
        system.debug('invoicesDetails===>'+invoicesDetails);
        populateCommissionMarginsSchema(invoicesDetails);
        populateSplitsSchema();
        this.monthlyCommissionsById = getMonthlyCommissionViaNameAndEmployee();
        commissionMasters = getCommissionMasterIdsFromMonthlyCommission(monthlyCommissionsById.values());
        pupulateCommissionsSchema(commissionMasters);
        populateMonthlyBreakdownSchema(this.monthlyCommissionsById.keyset());
        populateProfileNames();
        calculateMonthlyBreakdowns();
        upsertMonthlyBreakdown();
        populateMonthlyCommissionByIdByProfileName(this.monthlyCommissionsById.keyset());       
        updateMonthlyCommission();
    }
    
    public void populateCommissionMarginsSchema(List<Invoice_detail__c> invoicesDetails){
        
        /******************************************************************************************
        This method segregates the invoice according to opportunity and account and then segregates 
        them as per their Month and year of invoice then
        calculates margins on every invoice detail, cumulates the result if different invoices
        exist on the same opportunity/account in a month of the year  then populates the 
        calculatedMarginsByOpportunityIdByMonth and calculatedMarginsByAccountIdByMonth 
        ********************************************************************************************/
        
        System.debug('Entring:populateCommissionMarginsSchem => invoicesDetails'+invoicesDetails);
        for(Invoice_detail__c invoiceDetail : invoicesDetails)
        {
            system.debug('InvoiceDetail.Invoice_Date__c.month()====>'+InvoiceDetail.Invoice_Date__c.month());
            String invoiceMonthAndYear = CommissionCalculatorConstants.MONTHBYNUMBER.get(InvoiceDetail.Invoice_Date__c.month())+ '-'+ String.valueOf(invoiceDetail.Invoice_Date__c.year());
            if(invoiceDetail.Opportunity__c != null)
            {
                if(this.calculatedMarginsByOpportunityIdByMonth.containsKey(invoiceMonthAndYear))
                {
                    if(this.calculatedMarginsByOpportunityIdByMonth.get(invoiceMonthAndYear).containsKey(invoiceDetail.Opportunity__c))
                    {
                        this.calculatedMarginsByOpportunityIdByMonth.get(invoiceMonthAndYear).put(invoiceDetail.Opportunity__c,
                                                                                                  this.calucluateInvoiceMargins(this.calculatedMarginsByOpportunityIdByMonth.get(invoiceMonthAndYear).get(invoiceDetail.Opportunity__c),
                                                                                                                                invoiceDetail));    
                    }
                    else {
                        this.opportunityIds.add(invoiceDetail.Opportunity__c);
                        this.calculatedMarginsByOpportunityIdByMonth.get(invoiceMonthAndYear).put(invoiceDetail.Opportunity__c,
                                                                                                  this.calucluateInvoiceMargins(New InvoiceMargins(),
                                                                                                                                invoiceDetail));    
                    }
                }
                else {
                    this.opportunityIds.add(invoiceDetail.Opportunity__c);
                    this.calculatedMarginsByOpportunityIdByMonth.put(invoiceMonthAndYear , 
                                                                     new Map<Id,InvoiceMargins>{invoiceDetail.Opportunity__c => this.calucluateInvoiceMargins(New InvoiceMargins(),
                                                                                                                                                              invoiceDetail)});
                }
            }
            else 
            {
                if(this.calculatedMarginsByAccountIdByMonth.containsKey(invoiceMonthAndYear))
                {
                    if(this.calculatedMarginsByAccountIdByMonth.get(invoiceMonthAndYear).containsKey(invoiceDetail.Account__c))
                    {
                        this.calculatedMarginsByAccountIdByMonth.get(invoiceMonthAndYear).put(invoiceDetail.Account__c,
                                                                                              this.calucluateInvoiceMargins(this.calculatedMarginsByAccountIdByMonth.get(invoiceMonthAndYear).get(invoiceDetail.Account__c),
                                                                                                                            invoiceDetail));    
                    }
                    else {
                        this.accountIds.add(invoiceDetail.Account__c);
                        this.calculatedMarginsByAccountIdByMonth.get(invoiceMonthAndYear).put(invoiceDetail.Account__c,
                                                                                              this.calucluateInvoiceMargins(New InvoiceMargins(),
                                                                                                                            invoiceDetail));    
                    }
                }
                else {
                    this.accountIds.add(invoiceDetail.Account__c);
                    this.calculatedMarginsByAccountIdByMonth.put(invoiceMonthAndYear , 
                                                                 new Map<Id,InvoiceMargins>{invoiceDetail.Account__c => this.calucluateInvoiceMargins(New InvoiceMargins(),
                                                                                                                                                      invoiceDetail)});
                }
            }
        }
        
       
        System.debug('Exit:populateCommissionMarginsSchema =>  calculatedMarginsByOpportunityIdByMonth::'+
                     this.calculatedMarginsByOpportunityIdByMonth+'\n calculatedMarginsByAccountIdByMonth::'+
                     this.calculatedMarginsByAccountIdByMonth);
    }
    
    public InvoiceMargins calucluateInvoiceMargins(InvoiceMargins preEvaluatedInvoice , Invoice_detail__c invoiceDetail){
        
        /********************************************************
        * This method calculates the margins of invoices and
        * returns the calculated result
        ********************************************************/
        
        preEvaluatedInvoice.totalSales += invoiceDetail.Item_Price__c;
        if(invoiceDetail.Item_Group__c == commissionCalculatorconstants.itemGroupTile)
        {
            preEvaluatedInvoice.tileSales += invoiceDetail.Item_Price__c;
            preEvaluatedInvoice.tileMargin += (invoiceDetail.Item_Price__c - invoiceDetail.Item_cost__c);
            preEvaluatedInvoice.tileMarginPercentage = ((preEvaluatedInvoice.tileMargin /preEvaluatedInvoice.tileSales) *100).setScale(2);
        }
        else
        {
            preEvaluatedInvoice.AncillarySales += invoiceDetail.Item_Price__c;
            preEvaluatedInvoice.AncillaryMargin += (invoiceDetail .Item_Price__c - invoiceDetail.Item_cost__c);
            preEvaluatedInvoice.ancillaryMarginPercentage = ((preEvaluatedInvoice.AncillaryMargin / preEvaluatedInvoice.AncillarySales) *100).setScale(2);
        }
        return preEvaluatedInvoice;
    } 
    
    public void populateSplitsSchema(){
        
        /*******************************************************
        * This specific method fetches the split portions from
        * opportunity splits and creates a Map of opportunity id
        * and split Details based on Profiles.
        *******************************************************/
        
        System.debug('Entring:populateSplitsSchema');
        Set<Id> oppotunityIdsToBeRemovedFromOpportunityIds = new Set<Id>();
        for(OpportunitySplit split :OpportunitySplitSelector.getOpportunitySplitByOpportunityWithCalculateCommissionEnable(this.opportunityIds)){            
            if(this.splitsByOpportunityIdByProfileName.containsKey(split.SplitOwner.Profile.Name))
            {
                if(this.splitsByOpportunityIdByProfileName.get(split.SplitOwner.Profile.Name).containsKey(split.opportunityId))
                {
                    this.splitsByOpportunityIdByProfileName.get(split.SplitOwner.Profile.Name).get(split.opportunityId).add(New SplitDetails(split.SplitOwnerId,split.SplitOwner.Profile.Name,split.SplitPercentage));   
                }
                else {
                    this.splitsByOpportunityIdByProfileName.get(split.SplitOwner.Profile.Name)
                        .put(split.opportunityId ,New List<SplitDetails>{new SplitDetails(split.SplitOwnerId,split.SplitOwner.Profile.Name,split.SplitPercentage)});   
                }
            }
            else {
                this.splitsByOpportunityIdByProfileName.put(split.SplitOwner.Profile.Name ,
                                                            new Map<Id,List<SplitDetails>>{split.OpportunityId => 
                                                                New List<SplitDetails>{New SplitDetails(split.SplitOwnerId,split.SplitOwner.Profile.Name,split.SplitPercentage)}});
            }
            oppotunityIdsToBeRemovedFromOpportunityIds.add(split.opportunityId);
        }
        this.opportunityIds.removeAll(oppotunityIdsToBeRemovedFromOpportunityIds);
        updateSplitsByOpportunityIdByProfileNameWithRemainingOpportunities();
        updateSplitsByAccountIdByProfileName();
        System.debug('Exit:populateSplitsSchema =>  splitsByOpportunityIdByProfileName::'+
                     this.splitsByOpportunityIdByProfileName);
    }
    
    public void updateSplitsByOpportunityIdByProfileNameWithRemainingOpportunities(){
        
        /******************************************************** 
* If there is any opportunity exists in the data 
* whose splits does not exist, for thos opportunities
* this method will fetch their owner's details and 
* updates the same opportunity same map modified by 
* oppotunityIdsToBeRemovedFromOpportunityIds with split
* portion of 100% for remaining opportunities.
********************************************************/
        
        System.debug('Entring:updateSplitsByOpportunityIdByProfileNameWithRemainingOpportunities');
        for(Opportunity opportunity :OpportunitySelector.getOpportunitiesByIdWithCalculateCommissionEnable(this.opportunityIds)){ 
            if(this.splitsByOpportunityIdByProfileName.containsKey(opportunity.owner.profile.Name)){
                if(this.splitsByOpportunityIdByProfileName.get(opportunity.owner.profile.Name).containsKey(opportunity.Id)){
                    this.splitsByOpportunityIdByProfileName.get(opportunity.owner.profile.Name).get(opportunity.Id).add(New SplitDetails(opportunity.OwnerId,opportunity.owner.profile.name,CommissionCalculatorConstants.MARGINPERCENTFOROPPWITHNOSPLITS));   
                } 
                else{
                    this.splitsByOpportunityIdByProfileName.get(opportunity.owner.profile.Name)
                        .put(opportunity.Id ,New List<SplitDetails> {new SplitDetails(opportunity.OwnerId,opportunity.owner.profile.name,CommissionCalculatorConstants.MARGINPERCENTFOROPPWITHNOSPLITS)});   
                }
            }
            else {
                this.splitsByOpportunityIdByProfileName
                    .put(opportunity.owner.profile.Name ,new Map<Id,List<SplitDetails>>{opportunity.Id => New List<SplitDetails>{New SplitDetails(opportunity.OwnerId,opportunity.owner.profile.name,CommissionCalculatorConstants.MARGINPERCENTFOROPPWITHNOSPLITS)}});
            }
        }
        System.debug('Exit:updateSplitsByOpportunityIdByProfileNameWithRemainingOpportunities');
    }
    
    public void updateSplitsByAccountIdByProfileName(){
        
        /******************************************************** 
        * This method does the same operations as
        * updateSplitsByOpportunityIdByProfileNameWithRemainingOpportunities
        * method but for accounts and creates a Map  of account id
        * and split Details based on Profiles.
        ********************************************************/        
        
        System.debug('Entring:updateSplitsByAccountIdByProfileName');
        for(Account account : AccountSelector.getAccountsByIdsWithCalculateCommissionEnable(this.accountIds)){
            if(this.splitsByAccountIdByProfileName.containsKey(account.Owner.Profile.Name)){
                if(this.splitsByAccountIdByProfileName.get(account.Owner.Profile.Name).containsKey(account.Id)){
                    this.splitsByAccountIdByProfileName.get(account.Owner.Profile.Name).get(account.Id).add(New SplitDetails(account.OwnerId,account.Owner.Profile.Name,CommissionCalculatorConstants.MARGINPERCENTFORACCOUNTS));   
                } 
                else{
                    this.splitsByAccountIdByProfileName.get(account.Owner.Profile.Name)
                        .put(account.Id ,New  List<SplitDetails> {new SplitDetails(account.OwnerId,account.Owner.Profile.Name,CommissionCalculatorConstants.MARGINPERCENTFORACCOUNTS)});   
                }
            }
            else {
                this.splitsByAccountIdByProfileName.put(account.Owner.Profile.Name ,new Map<Id,List<SplitDetails>>{account.Id => New List<SplitDetails>{New SplitDetails(account.OwnerId,account.Owner.Profile.Name,CommissionCalculatorConstants.MARGINPERCENTFORACCOUNTS)}});
            }
        }
        System.debug('Exit:updateSplitsByAccountIdByProfileName =>  splitsByAccountIdByProfileName::'+
                     this.splitsByAccountIdByProfileName);
    }
    
    public Map<Id,Monthly_Commission__c> getMonthlyCommissionViaNameAndEmployee(){
        
        /************************************************************************
        * It performs a dynamic query on Monthly Commission Where it fetches only
        * those records whose employee Ids we've and name should have some specific 
        * month and year.
        **************************************************************************/
        
        System.debug('Entering:getMonthlyCommissionViaNameAndEmployee');
        String query = 'SELECT Id, Name, Employee__c, EoY_Sales_Commission__c, Tile_Margin__c, Tile_Margin_Percent__c, Target_Met__c, Price__c, Not_Elligible_Margin__c, Month__c, Margin__c, Eligible_Margin__c, Date__c, Cost__c, Ancillary_Margin__c, Ancillary_Margin_Percent__c,EoY_Sales_Commission__r.Commission_Master__c FROM Monthly_Commission__c';
        String whereClause = ' WHERE (Name Like \'%';
        Set<String> nameClauseSetup = new Set<String>( calculatedMarginsByOpportunityIdByMonth.keySet());
        Set<Id> userIds = new Set<Id>();
        System.debug('calculatedMarginsByAccountIdByMonth KeySet'+calculatedMarginsByAccountIdByMonth.keySet());
        nameClauseSetup.addAll(calculatedMarginsByAccountIdByMonth.keySet());
        List<String> nameClause = new List<String>(nameClauseSetup);
        whereClause += String.join(nameClause, '\' OR Name Like \'%');
        whereClause += '\') AND';
        userIds = getUserIdsFromSchema(this.splitsByOpportunityIdByProfileName.values(),userIds);
        userIds = getUserIdsFromSchema(this.splitsByAccountIdByProfileName.values(),userIds);
        whereClause += ' Employee__c IN : userIds';
        query += whereClause;
        system.debug('query::'+query);
        List<Monthly_Commission__c> monthlyCommissionViaNameAndEmployee = Database.query(query);
        Map<Id,Monthly_Commission__c> monthlyCommissionById = new Map<Id,Monthly_Commission__c>(monthlyCommissionViaNameAndEmployee);
        system.debug('Exit:getMonthlyCommissionViaNameAndEmployee => monthlyCommissionById:'+monthlyCommissionById); 
        return monthlyCommissionById;
    }
    
    public Set<Id> getUserIdsFromSchema(List<Map<Id,List<SplitDetails>>> splitDetailsById,Set<Id> userIds){
        
        /***********************************************************
        * It returns a set of Ids fethed from splitDetailsById
        ***********************************************************/
        
        System.debug('Entering:getUserIdsFromSchema => splitDetailsById::'+splitDetailsById+'\n userIds::'+userIds);
        for(Map<Id,List<SplitDetails>> splitDetailById :splitDetailsById){
            for(Id sObjId : splitDetailById.keySet()){
                for(SplitDetails detail: splitDetailById.get(sObjId)){
                    userIds.add(detail.ownerId);
                }   
            }            
        }
        System.debug('Exit:getUserIdsFromSchema => userIds::'+userIds);
        return userIds;
    }
    
    
    public void populateMonthlyBreakdownSchema(Set<Id> monthlyCommissions){
        
        /***********************************************************
        * This method first we fetch the existing records of Monthly
        * Brekdowns and then group them according to opportunity 
        * and accounts and then populates two map out of this data.
        ***********************************************************/
        
        System.debug('Entering:populateMonthlyBreakdownSchema => monthlyCommissions::'+monthlyCommissions);
        for(Monthly_Breakdown__c monthlyBreakdown : MonthlyBreakdownSelector.getMonthlyBreakDownByMonthlyCommission(monthlyCommissions)){
            if(monthlyBreakdown.Opportunity__c != null)
            {
                if(this.monthlyBreakdownsByOpportunity.containsKey(monthlyBreakdown.Opportunity__c))
                {
                    this.monthlyBreakdownsByOpportunity.get(monthlyBreakdown.Opportunity__c).add(monthlyBreakdown);
                }
                else {
                    this.monthlyBreakdownsByOpportunity.put(monthlyBreakdown.Opportunity__c ,  new List<Monthly_Breakdown__c>{monthlyBreakdown});
                }
                
            }
            else
            {
                if(this.monthlyBreakdownsByAccount.containsKey(monthlyBreakdown.Account__c))
                {
                    this.monthlyBreakdownsByAccount.get(monthlyBreakdown.Account__c).add(monthlyBreakdown);
                }
                else {
                    this.monthlyBreakdownsByAccount.put(monthlyBreakdown.Account__c ,  new List<Monthly_Breakdown__c>{monthlyBreakdown});
                }
            }
        }
        System.debug('Exit:populateMonthlyBreakdownSchema =>  monthlyBreakDownsByOpportunity::'+
                     this.monthlyBreakDownsByOpportunity+'\n monthlyBreakDownsByAccount::'+
                     this.monthlyBreakDownsByAccount);
    }
    
    /******************************************************************************
    * Note :- Every method that has written AnD in their name specifically  
    * performs operations for Sales Representative - A&D profile's users
    ******************************************************************************/
        
    public void populateMonthlyBreakdownsToBeUpsertedForAnDForOpportunity(Map<Id,List<SplitDetails>> splitsbyOppportunity, Integer  counterFlag, Integer monthlyBreakdownsSize) {
        
        /******************************************************************************
* populateMonthlyBreakdownsToBeUpsertedForAnDByAccount method is base method 
* in which there are sub methods that performs calculations for Splits,Margins
* for Monthly Commissions and Monthly Breakdowns. Also, If a Breakdown exists for 
* Opportunity in a month for a user then it'llbe updated with new cumulated calculated 
* data and if not there'll be a new breakdown created and populated with the calculated data.
******************************************************************************/
        
        System.debug('Entering:populateMonthlyBreakdownsToBeUpsertedForAnDForOpportunity => splitsbyOppportunity::'+splitsbyOppportunity+
                     '\ncounterFlag'+counterFlag+
                     '\nmonthlyBreakdownsSize'+monthlyBreakdownsSize);
        for(Id opportunityId : splitsbyOppportunity.keySet()){
            for(String invoiceMonthAndYear : this.calculatedMarginsByOpportunityIdByMonth.keySet()){
                if(this.calculatedMarginsByOpportunityIdByMonth.get(invoiceMonthAndYear).containsKey(opportunityId)){
                    setupCalculationRelatedDataForMonthlyBreakdownForAnDForOpportunity(opportunityId,invoiceMonthAndYear,splitsbyOppportunity,counterFlag,monthlyBreakdownsSize);
                }
            }
        }
        System.debug('Exit:populateMonthlyBreakdownsToBeUpsertedForAnDForOpportunity =>  monthlyBreakdownsToBeUpserted::'+
                     JSON.serializePretty(this.monthlyBreakdownsToBeUpserted));
    }
    
    public void populateMonthlyBreakdownsToBeUpsertedForAnDForAccount(Map<Id,List<SplitDetails>> splitsbyAccount, Integer  counterFlag, Integer monthlyBreakdownsSize) {
        
        /*************************************************************
        * This method performs the same operation as 
        * populateMonthlyBreakdownsToBeUpsertedForAnDForOpportunity
        * but at account level
        **************************************************************/        
        System.debug('Entering:populateMonthlyBreakdownsToBeUpsertedForAnDForAccount => splitsbyAccount::'+splitsbyAccount+
                     '\ncounterFlag'+counterFlag+
                     '\nmonthlyBreakdownsSize'+monthlyBreakdownsSize);
        for(Id accountId : splitsbyAccount.keySet()){
            for(String invoiceMonthAndYear : this.calculatedMarginsByAccountIdByMonth.keySet()){
                if(this.calculatedMarginsByAccountIdByMonth.get(invoiceMonthAndYear).containsKey(accountId)){
                    setupCalculationRelatedDataForMonthlyBreakdownForAnDForAccount(accountId,invoiceMonthAndYear,splitsbyAccount,counterFlag,monthlyBreakdownsSize);
                }
            }
        }
        System.debug('Exit:populateMonthlyBreakdownsToBeUpsertedForAnDForAccount =>  monthlyBreakdownsToBeUpserted::'+
                     JSON.serializePretty(this.monthlyBreakdownsToBeUpserted));
    }
    
    public void setupCalculationRelatedDataForMonthlyBreakdownForAnDForOpportunity(Id opportunityId, String invoiceMonthAndYear, Map<Id,List<SplitDetails>> splitsbyOppportunity, Integer counterFlag, Integer monthlyBreakdownsSize){
        
        /****************************************************
* For opportunity type invoices this method checks
* if we've to create a new monthly breakdown
* or we need to create a new monthly breakdown.
*****************************************************/
        
        InvoiceMargins invoiceMargin = new InvoiceMargins(this.calculatedMarginsByOpportunityIdByMonth.get(invoiceMonthAndYear).get(opportunityId));
        for(SplitDetails splitDetail : splitsbyOppportunity.get(opportunityId)){
            if(this.monthlyBreakdownsByOpportunity.containsKey(opportunityId)){
                counterFlag=0;
                monthlyBreakdownsSize = this.monthlyBreakdownsByOpportunity.get(opportunityId).size();
                for(Monthly_Breakdown__c breakdown : this.monthlyBreakdownsByOpportunity.get(opportunityId)){
                    if(breakdown.Monthly_Commission__r.Employee__c == splitDetail.ownerId && 
                       breakdown.Monthly_Commission__r.Name.contains(invoiceMonthAndYear) && 
                       breakdown.Opportunity__c == opportunityId){
                           updateExistingMonthlyBreakdownForAnD(breakdown,invoiceMargin,splitDetail.split);
                           break; 
                       }
                    counterFlag++;
                }
                if(counterFlag == monthlyBreakdownsSize){
                    updateMonthlyBreakdownsToBeUpsertedWithNewBreakdownForAnD(opportunityId, splitDetail.ownerId, splitDetail.split, invoiceMonthAndYear,invoiceMargin);
                }
            }
            else {
                updateMonthlyBreakdownsToBeUpsertedWithNewBreakdownForAnD(opportunityId, splitDetail.ownerId, splitDetail.split, invoiceMonthAndYear,invoiceMargin);
            }
            
        }
    }
    
    public void setupCalculationRelatedDataForMonthlyBreakdownForAnDForAccount(Id accountId, String invoiceMonthAndYear, Map<Id,List<SplitDetails>> splitsbyAccount,
                                                                               Integer counterFlag, Integer monthlyBreakdownsSize){
                                                                                   
                                                                                   /****************************************************
* This does the same thing as 
* setupCalculationRelatedDataForMonthlyBreakdownForAnDForOpportunity
* method but for account related invoices
*****************************************************/
                                                                                   
                                                                                   InvoiceMargins invoiceMargin = new InvoiceMargins(this.calculatedMarginsByAccountIdByMonth.get(invoiceMonthAndYear).get(accountId));
                                                                                   for(SplitDetails splitDetail : splitsbyAccount.get(accountId)){
                                                                                       if(this.monthlyBreakdownsByAccount.containsKey(accountId)){
                                                                                           counterFlag=0;
                                                                                           monthlyBreakdownsSize = this.monthlyBreakdownsByAccount.get(accountId).size();
                                                                                           for(Monthly_Breakdown__c breakdown : this.monthlyBreakdownsByAccount.get(accountId)){
                                                                                               if(breakdown.Monthly_Commission__r.Employee__c == splitDetail.ownerId && 
                                                                                                  breakdown.Monthly_Commission__r.Name.contains(invoiceMonthAndYear) && 
                                                                                                  breakdown.account__c == accountId){
                                                                                                      updateExistingMonthlyBreakdownForAnD(breakdown,invoiceMargin,splitDetail.split);
                                                                                                      break; 
                                                                                                  }
                                                                                               counterFlag++;
                                                                                           }
                                                                                           if(counterFlag == monthlyBreakdownsSize){
                                                                                               updateMonthlyBreakdownsToBeUpsertedWithNewBreakdownForAnD(accountId, splitDetail.ownerId, splitDetail.split, invoiceMonthAndYear,invoiceMargin);
                                                                                           }
                                                                                       }
                                                                                       else {
                                                                                           updateMonthlyBreakdownsToBeUpsertedWithNewBreakdownForAnD(accountId, splitDetail.ownerId, splitDetail.split, invoiceMonthAndYear,invoiceMargin);
                                                                                       }
                                                                                       
                                                                                   }
                                                                               }
    
    public void updateExistingMonthlyBreakdownForAnD(Monthly_Breakdown__c monthlyBreakdown, InvoiceMargins invoiceMargin, Decimal splitPercentage){
        
        /*******************************************************
* updateExistingMonthlyBreakdownForAnD method is called 
* when a monthly breakdown is already exists and it needs
* be updated with new data. This method cumulates the new
* amount in already existing monthly breakdown and then 
* sends further this monthly commission to calculate
* split margin and eligible amount and then add this monthly
* breakdown to a list that will be upserted in the system 
* after all monthly breakdown calculations.
*********************************************************/
        
        monthlyBreakdown.Total_sales__c += invoiceMargin.totalSales;
        monthlyBreakdown.Tile_Sale__c += invoiceMargin.tileSales;
        monthlyBreakdown.ancillary_sale__c += invoiceMargin.ancillarySales;
        monthlyBreakdown.Tile_Margin__c  +=invoiceMargin.tileMargin;
        monthlyBreakdown.Ancillary_Margin__c += invoiceMargin.ancillaryMargin;
        monthlyBreakdown.Commission_Split_Percentage__c  = splitPercentage;
        monthlyBreakdown = calculateMonthlyBreakdownMargins(monthlyBreakdown);
        this.monthlyBreakdownsToBeUpserted.add(monthlyBreakdown);
        
    }
    
    public void updateMonthlyBreakdownsToBeUpsertedWithNewBreakdownForAnD(Id sObjectId, Id splitOwnerId,Decimal splitPercentage, String invoiceMonthAndYear, InvoiceMargins invoiceMargin){
        
        /*******************************************************
* This method also adds the monthly breakdown to that list 
* that will be upserted in the system after all monthly 
* breakdown calculations. But before that it creates a new
* monthly breakdown and performs all the mandatory calculations. 
*********************************************************/
        Id monthlyCommission = getMonthlyCommissionViaSplitOwnerIdAndInvoiceDate(splitOwnerId, invoiceMonthAndYear);
        if(!String.isBlank((String)monthlyCommission)){
            Monthly_Breakdown__c monthlyBreakdown = new Monthly_Breakdown__c();
            String sobjectType = sObjectId.getSObjectType().getDescribe().getName();
            System.debug(sobjectType);
            if(sObjectType == 'Opportunity')
            {
                monthlyBreakdown.opportunity__c = sObjectId;
            }
            else if(sObjectType == 'Account')
            {
                monthlyBreakdown.account__c = sObjectId;
            }
            monthlyBreakdown.Monthly_Commission__c = monthlyCommission;
            monthlyBreakdown.Total_Sales__c = invoiceMargin.totalSales;
            monthlyBreakdown.Tile_Sale__c = invoiceMargin.tileSales;
            monthlyBreakdown.Ancillary_Sale__c = invoiceMargin.ancillarySales;
            monthlyBreakdown.Tile_Margin__c  =invoiceMargin.tileMargin;
            monthlyBreakdown.Ancillary_Margin__c = invoiceMargin.ancillaryMargin;
            monthlyBreakdown.Commission_Split_Percentage__c  = splitPercentage;
            monthlyBreakdown = calculateMonthlyBreakdownMargins(monthlyBreakdown);
            this.monthlyBreakdownsToBeUpserted.add(monthlyBreakdown);
        }
    }
    
    public Monthly_Breakdown__c calculateMonthlyBreakdownMargins(Monthly_Breakdown__c monthlyBreakdown){
        
        /******************************************************
        * We're calculating margins(split portion) and 
        * eligible ammount of monthly breakdowns also 
        * checking if that specific breakdown meets the 
        * GP % target or not
        ******************************************************/
        
        if(monthlyBreakdown.Tile_Sale__c == 0){
            monthlyBreakdown.Tile_Margin_Percentage__c  = 0;
        }
        else{
            monthlyBreakdown.Tile_Margin_Percentage__c  = ((monthlyBreakdown.Tile_Margin__c / monthlyBreakdown.Tile_Sale__c) *100).setScale(2);
        }
        if(monthlyBreakdown.ancillary_sale__c == 0){
            monthlyBreakdown.Ancillary_Margin_Percentage__c  = 0;
        }
        else{
            monthlyBreakdown.Ancillary_Margin_Percentage__c  = ((monthlyBreakdown.Ancillary_Margin__c / monthlyBreakdown.ancillary_sale__c) *100).setScale(2);
        }
        system.debug('monthlyBreakdown===>'+monthlyBreakdown);
        
        monthlyBreakdown.Total_Invoice_Tile_Margin__c  = ((monthlyBreakdown.Tile_Margin__c  * monthlyBreakdown.Commission_Split_Percentage__c)/100).setScale(2);
        monthlyBreakdown.Total_Invoice_Ancillary_Margin__c   = ((monthlyBreakdown.Ancillary_Margin__c  * monthlyBreakdown.Commission_Split_Percentage__c)/100).setScale(2);
        monthlyBreakdown.Total_Margin__c = monthlyBreakdown.Total_Invoice_Tile_Margin__c + monthlyBreakdown.Total_Invoice_Ancillary_Margin__c;
        
        if( monthlyBreakdown.Tile_Margin_Percentage__c >= this.targetByTypeByCommissionMaster.get((this.monthlyCommissionsById.get(monthlyBreakdown.Monthly_Commission__c).EoY_Sales_Commission__r.Commission_Master__c)).get('Tile') &&
           monthlyBreakdown.Ancillary_Margin_Percentage__c >= this.targetByTypeByCommissionMaster.get((this.monthlyCommissionsById.get(monthlyBreakdown.Monthly_Commission__c).EoY_Sales_Commission__r.Commission_Master__c)).get('Ancillary')){
               monthlyBreakdown.Met_Margin__c = true;
           }
        else{
            monthlyBreakdown.Met_Margin__c = false;
        }
        if(monthlyBreakdown.Met_Margin__c){
            monthlyBreakdown.Elgible_Amount__c = monthlyBreakdown.Total_Margin__c;
        }
        else{
            monthlyBreakdown.Elgible_Amount__c = 0;
        }
        return monthlyBreakdown;
    } 
    
    public void populateProfileNames(){
        
        /******************************************
        * This method populates the all profile names
        * (that we've got so far) in a List
        *******************************************/
        
        System.debug('Entering:populateProfileNames => profileNames::'+profileNames);
        this.profileNames.addAll(this.splitsByOpportunityIdByProfileName.keySet()) ;
        this.profileNames.addAll(this.splitsByAccountIdByProfileName.keySet());
        System.debug('Exit:populateProfileNames =>  profileNames::'+this.profileNames);
    }
    
    public void calculateMonthlyBreakdowns(){
        
        /**************************************************************** 
* This method will Iterate the profile Name to call different 
* method for further calclation now at profile level 
* for all opportunity and account related incoices 
****************************************************************/
        
        System.debug('Entering:calculateMonthlyBreakdowns => profileNames::'+this.profileNames+
                     '\nsplitsByOpportunityIdByProfileName::'+this.splitsByOpportunityIdByProfileName+
                     '\nsplitsByAccountIdByProfileName::'+this.splitsByAccountIdByProfileName);
        Integer counterFlag=0;
        Integer monthlyBreakdownsSize = 0;  
        for(String profile : this.profileNames)
        {
            if(profile == CommissionCalculatorConstants.REPTYPEAD)
            {
                if(this.splitsByOpportunityIdByProfileName.containsKey(profile))
                {
                    populateMonthlyBreakdownsToBeUpsertedForAnDForOpportunity(this.splitsByOpportunityIdByProfileName.get(profile),counterFlag,monthlyBreakdownsSize);
                }
                if(this.splitsByAccountIdByProfileName.containsKey(profile))
                {
                    populateMonthlyBreakdownsToBeUpsertedForAnDForAccount(this.splitsByAccountIdByProfileName.get(profile),counterFlag,monthlyBreakdownsSize);
                }
            }
        }
        System.debug('Exit:calculateMonthlyBreakdowns =>  monthlyBreakdownsToBeUpserted::'+JSON.serializePretty(this.monthlyBreakdownsToBeUpserted));
    }
    
    public void upsertMonthlyBreakdown(){
        System.debug('Entering:upsertMonthlyBreakdown => monthlyBreakdownsToBeUpserted::'+monthlyBreakdownsToBeUpserted);
        if(!this.monthlyBreakdownsToBeUpserted.isEmpty()){
           upsert this.monthlyBreakdownsToBeUpserted;
        }
        System.debug('Exit:upsertMonthlyBreakdown => monthlyBreakdownsToBeUpserted::'+monthlyBreakdownsToBeUpserted);
    }
    
    public Id getMonthlyCommissionViaSplitOwnerIdAndInvoiceDate (Id splitOwnerId, String invoiceMonthAndYear){
        
        /*************************************************
* This is called inside loops
* where, it filters a monthly commissions Id 
* from all monthly commissions data that we've
* and then returns that id
*************************************************/
        Id monthlyCommission;
        for(Monthly_Commission__c commission : this.monthlyCommissionsById.values()){
            if(commission.Employee__c == splitOwnerId && commission.name.contains(invoiceMonthAndYear)){
                monthlyCommission = commission.Id;
                break;
            }
        }
         System.debug('splitOwnerId===>'+splitOwnerId);
        return monthlyCommission;
    }
    
    public Set<Id> getCommissionMasterIdsFromMonthlyCommission(List<Monthly_Commission__c> monthlyCommissions){
        
        /***********************************************
* This method returns the Ids 
* of Commission Masters fetched 
* Monthly commissions Data we've
***********************************************/
        
        System.debug('Entering:getCommissionMasterIdsFromMonthlyCommission => monthlyCommissions::'+monthlyCommissions);
        set<Id> commissionMasters = new Set<Id>();
        for(Monthly_Commission__c monthlyCommission : monthlyCommissions){
            commissionMasters.add(monthlyCommission.EoY_Sales_Commission__r.Commission_Master__c);
        }
        System.debug('Exit:getCommissionMasterIdsFromMonthlyCommission => commissionMasters::'+commissionMasters);
        return commissionMasters;
    }
    
    public void pupulateCommissionsSchema(Set<Id> commissionMasters){
        
        /*************************************************************
* pupulateCommissionsSchema method is used to fetch all the 
* commission structure and creates multiple maps.
* in these maps 1st map is of commission master and others are
* its related data, where key is commission master's id.
**************************************************************/
        
        System.debug('Entering:pupulateCommissionsSchema => commissionMasters::'+commissionMasters);
        this.commissionMasterById=CommissionMasterSelector.getCommissionMasterById(commissionMasters);
        this.commissionTiersByCommissionMaster = DataFactory.getsObjectsByFieldId(CommissionTierSelector.getCommissionTierByCommissionMasters(commissionMasters),'Commission_Master__c');
        this.targetByTypeByCommissionMaster = getTargetByTypeByCommissionMaster(GPPercentTargetSelector.getGPPercentTargetByCommissionMasters(commissionMasters));
        this.eoyGPBonusTarget = DataFactory.getsObjectsByFieldId(EoYGPBonusTargetSelector.getEoYGPBonusTargetByCommissionMasters(commissionMasters),'Commission_Master__c');
        System.debug('Exit:pupulateCommissionsSchema => commissionMasterById::'+this.commissionMasterById+
                     '\ncommissionTiersByCommissionMaster::'+this.commissionTiersByCommissionMaster+
                     '\ntargetByTypeByCommissionMaster::'+this.targetByTypeByCommissionMaster+
                     '\neoyGPBonusTarget::'+this.eoyGPBonusTarget);
    }
    
    public Map<Id,Map<String,Decimal>> getTargetByTypeByCommissionMaster(List<GP_Percent_Target__c> gpPercentTargets){
        
        /*****************************************
* This method returns a map of
* commission master's Id and 
* all GP % targets
******************************************/
        
        System.debug('Entering:getTargetByTypeByCommissionMaster => gpPercentTargets::'+gpPercentTargets);
        Map<Id,Map<String,Decimal>> targetByTypeByCommissionMaster = new Map<Id,Map<String,Decimal>>();
        for(GP_Percent_Target__c gpPercentTarget : gpPercentTargets){
            if(targetByTypeByCommissionMaster.containsKey(gpPercentTarget.Commission_Master__c)){
                targetByTypeByCommissionMaster.get(gpPercentTarget.Commission_Master__c).put(gpPercentTarget.Type__c,gpPercentTarget.Target_Percent__c);
            }
            else{
                targetByTypeByCommissionMaster.put(gpPercentTarget.Commission_Master__c,new Map<String,Decimal>{gpPercentTarget.Type__c => gpPercentTarget.Target_Percent__c});
            }
        }
        System.debug('Exit:getTargetByTypeByCommissionMaster => targetByTypeByCommissionMaster::'+targetByTypeByCommissionMaster);
        return targetByTypeByCommissionMaster;
    }
    
    public void populateMonthlyCommissionByIdByProfileName(Set<Id> monthlyCommissions){
        
        /*****************************************************
* we first fetch all the monthly breakdowns whose ids 
* we've and then we setup initial monthly commission 
* data with the help of monthly breakdowns
*****************************************************/
        
        System.debug('Entering:populateMonthlyCommissionByIdByProfileName => monthlyCommissions::'+monthlyCommissions); //monthlyCommissionByIdByProfileName
        for(Monthly_Breakdown__c monthlyBreakdown : monthlyBreakDownSelector.getMonthlyBreakDownByMonthlyCommission(monthlyCommissions)){
            
            if(this.monthlyCommissionByIdByProfileName.containsKey(monthlyBreakdown.monthly_commission__r.employee__r.profile.name)){
                
                if((this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).containsKey(monthlyBreakdown.monthly_commission__c))){
                    updateMonthlyCommissionViaMonthlyBreakdown(monthlyBreakdown);
                }
                else {                    
                    this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).put
                        (monthlyBreakdown.Monthly_Commission__c , assignMonthlyCommissionViaMonthlyBreakdown(monthlyBreakdown));
                }
                
            }
            else {                
                this.monthlyCommissionByIdByProfileName.put(monthlyBreakdown.Monthly_Commission__r.Employee__r.Profile.Name , 
                                                            new Map<Id,Monthly_Commission__c> {monthlyBreakdown.monthly_commission__c => 
                                                                assignMonthlyCommissionViaMonthlyBreakdown(monthlyBreakdown)});
            }            
        }
        System.debug('Exit:populateMonthlyCommissionByIdByProfileName =>  monthlyCommissionByIdByProfileName::'+
                     JSON.serializePretty( this.monthlyCommissionByIdByProfileName));  
    }
    
    public void updateMonthlyCommissionViaMonthlyBreakdown(Monthly_Breakdown__c monthlyBreakdown){
        
        /***********************************************************
* Called from : populateMonthlyCommissionByIdByProfileName
* If a monthly commission already has data then this 
* method will cumulate the monthly commission's data to it.
* also checks if this monthly commission has the eligible
* amount or not and if it meets the GP % Targets.
************************************************************/
        
        this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Tile_margin__c += monthlyBreakdown.Tile_Margin__c;
        this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Ancillary_Margin__c += monthlyBreakdown.Ancillary_Margin__c;
        this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Tile_Sale__c += monthlyBreakdown.Tile_Sale__c;
        this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Ancillary_Sale__c += monthlyBreakdown.Ancillary_Sale__c;
        this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Total_Invoice_Ancillary_Margin__c += monthlyBreakdown.Total_Invoice_Ancillary_Margin__c;
        this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Total_Invoice_Tile_Margin__c += monthlyBreakdown.Total_Invoice_Tile_Margin__c;
        
        if(this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Tile_Sale__c == 0){
            this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Tile_Margin_Percent__c = 0;
        }
        else{
            this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Tile_Margin_Percent__c = ((this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Tile_margin__c
                                                                                                                                                                                                /this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Tile_Sale__c)
                                                                                                                                                                                               *100).setScale(2);
        }  
        
        if(this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Ancillary_Sale__c == 0){
            this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Ancillary_Margin_Percent__c = 0;
        }
        else{
            this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Ancillary_Margin_Percent__c = ((this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Ancillary_Margin__c
                                                                                                                                                                                                     /this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Ancillary_Sale__c)
                                                                                                                                                                                                    *100).setScale(2);
        }
        if(monthlyBreakdown.Monthly_Commission__r.Employee__r.Profile.Name == CommissionCalculatorConstants.REPTYPEAD){
            if(this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Tile_Margin_Percent__c 
               >= (this.targetByTypeByCommissionMaster.get(monthlyBreakdown.Monthly_Commission__r.EoY_Sales_Commission__r.Commission_Master__c).get('Tile')) 
               && 
               this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Ancillary_Margin_Percent__c 
               >= (this.targetByTypeByCommissionMaster.get(monthlyBreakdown.Monthly_Commission__r.EoY_Sales_Commission__r.Commission_Master__c).get('Ancillary'))) {
                   this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Target_Met__c = true;
               }
            else {
                this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Target_Met__c = false;
            }
        }
        this.monthlyCommissionByIdByProfileName.get(monthlyBreakdown.monthly_commission__r.employee__r.profile.name).get(monthlyBreakdown.monthly_commission__c).Eligible_margin__c += monthlyBreakdown.Elgible_Amount__c;
    }
    
    public Monthly_Commission__c assignMonthlyCommissionViaMonthlyBreakdown(Monthly_Breakdown__c monthlyBreakdown){
        
        /***********************************************************
* Called from : populateMonthlyCommissionByIdByProfileName
* If a monthly commission doesn't has data then this 
* method will assign monthly breakdown's data to 
* monthly commission.
* also checks if this monthly commission has the eligible
* amount or not and if it meets the GP % Targets.
************************************************************/
        
        Monthly_Commission__c monthlyCommission = new Monthly_Commission__c();
        monthlyCommission.Id  = monthlyBreakdown.Monthly_Commission__c;
        monthlyCommission.Tile_Sale__c = monthlyBreakdown.Tile_Sale__c;
        monthlyCommission.Ancillary_Sale__c = monthlyBreakdown.Ancillary_Sale__c;
        monthlyCommission.Tile_Margin__c = monthlyBreakdown.Tile_Margin__c;
        monthlyCommission.Ancillary_Margin__c = monthlyBreakdown.Ancillary_Margin__c;
        monthlyCommission.Tile_Margin_Percent__c  = monthlyBreakdown.Tile_Margin_Percentage__c;
        monthlyCommission.Ancillary_Margin_Percent__c = monthlyBreakdown.Ancillary_Margin_Percentage__c;
        monthlyCommission.Total_Invoice_Ancillary_Margin__c = monthlyBreakdown.Total_Invoice_Ancillary_Margin__c;
        monthlyCommission.Total_Invoice_Tile_Margin__c = monthlyBreakdown.Total_Invoice_Tile_Margin__c;
        if(monthlyBreakdown.Monthly_Commission__r.Employee__r.Profile.Name == CommissionCalculatorConstants.REPTYPEAD){
            if(monthlyCommission.Tile_Margin_Percent__c >= (this.targetByTypeByCommissionMaster.get
                                                            (monthlyBreakdown.Monthly_Commission__r.EoY_Sales_Commission__r.Commission_Master__c).get
                                                            ('Tile'))
               && 
               monthlyCommission.Ancillary_Margin_Percent__c >= (this.targetByTypeByCommissionMaster.get
                                                                 (monthlyBreakdown.Monthly_Commission__r.EoY_Sales_Commission__r.Commission_Master__c).get
                                                                 ('Ancillary')))
            {
                monthlyCommission.target_met__c= true;
            }
            else {
                monthlyCommission.target_met__c= false;
            }
        }
        monthlyCommission.Eligible_margin__c = monthlyBreakdown.Elgible_Amount__c;
        
        return monthlyCommission;
    }
    
    public void updateMonthlyCommission(){
        
        /*********************************************************
* updateMonthlyCommission Will perform the final Update
* DML that'll update the monthly commissions
**********************************************************/
        
        System.debug('Entering:updateMonthlyCommission => monthlyCommissionByIdByProfileName::'+this.monthlyCommissionByIdByProfileName);
        List<Monthly_Commission__c> monthlyCommissionsToBeUpdated = new List<Monthly_Commission__c>();
        
        for(String profileName : this.monthlyCommissionByIdByProfileName.keySet()){
            monthlyCommissionsToBeUpdated.addAll(this.monthlyCommissionByIdByProfileName.get(profileName).values());
        }
        if(!monthlyCommissionsToBeUpdated.isEmpty()){
            try{
               update monthlyCommissionsToBeUpdated;
            }
            catch(DMLException e) {
                ExceptionUtils.createExceptionLogV2('InvoiceDetailTriggerHelper', e.getMessage(), e.getStackTraceString());
                System.debug('ERROR:: updateMonthlyCommission ==> Message::'+e.getMessage()+'\nTrace::'+e.getStackTraceString());
            }           
        }
        System.debug('Exit:updateMonthlyCommission => monthlyCommissionsToBeUpdated::'+JSON.serializePretty(monthlyCommissionsToBeUpdated));
    }
    
    public class InvoiceMargins {
        public Decimal totalSales;
        public Decimal tileSales;
        public Decimal ancillarySales;
        public Decimal tileMargin;
        public Decimal ancillaryMargin;
        public Decimal tileMarginPercentage;
        public Decimal ancillaryMarginPercentage;
        
        
        public invoiceMargins(){
            totalSales = 0 ;
            tileSales = 0;
            ancillarySales = 0;
            tileMargin = 0;
            ancillaryMargin = 0;
            tileMarginPercentage = 0;
            ancillaryMarginPercentage = 0;
        }
        
        public invoiceMargins(Decimal totalSales, Decimal tileSales, Decimal ancillarySales, Decimal tileMargin,
                              Decimal ancillaryMargin, Decimal tileMarginPercentage, Decimal ancillaryMarginPercentage){
                                  this.totalSales =totalSales;
                                  this.tileSales =tileSales;
                                  this.ancillarySales =ancillarySales;
                                  this.tileMargin =tileMargin;
                                  this.ancillaryMargin =ancillaryMargin;
                                  this.tileMarginPercentage =tileMarginPercentage;
                                  this.ancillaryMarginPercentage =ancillaryMarginPercentage;                              
                              }
        public invoiceMargins(InvoiceMargins invoiceMargin){
            this.totalSales =invoiceMargin.totalSales;
            this.tileSales =invoiceMargin.tileSales;
            this.ancillarySales =invoiceMargin.ancillarySales;
            this.tileMargin =invoiceMargin.tileMargin;
            this.ancillaryMargin =invoiceMargin.ancillaryMargin;
            this.tileMarginPercentage =invoiceMargin.tileMarginPercentage;
            this.ancillaryMarginPercentage =invoiceMargin.ancillaryMarginPercentage;         
        }
    }
    
    Public class SplitDetails{
        Public Id ownerId;
        Public String ownerProfile;
        Public Decimal split;
        Public SplitDetails(Id ownerId,String ownerProfile,Decimal split){
            this.ownerId = ownerId;
            this.ownerProfile = ownerProfile;
            this.split = split;
        }
    }
}