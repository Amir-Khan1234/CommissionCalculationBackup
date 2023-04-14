public class CommissionCalculatorConstants {
    public static final String ITEMGROUPTILE='Tile';
    public static final String ITEMGROUPANCILLARY='Ancillary';
    public static final String RETROACTIVE='Retroactive';
    public static final String MARGINAL='Marginal';
	public static final Map<Integer,String> MONTHBYNUMBER = new Map<Integer,String>{1 => 'Jan', 2 => 'Feb', 3 => 'Mar', 4 => 'Apr', 5 => 'May', 6 => 'Jun',
                                                                                    7 => 'Jul', 8 => 'Aug', 9 => 'Sep', 10 => 'Oct', 11 => 'Nov', 12 => 'Dec'};
    public static final Decimal MARGINPERCENTFOROPPWITHNOSPLITS =  100;   
    public static final Decimal MARGINPERCENTFORACCOUNTS =  100;  
    public static final String REPTYPEAD = 'Sales Representative - A&D';
    public static final String REPTYPEDEALER = 'Sales Representative - Dealer';
    public static final String REPTYPECONTRACTOR = 'Sales Representative - Contractor';
    public static final List<String> profileNames = new list<string>{'Sales Representative - A&D','Sales Representative - Dealer','Sales Representative - Contractor'};
}