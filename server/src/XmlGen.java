import java.io.IOException;
import java.util.ArrayList;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.Properties;

import org.kapott.hbci.GV_Result.GVRDauerList;
import org.kapott.hbci.GV_Result.GVRKUms;
import org.kapott.hbci.GV_Result.GVRTermUebList;
import org.kapott.hbci.GV_Result.GVRKKSaldoReq;
import org.kapott.hbci.GV_Result.GVRKKUms;
import org.kapott.hbci.GV_Result.GVRKKSettleList;
import org.kapott.hbci.GV_Result.GVRTANMediaList.TANMediaInfo;
import org.kapott.hbci.GV_Result.GVRTANMediaList;
import org.kapott.hbci.manager.HBCIUtils;
import org.kapott.hbci.manager.HBCIHandler;
import org.kapott.hbci.passport.HBCIPassport;
import org.kapott.hbci.passport.HBCIPassportPinTan;
import org.kapott.hbci.passport.HBCIPassportDDV;
import org.kapott.hbci.structures.Konto;
import org.kapott.hbci.structures.Value;

public class XmlGen {
	private StringBuffer xmlBuf;
	
	XmlGen(StringBuffer buf) {
		xmlBuf = buf;
	}
	
    private String escapeSpecial(String s) {
    	String r = s.replaceAll("&", "&amp;");
    	r = r.replaceAll("<", "&lt;");
    	r = r.replaceAll(">", "&gt;");
    	r = r.replaceAll("\"", "&quot;");
    	r = r.replaceAll("'", "&apos;");
    	return r;
    }
    
    public void tag(String tag, String value) throws IOException {
    	if(value == null) return;
    	xmlBuf.append("<"+tag+">"+escapeSpecial(value)+"</"+tag+">");
    }
    
    public void valueTag(String tag, Value value) {
    	if(value == null) return;
    	xmlBuf.append("<"+tag+" type=\"value\">"+Long.toString(value.getLongValue())+"</"+tag+">");
    }
    
    public void longTag(String tag, long l) {
    	xmlBuf.append("<"+tag+" type=\"long\">"+Long.toString(l)+"</"+tag+">");
    }
    
    public void dateTag(String tag, Date date) {
    	if(date == null) return;
    	xmlBuf.append("<"+tag+" type=\"date\">"+HBCIUtils.date2StringISO(date)+"</"+tag+">");
    }
    
    public void intTag(String tag, String value) {
    	if(value == null) return;
    	xmlBuf.append("<"+tag+" type=\"int\">"+value+"</"+tag+">");
    }

    public void intTag(String tag, int value) {
    	xmlBuf.append("<"+tag+" type=\"int\">"+Integer.toString(value)+"</"+tag+">");
    }

    
    public void booleTag(String tag, boolean b) {
    	if(b) xmlBuf.append("<"+tag+" type=\"boole\">yes</"+tag+">");
    	else xmlBuf.append("<"+tag+" type=\"boole\">no</"+tag+">");
    }
    
    public void accountToXml(Konto account, HBCIHandler handler) throws IOException {
    	HBCIPassport pp = handler.getPassport();
    	
    	xmlBuf.append("<object type=\"Account\">");
    	if(account.curr == null || account.curr.length() == 0) account.curr = "EUR";
    	if(account.country == null || account.curr.length() == 0) account.country = "DE";
    	tag("name", account.type);
    	tag("bankName", HBCIUtils.getNameForBLZ(account.blz));
    	tag("bankCode", account.blz);
    	tag("accountNumber", account.number);
    	tag("ownerName", account.name);
    	tag("currency", account.curr.toUpperCase());
    	tag("country", account.country.toUpperCase());
    	tag("iban", account.iban);
    	tag("bic", account.bic);
    	tag("userId", pp.getUserId());
    	tag("customerId", account.customerid);
    	tag("subNumber", account.subnumber);
        intTag("type", account.category);
        xmlBuf.append("<supportedJobs type=\"list\">");
        ArrayList<String> gvs = (ArrayList<String>)account.allowedGVs;
        if(gvs != null && gvs.contains("HKUEB") || gvs == null && handler.isSupported("Ueb")) tag("name", "Ueb");
        if(gvs != null && gvs.contains("HKTUE") || gvs == null && handler.isSupported("TermUeb")) tag("name", "TermUeb");
        if(gvs != null && gvs.contains("HKAOM") || gvs == null && handler.isSupported("UebForeign")) tag("name", "UebForeign");
        if(gvs != null && gvs.contains("HKCCS") || gvs == null && handler.isSupported("UebSEPA")) tag("name", "UebSEPA");
        if(gvs != null && gvs.contains("HKUMB") || gvs == null && handler.isSupported("Umb")) tag("name", "Umb");
        if(gvs != null && gvs.contains("HKLAS") || gvs == null && handler.isSupported("Last")) tag("name", "Last");
        if(gvs != null && gvs.contains("HKDAE") || gvs == null && handler.isSupported("DauerNew")) tag("name", "DauerNew");
        if(gvs != null && gvs.contains("HKDAN") || gvs == null && handler.isSupported("DauerEdit")) tag("name", "DauerEdit");
        if(gvs != null && gvs.contains("HKDAL") || gvs == null && handler.isSupported("DauerDel")) tag("name", "DauerDel");
        if(gvs != null && gvs.contains("HKTAB") || gvs == null && handler.isSupported("TANMediaList")) tag("name", "TANMediaList");
        if(gvs != null && gvs.contains("HKSUB") || gvs == null && handler.isSupported("MultiUeb")) tag("name", "MultiUeb");
        
        xmlBuf.append("</supportedJobs>");
    	xmlBuf.append("</object>");
    }
    
    public void accountJobsToXml(Konto account, HBCIHandler handler) throws IOException {
		xmlBuf.append("<object type=\"AccountJobs\">");
		tag("accountNumber", account.number);
		tag("subNumber", account.subnumber);
        xmlBuf.append("<supportedJobs type=\"list\">");
		ArrayList<String> gvs = (ArrayList<String>)account.allowedGVs;
        if(gvs != null && gvs.contains("HKUEB") || gvs == null && handler.isSupported("Ueb")) tag("name", "Ueb");
        if(gvs != null && gvs.contains("HKTUE") || gvs == null && handler.isSupported("TermUeb")) tag("name", "TermUeb");
        if(gvs != null && gvs.contains("HKAOM") || gvs == null && handler.isSupported("UebForeign")) tag("name", "UebForeign");
        if(gvs != null && gvs.contains("HKCCS") || gvs == null && handler.isSupported("UebSEPA")) tag("name", "UebSEPA");
        if(gvs != null && gvs.contains("HKUMB") || gvs == null && handler.isSupported("Umb")) tag("name", "Umb");
        if(gvs != null && gvs.contains("HKLAS") || gvs == null && handler.isSupported("Last")) tag("name", "Last");
        if(gvs != null && gvs.contains("HKDAE") || gvs == null && handler.isSupported("DauerNew")) tag("name", "DauerNew");
        if(gvs != null && gvs.contains("HKDAN") || gvs == null && handler.isSupported("DauerEdit")) tag("name", "DauerEdit");
        if(gvs != null && gvs.contains("HKDAL") || gvs == null && handler.isSupported("DauerDel")) tag("name", "DauerDel");
        if(gvs != null && gvs.contains("HKTAB") || gvs == null && handler.isSupported("TANMediaList")) tag("name", "TANMediaList");
        if(gvs != null && gvs.contains("HKSUB") || gvs == null && handler.isSupported("MultiUeb")) tag("name", "MultiUeb");
        xmlBuf.append("</supportedJobs></object>");
    }
  
	@SuppressWarnings("unchecked")
    public void umsToXml(GVRKUms ums, Konto account) throws IOException {
		
    	xmlBuf.append("<object type=\"BankQueryResult\">");
    	tag("bankCode", account.blz);
    	tag("accountNumber", account.number);
    	tag("accountSubnumber", account.subnumber);
    	xmlBuf.append("<statements type=\"list\">");

    	List<GVRKUms.UmsLine> lines = ums.getFlatData();
    	long hash;
    	for(Iterator<GVRKUms.UmsLine> i = lines.iterator(); i.hasNext(); ) {
    		hash = 0;
    		GVRKUms.UmsLine line = i.next();
    		
    		StringBuffer purpose = new StringBuffer();
    		if(line.gvcode.equals("999")) {
    			purpose.append(line.additional);
    			hash += line.additional.hashCode();
    		}
    		else {
	    		for(Iterator<String> j = line.usage.iterator(); j.hasNext();) {
	    			String s = j.next();
	    			purpose.append(s);
	    			hash += s.hashCode();
	    			if(j.hasNext()) purpose.append("\n");
	    		}
    		}
    		
    		// calculate id
    		hash += account.number.hashCode();
    		hash += account.blz.hashCode();
    		
        	xmlBuf.append("<cdObject type=\"BankStatement\">");
        	tag("localAccount", account.number);
        	tag("localBankCode", account.blz);
        	tag("bankReference", line.instref);
        	tag("currency", line.value.getCurr());
        	tag("customerReference", line.customerref);
        	if(line.customerref != null) hash += line.customerref.hashCode();
        	dateTag("date", line.bdate);
        	hash += line.bdate.hashCode();
        	dateTag("valutaDate", line.valuta);
        	hash += line.valuta.hashCode();
        	valueTag("value", line.value);
        	hash += line.value.getLongValue();
        	if(line.saldo != null) valueTag("saldo", line.saldo.value);
//        	if(line.saldo != null) dateTag("saldoTimestamp", line.saldo.timestamp);
        	valueTag("charge", line.charge_value);
        	// todo: orig_value
        	tag("primaNota", line.primanota);
        	if(line.primanota != null) hash += line.primanota.hashCode();
        	tag("purpose", purpose.toString());
        	if(line.other != null) {
	        	tag("remoteAccount", line.other.number);
	        	tag("remoteBankCode", line.other.blz);
	        	tag("remoteBIC", line.other.bic);
	        	tag("remoteCountry", line.other.country);
	        	tag("remoteIBAN", line.other.iban);
	        	if(line.other.name2 == null) tag("remoteName", line.other.name);
	        	else tag("remoteName", line.other.name + line.other.name2);
	        	
	        	hash += line.other.number.hashCode();
	        	hash += line.other.blz.hashCode();
	        	if(line.other.bic != null) hash += line.other.bic.hashCode();
	        	if(line.other.iban != null) hash += line.other.iban.hashCode();
        	}
            tag("transactionCode", line.gvcode);
            tag("transactionText", line.text);
            tag("additional", line.additional);
            booleTag("isStorno", line.isStorno);
            longTag("hashNumber", hash);
        	xmlBuf.append("</cdObject>");
    	}

    	xmlBuf.append("</statements></object>");
    }
    
    public void dauerListToXml(GVRDauerList dl, Konto account) throws IOException {
    	GVRDauerList.Dauer [] standingOrders = dl.getEntries();
    	for(GVRDauerList.Dauer stord: standingOrders) {
    		
        	xmlBuf.append("<cdObject type=\"StandingOrder\">");
//        	tag("localAccount", stord.my.number);
//        	tag("localBankCode", stord.my.blz);
        	tag("currency",stord.my.curr);
        	valueTag("value", stord.value);
        	
        	// purpose
        	int i=1;
        	for(String s: stord.usage) {
        		tag("purpose"+Integer.toString(i), s);
        		i++;
        		if(i>4) break;
        	}
        	
        	// other
        	if(stord.other != null) {
	        	tag("remoteAccount", stord.other.number);
	        	tag("remoteBankCode", stord.other.blz);
	        	tag("remoteSuffix",stord.other.subnumber);
	        	if(stord.other.name2 == null) tag("remoteName", stord.other.name);
	        	else tag("remoteName", stord.other.name + stord.other.name2);
        	}
        	
        	// timeunit
        	if(stord.timeunit.compareTo("W") == 0) intTag("period", 0); else intTag("period", 1);
        	
        	// turnus
        	intTag("cycle", stord.turnus);
        	intTag("executionDay", stord.execday);
        	
        	tag("orderKey", stord.orderid);
        	
        	// exec dates
        	dateTag("firstExecDate", stord.firstdate);
        	dateTag("nextExecDate", stord.nextdate);
        	dateTag("lastExecDate", stord.lastdate);
        	
        	xmlBuf.append("</cdObject>");
    	}
    }
    
    public void termUebListToXml(GVRTermUebList ul, Konto account) throws IOException {
    	GVRTermUebList.Entry [] uebs = ul.getEntries();
    	
    	for(GVRTermUebList.Entry ueb: uebs) {
    		xmlBuf.append("<cdObject type=\"Transfer\">");
        	tag("localAccount", ueb.my.number);
        	tag("localBankCode", ueb.my.blz);
        	tag("currency",ueb.my.curr);
        	valueTag("value", ueb.value);
        	
        	// purpose
        	int i=1;
        	for(String s: ueb.usage) {
        		tag("purpose"+Integer.toString(i), s);
        		i++;
        		if(i>4) break;
        	}
        	
        	// other
        	if(ueb.other != null) {
	        	tag("remoteAccount", ueb.other.number);
	        	tag("remoteBankCode", ueb.other.blz);
	        	tag("remoteSuffix",ueb.other.subnumber);
	        	if(ueb.other.name2 == null) tag("remoteName", ueb.other.name);
	        	else tag("remoteName", ueb.other.name + ueb.other.name2);
        	}

        	// exec date
        	dateTag("date", ueb.date);
        	tag("orderKey", ueb.orderid);
        	xmlBuf.append("</cdObject>");
    	}
    }
    
    public void passportToXml(HBCIHandler handler, boolean withAccounts) throws IOException {
    	HBCIPassport pp = handler.getPassport();
    	xmlBuf.append("<object type=\"User\">");
    	tag("bankCode", pp.getBLZ());
    	tag("bankName", pp.getInstName());
    	tag("userId",pp.getUserId());
    	tag("customerId", pp.getCustomerId());
    	tag("bankURL", pp.getHost());
    	tag("port", pp.getPort().toString());
    	String filter = pp.getFilterType();
    	if(filter.compareTo("Base64") == 0) booleTag("noBase64", false); else booleTag("noBase64", true);  	
    	String version = pp.getHBCIVersion();
    	if(version.compareTo("plus") == 0) version = "220";
    	tag("hbciVersion", version);

    	if(pp instanceof HBCIPassportPinTan) {
    		HBCIPassportPinTan ppPT = (HBCIPassportPinTan)pp;
    		
        	booleTag("checkCert", ppPT.getCheckCert());
        	Properties sec = ppPT.getCurrentSecMechInfo();
        	if(sec != null)	{
        		intTag("tanMethodNumber", sec.getProperty("secfunc"));
        		tag("tanMethodDescription", sec.getProperty("name"));
        	}    		
    	}
    	
    	if(pp instanceof HBCIPassportDDV) {
    		HBCIPassportDDV ppDDV =(HBCIPassportDDV)pp;
    		tag("chipCardId", ppDDV.getCardId());
    	}
    	
    	if(withAccounts == true) {
    		xmlBuf.append("<accounts type=\"list\">");
    		Konto [] accounts = pp.getAccounts();
    		for(Konto k: accounts) {
    			accountToXml(k, handler);
    		}
    		xmlBuf.append("</accounts>");
    	}
    	
    	xmlBuf.append("</object>");    	
    }
        
    public void userToXml(User user) throws IOException {
    	xmlBuf.append("<object type=\"User\">");
    	tag("name", user.name);
    	tag("bankCode", user.bankCode);
    	tag("bankName", user.bankName);
    	tag("userId", user.userId);
    	tag("customerId", user.customerId);
    	tag("bankURL", user.host);
    	tag("port", Integer.toString(user.port));
    	String filter = user.filter;
    	if(filter.compareTo("Base64") == 0) booleTag("noBase64", false); else booleTag("noBase64", true);  	
    	String version = user.version;
    	if(version.compareTo("plus") == 0) version = "220";
    	tag("hbciVersion", version);
    	booleTag("checkCert", user.checkCert);
    	xmlBuf.append("</object>");
    }
    
    public void tanMediumToXml(TANMediaInfo info) throws IOException {
    	xmlBuf.append("<cdObject type=\"TanMedium\">");
    	tag("category", info.mediaCategory);
    	tag("status", info.status);
    	tag("cardNumber", info.cardNumber);
    	tag("cardSeqNumber", info.cardSeqNumber);
    	if(info.cardType != null) intTag("cardType", info.cardType);
    	dateTag("validFrom", info.validFrom);
    	dateTag("validTo", info.validTo);
    	tag("tanListNumber", info.tanListNumber);
    	tag("name", info.mediaName);
    	tag("mobileNumber", info.mobileNumber);
    	tag("mobileNumberSecure", info.mobileNumberSecure);
    	if(info.freeTans != null) intTag("freeTans", info.freeTans);
    	dateTag("lastUse", info.lastUse);
    	dateTag("activatedOn", info.activatedOn);
    	xmlBuf.append("</cdObject>");
    }
    
    public void tanMediaListToXml(GVRTANMediaList list) throws IOException {
    	xmlBuf.append("<object type=\"TanMediaList\">");
    	intTag("tanOption", list.getTanOption());
    	xmlBuf.append("<mediaList type=\"list\">");
		List<GVRTANMediaList.TANMediaInfo> mediaList = list.mediaList();
		for (int i=0; i<mediaList.size(); i++) {
			tanMediumToXml(mediaList.get(i));
		}
    	xmlBuf.append("</mediaList></object>");
    }
    
    public void tanMethodToXml(Properties tanMethod) throws IOException {
    	xmlBuf.append("<cdObject type=\"TanMethod\">");
		tag("method", tanMethod.getProperty("secfunc"));
		tag("identifier", tanMethod.getProperty("id"));
		tag("process", tanMethod.getProperty("process"));
		tag("zkaMethodName", tanMethod.getProperty("zkamethod_name"));
		tag("zkaMethodVersion", tanMethod.getProperty("zkamethod_version"));
		tag("name", tanMethod.getProperty("name"));
		tag("inputInfo", tanMethod.getProperty("intputinfo"));
		tag("needTanMedia", tanMethod.getProperty("needtanmedia"));
		String s = tanMethod.getProperty("maxlentan2step");
		if( s != null) intTag("maxTanLength", Integer.parseInt(s));
    	xmlBuf.append("</cdObject>");
    }
    
    public void ccBalanceToXml(GVRKKSaldoReq res) throws IOException {
    	xmlBuf.append("<object type=\"CCSaldo\">");
    	valueTag("saldo", res.saldo.value);
    	tag("currency", res.saldo.value.getCurr());
    	valueTag("amountAvailable", res.amount_available);
    	valueTag("amountPending", res.amount_pending);
    	valueTag("cardLimit", res.cardlimit);
    	dateTag("nextSettleDate", res.nextsettledate);
    	xmlBuf.append("</object>");
    }
    
    public void ccUmsToXml(GVRKKUms res) throws IOException {
    	xmlBuf.append("<object type=\"CCUms\">");
    	
    	tag("ccNumber", res.cc_number);
    	tag("ccAccount", res.cc_account);
    	dateTag("lastSettleDate", res.lastsettledate);
    	dateTag("nextSettleDate", res.nextsettledate);
    	valueTag("saldo", res.saldo.value);
    	
    	xmlBuf.append("<umsList type=\"list\">");
    	for(GVRKKUms.UmsLine ums: res.lines) {
        	xmlBuf.append("<object type=\"CCStatement\">");    		
    		dateTag("valutaDate", ums.valutaDate);
    		dateTag("postingDate", ums.postingDate);
    		dateTag("docDate", ums.docDate);
    		tag("ccNumberUms", ums.cc_number_ums);
    		valueTag("value", ums.value);
    		tag("currency", ums.value.getCurr());
    		valueTag("origValue", ums.origValue);
    		tag("origCurrency", ums.origValue.getCurr());
    		tag("customerRef", ums.customerref);
    		tag("instRef", ums.instref);
    		tag("country", ums.country);
    		booleTag("isSettled", ums.isSettled);
    		tag("reference", ums.reference);
    		tag("chargeKey", ums.chargeKey);
    		tag("chargeForeign", ums.chargeForeign);
    		tag("chargeTerminal", ums.chargeTerminal);
    		tag("settlementRef", ums.settlementReference);
    		
    		xmlBuf.append("<transactionTexts type=\"list\">");
    		for(String text: ums.transactionTexts) {
    			tag("text", text);
    		}
    		xmlBuf.append("</transactionTexts>");
    		xmlBuf.append("</object>");
    	}
    	xmlBuf.append("</umsList></object>");
    }
    
    public void ccSettleListToXml(GVRKKSettleList res) throws IOException {
    	xmlBuf.append("<object type=\"CCSettleList\">");
    	
    	tag("ccNumber", res.cc_number);
    	tag("ccAccount", res.cc_account);
    	xmlBuf.append("<settleList type=\"list\">");
    	for(GVRKKSettleList.Info info: res.settlements) {
        	xmlBuf.append("<object type=\"CCSettleInfo\">");
        	tag("settleID", info.settleID);
        	booleTag("received", info.received);
        	dateTag("settleDate", info.settleDate);
        	dateTag("firstReceive", info.firstReceive);
        	valueTag("value", info.value);
        	tag("currency", info.currency);
        	xmlBuf.append("</object>");
    	}
    	xmlBuf.append("</settleList></object>");
    }

	
}
