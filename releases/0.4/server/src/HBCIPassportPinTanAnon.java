
import org.kapott.hbci.manager.HBCIUtilsInternal;
import org.kapott.hbci.passport.*;

public class HBCIPassportPinTanAnon extends HBCIPassportPinTan {
	
	private boolean ready;
	static final long serialVersionUID=0;		// this class is not serialized
	
	public HBCIPassportPinTanAnon(String bankCode) {
		super(null, 0);
		
		ready = false;
		String info = HBCIUtilsInternal.getBLZData(bankCode);
	    String host = HBCIUtilsInternal.getNthToken(info, 6);
	    if(host == null || host.isEmpty()) return;
	    if(host.startsWith("https://")) host = host.substring(8);
	    String version = HBCIUtilsInternal.getNthToken(info, 8);
	    if(version == null || version.isEmpty()) return;
	    
		this.setBLZ(bankCode);
		this.setCountry("DE");
		this.setFilterType("Base64");
		this.setHost(host);
		this.setHBCIVersion(version);
		this.setPort(443);		
		this.setProxy("");

	    ready = true;
	}
	
	public boolean isReady() {
		return ready;
	}
	
	public void saveChanges() {
		return;
	}

}
