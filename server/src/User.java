
import java.util.ArrayList;
import java.util.Properties;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectOutputStream;
import java.io.Serializable;

import org.kapott.hbci.passport.*;

public class User implements Serializable {
/**
	 * 
	 */
	private static final long serialVersionUID = 1572961858013515768L;
	public String name;
	public String bankCode;
	public String bankName;
	public String userId;
	public String customerId;
	public String host;
	public int    port;
	public String filter;
	public String version;
	public String tanMethod;
	public String tanMethodDescription;
	public boolean checkCert;

	public ArrayList<String> methods;
	
	public User initWithHBCI(HBCIPassportPinTan pp, String ppName) {
		name = ppName;
		bankCode = pp.getBLZ();
		bankName = pp.getInstName();
		userId = pp.getUserId();
		customerId = pp.getCustomerId();
		host = pp.getHost();
		port = pp.getPort();
		filter = pp.getFilterType();
		version = pp.getHBCIVersion();
		checkCert = pp.getCheckCert();
    	Properties sec = pp.getCurrentSecMechInfo();
    	if(sec != null)	{
    		tanMethod = sec.getProperty("secfunc");
    		tanMethodDescription = sec.getProperty("name");
    	}
		return this;
	}
	
	public void updatePinTanMethod(HBCIPassportPinTan pp) {
    	Properties sec = pp.getCurrentSecMechInfo();
    	if(sec != null)	{
    		tanMethod = sec.getProperty("secfunc");
    		tanMethodDescription = sec.getProperty("name");
    	}		
	}
	
	public void save() throws IOException {
        FileOutputStream userFile = new FileOutputStream(HBCIServer.server().passportFilepath(bankCode, userId));
        ObjectOutputStream o = new ObjectOutputStream( userFile );
        o.writeObject(this);
        o.close();
	}
	
	
	public static User createFromHBCI(HBCIPassportPinTan pp, String name) {
		User p = new User();
		p.initWithHBCI(pp, name);
		return p;
	}
	
}
