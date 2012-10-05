import org.kapott.hbci.passport.HBCIPassportDDV;


public class HBCIPassportDDVExt extends HBCIPassportDDV {
	
    public HBCIPassportDDVExt(Object init,int dummy)
    {
        super(init, dummy);
    }

    public HBCIPassportDDVExt(Object init)
    {
        super(init);
    }
    
    public boolean isAlive() {
    	boolean result = true;
    	try {
    		ctReadBankData();
    	}
    	catch(Exception e) {
    		result = false;
    	}
    	return result;
    }

}
