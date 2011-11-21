

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.OutputStreamWriter;
import java.util.List;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Date;
import java.util.Enumeration;
import java.util.Properties;
import java.util.ArrayList;
import java.io.File;
import java.io.FileInputStream;
import java.io.StringReader;

import org.kapott.hbci.callback.HBCICallbackConsole;
import org.kapott.hbci.exceptions.*;
import org.kapott.hbci.manager.HBCIHandler;
import org.kapott.hbci.manager.HBCIUtils;
import org.kapott.hbci.manager.HBCIUtilsInternal;
import org.kapott.hbci.manager.LogFilter;
import org.kapott.hbci.passport.AbstractHBCIPassport;
import org.kapott.hbci.passport.HBCIPassport;
import org.kapott.hbci.passport.HBCIPassportPinTan;
import org.kapott.hbci.passport.INILetter;
import org.kapott.hbci.structures.*;
import org.kapott.hbci.structures.*;
import org.kapott.hbci.GV.*;
import org.kapott.hbci.GV_Result.*;
import org.kapott.hbci.status.*;

import java.lang.reflect.*;
import org.xmlpull.v1.*;

public class HBCIServer {
	
	public static final int ERR_ABORTED = 0;
	public static final int ERR_GENERIC = 1;
	public static final int ERR_WRONG_PASSWD = 2;
	public static final int ERR_MISS_PARAM = 3;
	public static final int ERR_MISS_USER = 4;
	public static final int ERR_MISS_ACCOUNT = 5;
	
    private static HBCIPassport passport;
    private static HBCIHandler  hbciHandle;
    private static BufferedReader in;
    private static BufferedWriter out;
    private static StringBuffer xmlBuf;
    private static Properties map;
    private static Properties hbciHandlers;
    private static Properties accounts;
    public static String passportPath;
    private static Properties countryInfos;
    
    // should be replaced with PW-notifications to client
    private static String currentPassword = null;
    private static String password = null;
    private static Properties users = null;

	
	private static class MyCallback	extends HBCICallbackConsole
	{
		public synchronized void status(HBCIPassport passport, int statusTag, Object[] o) 
		{
		// disable status output
		}

		public void log(String msg,int level,Date date,StackTraceElement trace) {
			try {
				out.write("<log level=\""+Integer.toString(level)+"\"><![CDATA[");
				out.write(msg);
				out.write("]]></log>\n.");
				out.flush();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}

/*		
		public void log(String msg,int level,Date date,StackTraceElement trace) {
				System.err.print("<log level=\""+Integer.toString(level)+"\">");
				System.err.println(msg);
		}
*/
		
		public String callbackClient(HBCIPassport pp, String command, String msg, String def, int reason, int type) throws IOException {
			out.write("<callback command=\""+command+"\">");
			out.write("<bankCode>"+pp.getBLZ()+"</bankCode>");
			out.write("<userId>"+pp.getUserId()+"</userId>");
			out.write("<message><![CDATA["+msg+"]]></message>");
			out.write("<proposal>"+def+"</proposal>");
			out.write("<reason>"+Integer.toString(reason)+"</reason>");
			out.write("<type>"+Integer.toString(type)+"</type>");
			out.write("</callback>.");
			out.flush();
			
			String res = in.readLine();
			return res;
		}
		
	    public void callback(HBCIPassport passport, int reason, String msg, int datatype, StringBuffer retData) 
	    {
	        try {
	            String    st;
	            String def = retData.toString();
	            
	            switch(reason) {
	               	case NEED_COUNTRY: 			st = "DE"; break;
	                case NEED_BLZ: 				st = (String)map.get("bankCode"); break;
	                case NEED_HOST: 			st = (String)map.get("host"); break;
	                case NEED_PORT: 			st = (String)map.get("port"); break;
	                case NEED_FILTER: 			st = (String)map.get("filter"); break;
	                case NEED_USERID: 			st = (String)map.get("userId"); break;
	                case NEED_CUSTOMERID: 		st = (String)map.get("customerId"); break;
	                case NEED_PASSPHRASE_LOAD:  st = "PecuniaData"; break;
	                	/*
	                	if(password != null) st = password; else {
	                		st = callbackClient(passport, "password_load", msg, def, reason, datatype);
	                		currentPassword = st;
	                	}; break;
	                	*/
	                case NEED_PASSPHRASE_SAVE: 	st = "PecuniaData"; break; //st = callbackClient(passport, "password_save", msg, def, reason, datatype); break; 
	                case NEED_CONNECTION:
	                case CLOSE_CONNECTION: return;
	                case NEED_PT_SECMECH: 		st = callbackClient(passport, "getTanMethod", msg, def, reason, datatype); break;
	                case NEED_SOFTPIN:
	                case NEED_PT_PIN:			st = callbackClient(passport, "getPin", msg, def, reason, datatype); break;
	                case NEED_PT_TAN:			st = callbackClient(passport, "getTan", msg, def, reason, datatype); break;
	                case NEED_PT_TANMEDIA:		st = callbackClient(passport, "getTanMedia", msg, def, reason, datatype); break;
	                case HAVE_INST_MSG:			return;
	
	                default: System.err.println("Unhandled callback reason code: " + Integer.toString(reason)); return;
	            }
                if(st != null) {
                	if(st.equals("<abort>")) throw new AbortedException("Abbruch durch Benutzer");
                	retData.replace(0,retData.length(),st);
                }

	            
	        } catch (Exception e) {
	            throw new HBCI_Exception(HBCIUtilsInternal.getLocMsg("EXCMSG_CALLB_ERR"),e);
	        }
	    	
	    	
	    }
		
	}
	
	private static void log(String msg,int level,Date date) {
		try {
			out.write("<log level=\""+Integer.toString(level)+"\"><![CDATA[");
			out.write(msg);
			out.write("]]></log>\n.");
			out.flush();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	private static String passportKey(Properties map, String command) throws IOException
	{
		String bankCode = getParameter(map, "bankCode");
		String userId = getParameter(map, "userId");
		return passportKey(bankCode, userId);
	}
	
	public static String passportKey(String bankCode, String userId) {
		return bankCode + "_" + userId;
	}
	
	private static String getParameter(Properties aMap, String parameter) throws IOException {
		String ret = aMap.getProperty(parameter);
		if(ret == null) throw new HBCIParamException(parameter);
		return ret;
	}

    private static void initHBCI() {
        HBCIUtils.init(null,new MyCallback());
        
        // Basic Params
        HBCIUtils.setParam("client.connection.localPort",null);
        HBCIUtils.setParam("log.loglevel.default","5");
        
        //Passport
        HBCIUtils.setParam("client.passport.default","PinTan");
        HBCIUtils.setParam("client.passport.PinTan.checkcert","1");
        HBCIUtils.setParam("client.passport.PinTan.certfile",null);
        HBCIUtils.setParam("client.passport.PinTan.proxy",null);
        HBCIUtils.setParam("client.passport.PinTan.proxyuser",null);
        HBCIUtils.setParam("client.passport.PinTan.proxypass",null);
        HBCIUtils.setParam("client.passport.PinTan.init","1");
//        HBCIUtils.setParam("client.retries.passphrase","0");
        HBCIUtils.setParam("client.passport.hbciversion.default","plus");
        
        // get countries
        String countryPath = "/CountryInfo.txt";
        InputStream f=HBCIServer.class.getResourceAsStream(countryPath);
        BufferedReader fin = new BufferedReader(new InputStreamReader(f));
        String s;
        try {
			while((s = fin.readLine()) != null && s.length() != 0) {
				String[] info = s.split(";", 0);
				countryInfos.put(info[1], info);
			}
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
    }
    
    private static String escapeSpecial(String s) {
    	String r = s.replaceAll("&", "&amp;");
    	r = r.replaceAll("<", "&lt;");
    	r = r.replaceAll(">", "&gt;");
    	r = r.replaceAll("\"", "&quot;");
    	r = r.replaceAll("'", "&apos;");
    	return r;
    }
    
    private static void tag(String tag, String value) throws IOException {
    	if(value == null) return;
    	xmlBuf.append("<"+tag+">"+escapeSpecial(value)+"</"+tag+">");
    }
    
    private static void valueTag(String tag, Value value) {
    	if(value == null) return;
    	xmlBuf.append("<"+tag+" type=\"value\">"+Long.toString(value.getLongValue())+"</"+tag+">");
    }
    
    private static void longTag(String tag, long l) {
    	xmlBuf.append("<"+tag+" type=\"long\">"+Long.toString(l)+"</"+tag+">");
    }
    
    private static void dateTag(String tag, Date date) {
    	if(date == null) return;
    	xmlBuf.append("<"+tag+" type=\"date\">"+HBCIUtils.date2StringISO(date)+"</"+tag+">");
    }
    
    private static void intTag(String tag, String value) {
    	xmlBuf.append("<"+tag+" type=\"int\">"+value+"</"+tag+">");
    }

    private static void intTag(String tag, int value) {
    	xmlBuf.append("<"+tag+" type=\"int\">"+Integer.toString(value)+"</"+tag+">");
    }

    
    private static void booleTag(String tag, boolean b) {
    	if(b) xmlBuf.append("<"+tag+" type=\"boole\">yes</"+tag+">");
    	else xmlBuf.append("<"+tag+" type=\"boole\">no</"+tag+">");
    }
        
    private static void accountToXml(Konto account, HBCIPassport pp) throws IOException {
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
    	xmlBuf.append("</object>");
    }
    
    private static void umsToXml(GVRKUms ums, Konto account) throws IOException {
//    	ArrayList<GVRKUms.UmsLine> lines = (ArrayList)ums.getFlatData();
    	List lines = ums.getFlatData();
    	if(lines.isEmpty()) return;
    	long hash;
    	for(Iterator i = lines.iterator(); i.hasNext(); ) {
    		hash = 0;
    		GVRKUms.UmsLine line = (GVRKUms.UmsLine)i.next();
    		
    		StringBuffer purpose = new StringBuffer();
    		if(line.gvcode.equals("999")) {
    			purpose.append(line.additional);
    			hash += line.additional.hashCode();
    		}
    		else {
	    		for(Iterator j = line.usage.iterator(); j.hasNext();) {
	    			String s = (String)j.next();
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
    }
    
    private static void dauerListToXml(GVRDauerList dl, Konto account) throws IOException {
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
    
    private static void passportToXml(HBCIPassportPinTan pp) throws IOException {
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
    	booleTag("checkCert", pp.getCheckCert());
    	Properties sec = pp.getCurrentSecMechInfo();
    	if(sec != null)	{
    		intTag("tanMethodNumber", sec.getProperty("secfunc"));
    		tag("tanMethodDescription", sec.getProperty("name"));
    	}
    	    	
    	xmlBuf.append("</object>");
    }
    
    private static void userToXml(User user) throws IOException {
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
		intTag("tanMethodNumber", user.tanMethod);
		tag("tanMethodDescription", user.tanMethodDescription);    	    	
    	xmlBuf.append("</object>");
    }
    
    private static HBCIHandler hbciHandler(String bankCode, String userId) {
    	String fname = passportKey(bankCode, userId);
    	String altName = null;
		HBCIHandler handler = (HBCIHandler)hbciHandlers.get(fname);
		if(handler == null) {
			// check if passport file exists
			String filePath = passportPath + "/" + fname + ".dat";
			HBCIUtils.log("HBCIServer: open passort: "+filePath, HBCIUtils.LOG_DEBUG);
			File file = new File(filePath);
			if(file.exists() == false) {
				HBCIUtils.log("HBCIServer: passport file "+filePath+" not found, checking alternatives", HBCIUtils.LOG_DEBUG);
				
				boolean found = false;
				// check if there is a passport file with userID and different bank code
				for(Enumeration e = users.keys(); e.hasMoreElements(); ) {
					String key  = (String)e.nextElement();
					if(key.endsWith(userId)) {
						// we found an alternative passport that could fit
						
						filePath = passportPath + "/" + key + ".dat";
						HBCIUtils.log("HBCIServer: try alternative passort: "+filePath, HBCIUtils.LOG_DEBUG);
						file = new File(filePath);
						if(file.exists() == true) {
							found = true;
							altName = key;
							HBCIUtils.log("HBCIServer: alternative passport file "+filePath+" found", HBCIUtils.LOG_DEBUG);
							break;
						}						
					}
				}
				if(found == false) {
					HBCIUtils.log("HBCIServer: alternative passport file "+filePath+" not found!", HBCIUtils.LOG_DEBUG);
					return null;					
				}				
			}

			HBCIUtils.setParam("client.passport.PinTan.filename",filePath);
	        HBCIPassport passport=AbstractHBCIPassport.getInstance();
	        HBCIHandler hbciHandle=new HBCIHandler(null, passport);
	        if(hbciHandle == null) {
				HBCIUtils.log("HBCIServer: failed to create passport from file "+filePath+"!", HBCIUtils.LOG_ERR);
				return null;
	        }
	        // we currently support only one User per BLZ
	        hbciHandlers.put(fname, hbciHandle);
	        if(altName != null) hbciHandlers.put(altName, hbciHandle);
			HBCIUtils.log("HBCIServer: passport created for bank code "+bankCode+", user "+userId, HBCIUtils.LOG_DEBUG);
	        return hbciHandle;
		}
		return handler;
    }
    
	
	private static void addPassport() throws IOException {
		String filename = passportKey(map, "addPassport");
		if(filename == null) return;
		String filePath = passportPath + "/" + filename + ".dat";
        HBCIUtils.setParam("client.passport.PinTan.filename",filePath);
        
        String checkCert = map.getProperty("checkCert");
        if(checkCert != null && checkCert.equals("no")) {
        	HBCIUtils.setParam("client.passport.PinTan.checkcert", "0");
        } else {
        	HBCIUtils.setParam("client.passport.PinTan.checkcert", "1");
        }
        passport=AbstractHBCIPassport.getInstance();
        HBCIUtils.setParam("action.resetBPD","1");
        HBCIUtils.setParam("action.resetUPD","1");
        
//    	passport.clearBPD();
//    	passport.clearUPD();
        try {
        	String version = map.getProperty("version");
        	if(version.compareTo("220") == 0) version = "plus";
        	hbciHandle=new HBCIHandler(version, passport);
        }
        catch(HBCI_Exception e) {
        	File ppFile = new File(filePath);
        	ppFile.delete();
        	throw e;
        }
        
        hbciHandlers.put(filename, hbciHandle);
        
        
        // User-Infos schreiben
        String name = getParameter(map, "name");
        User user = User.createFromHBCI((HBCIPassportPinTan)passport, name);
        user.save();
        users.put(filename, user);
        
        xmlBuf.append("<result name=\"addPassport\">");
		passportToXml((HBCIPassportPinTan)passport);
        xmlBuf.append("</result>.");
		out.write(xmlBuf.toString());
        out.flush();
 	}
	
	private static void deletePassport() throws IOException {
		String filename = passportKey(map, "deletePassport");
		if(filename == null) return;
	
		hbciHandlers.remove(filename);
		
		// remove the passport file
		String filePath = passportPath + "/" + filename + ".dat";
    	File ppFile = new File(filePath);
    	ppFile.delete();
    	
    	// remove user file
		filePath = passportPath + "/" + filename + ".ser";
    	ppFile = new File(filePath);
    	ppFile.delete();
    	users.remove(filename);
    	
        xmlBuf.append("<result name=\"deletePassport\">");
        xmlBuf.append("</result>.");
		out.write(xmlBuf.toString());
        out.flush();
	}
	
	private static void getAllStatements() throws IOException {
		Properties orders = new Properties();
		
		// first collect all orders separated by handlers
		ArrayList list = (ArrayList)map.get("accinfolist");
		if(list.size() == 0) {
			HBCIUtils.log("HBCIServer: getStatement called without accounts", HBCIUtils.LOG_DEBUG);
		}
		for(int i=0; i<list.size(); i++) {
			Properties tmap = (Properties)list.get(i);
			String bankCode = getParameter(tmap, "accinfo.bankCode");
			String userId = getParameter(tmap, "accinfo.userId");
			String accountNumber = getParameter(tmap, "accinfo.accountNumber");
			
			HBCIHandler handler = hbciHandler(bankCode, userId);
			if(handler == null) {
				HBCIUtils.log("HBCIServer: getStatements skips bankCode "+bankCode+" user "+userId, HBCIUtils.LOG_DEBUG);
				continue;
			}
			GVKUmsAll job = (GVKUmsAll)handler.newJob("KUmsAll");
			Konto account = (Konto)accounts.get(bankCode+accountNumber);
			if(account == null) {
				account = handler.getPassport().getAccount(accountNumber);
				if(account == null) {
					HBCIUtils.log("HBCIServer: getStatements skips account "+accountNumber, HBCIUtils.LOG_DEBUG);
					continue;
				}
			}
			job.setParam("my", account);
			String fromDateString = tmap.getProperty("accinfo.fromDate");
			if(fromDateString != null) {
				Date fromDate = HBCIUtils.string2DateISO(fromDateString);
				if(fromDate != null) {
					job.setParam("startdate", fromDate);
				}
			}
			HBCIUtils.log("HBCIServer: getStatements customerId: "+account.customerid, HBCIUtils.LOG_DEBUG);
			if(account.customerid == null) job.addToQueue();
			else job.addToQueue(account.customerid);
			ArrayList<Properties> jobs = (ArrayList<Properties>)orders.get(handler);
			if(jobs == null) {
				jobs = new ArrayList<Properties>();
				orders.put(handler, jobs);
			}
			Properties jobacc = new Properties();
			jobacc.put("job", job);
			jobacc.put("account", account);
			jobs.add(jobacc);
			
		}
		
		// now iterate through orders
		if(orders.size() == 0) {
			HBCIUtils.log("HBCIServer: getStatements: there are no orders!", HBCIUtils.LOG_DEBUG);			
		}
		for(Enumeration e = orders.keys(); e.hasMoreElements(); ) {
			HBCIHandler handler = (HBCIHandler)e.nextElement();
			ArrayList<Properties> jobs = (ArrayList<Properties>)orders.get(handler);
			
			HBCIExecStatus status = handler.execute();
			if(status.isOK()) {
				for(Properties jobacc: jobs) {
					GVKUmsAll job = (GVKUmsAll)jobacc.get("job");
					Konto account = (Konto)jobacc.get("account");
					GVRKUms res = (GVRKUms)job.getJobResult();
					if(res.isOK()) {
				    	xmlBuf.append("<object type=\"BankQueryResult\">");
				    	tag("bankCode", account.blz);
				    	tag("accountNumber", account.number);
				    	xmlBuf.append("<statements type=\"list\">");
						umsToXml(res, account);
						xmlBuf.append("</statements></object>");
					}
					
				}
			}
		}
		out.write("<result command=\"getAllStatements\">");
		out.write("<list>");
		out.write(xmlBuf.toString());
		out.write("</list>");
		out.write("</result>.");
		out.flush();
	}

	
	private static void getAllStandingOrders() throws IOException {
		Properties orders = new Properties();
		
		// first collect all orders separated by handlers
		ArrayList list = (ArrayList)map.get("accinfolist");
		for(int i=0; i<list.size(); i++) {
			Properties tmap = (Properties)list.get(i);
			String bankCode = getParameter(tmap, "accinfo.bankCode");
			String userId = getParameter(tmap, "accinfo.userId");
			String accountNumber = getParameter(tmap, "accinfo.accountNumber");
			
			HBCIHandler handler = hbciHandler(bankCode, userId);
			if(handler == null) continue;
			GVDauerList job = (GVDauerList)handler.newJob("DauerList");
			Konto account = (Konto)accounts.get(bankCode+accountNumber);
			if(account == null) {
				account = handler.getPassport().getAccount(accountNumber);
				if(account == null) continue;
			}
			job.setParam("my", account);
			if(account.customerid == null) job.addToQueue();
			else job.addToQueue(account.customerid);
			ArrayList<Properties> jobs = (ArrayList<Properties>)orders.get(handler);
			if(jobs == null) {
				jobs = new ArrayList<Properties>();
				orders.put(handler, jobs);
			}
			Properties jobacc = new Properties();
			jobacc.put("job", job);
			jobacc.put("account", account);
			jobs.add(jobacc);
			
		}
		
		// now iterate through orders
		for(Enumeration e = orders.keys(); e.hasMoreElements(); ) {
			HBCIHandler handler = (HBCIHandler)e.nextElement();
			ArrayList<Properties> jobs = (ArrayList<Properties>)orders.get(handler);
			
			HBCIExecStatus status = handler.execute();
			if(status.isOK()) {
				for(Properties jobacc: jobs) {
					GVDauerList job = (GVDauerList)jobacc.get("job");
					Konto account = (Konto)jobacc.get("account");
					GVRDauerList res = (GVRDauerList)job.getJobResult();
					if(res.isOK()) {
				    	xmlBuf.append("<object type=\"BankQueryResult\">");
				    	tag("bankCode", account.blz);
				    	tag("accountNumber", account.number);
				    	xmlBuf.append("<standingOrders type=\"list\">");
						dauerListToXml(res, account);
						xmlBuf.append("</standingOrders></object>");
					}
				}
			}
		}
		out.write("<result command=\"getAllStandingOrders\">");
		out.write("<list>");
		out.write(xmlBuf.toString());
		out.write("</list>");
		out.write("</result>.");
		out.flush();
	}

/*	
	private static void getStandingOrders() throws IOException {
		String bankCode = getParameter(map, "bankCode");
		String userId = getParameter(map, "userId");
		String accountNumber = getParameter(map, "accountNumber");
		
		HBCIHandler handler = (HBCIHandler)hbciHandlers.get(passportKey(bankCode, userId));
		if(handler == null) {
			error(ERR_MISS_USER, "getStandingOrders", userId);
			return;
		}
		
		GVDauerList job = (GVDauerList)handler.newJob("DauerList");
		Konto account = (Konto)accounts.get(bankCode+accountNumber);
		if(account == null) {
			account = handler.getPassport().getAccount(accountNumber);
			if(account == null) {
				error(ERR_MISS_ACCOUNT, "getStandingOrders", accountNumber);
				return;
			}
		}
		job.setParam("my", account);
		if(account.customerid == null) job.addToQueue();
		else job.addToQueue(account.customerid);

		HBCIExecStatus status = handler.execute();
		if(status.isOK()) {
			GVRDauerList res = (GVRDauerList)job.getJobResult();
			if(res.isOK()) {
				dauerListToXml(res, account);
			}
		}
		out.write("<result command=\"getAllStandingOrders\">");
		out.write("<list>");
		out.write(xmlBuf.toString());
		out.write("</list>");
		out.write("</result>.");
		out.flush();
	}
*/	
	
	private static void sendTransfers() throws IOException {
		Properties orders = new Properties();
		HashSet<HBCIHandler> handlers = new HashSet<HBCIHandler>();
		String gvCode=null;
		
		// first collect all orders separated by handlers
		ArrayList<Properties> list = (ArrayList<Properties>)map.get("transfers");
		for(Properties map: list) {
			String bankCode = getParameter(map, "transfer.bankCode");
			String userId = getParameter(map, "transfer.userId");
			String accountNumber = getParameter(map, "transfer.accountNumber");
			
			HBCIHandler handler = hbciHandler(bankCode, userId);
			if(handler == null) {
				System.err.println("No HBCI Handler for bank: " + bankCode + ", user: " + userId);
				continue;
			}
			// delete all unsent transfers from previous calls
			if(!handlers.contains(handler)) {
				handler.reset();
				handlers.add(handler);
			}
			Konto account = (Konto)accounts.get(bankCode+accountNumber);
			if(account == null) {
				account = handler.getPassport().getAccount(accountNumber);
				if(account == null) continue;
			}
			
			String transferType = getParameter(map, "transfer.type");
			if(transferType.equals("standard")) gvCode = "Ueb";
			else if(transferType.equals("dated")) gvCode = "TermUeb"; 
			else if(transferType.equals("internal")) gvCode = "Umb";
			else if(transferType.equals("foreign")) gvCode = "UebForeign";
			
			HBCIJob job = handler.newJob(gvCode);
			job.setParam("src", account);

			// Gegenkonto
			if(!transferType.equals("foreign")) {
				Konto dest = new Konto(	getParameter(map, "transfer.remoteCountry"),
				getParameter(map, "transfer.remoteBankCode"),
				getParameter(map, "transfer.remoteAccount"));
				job.setParam("dst", dest);

				// RemoteName
				String remoteName = getParameter(map, "transfer.remoteName");
				if(remoteName.length() > 27) {
					job.setParam("name", remoteName.substring(0, 27));
					job.setParam("name2", remoteName.substring(27));
				} else job.setParam("name", remoteName);
				
			} else {
				job.setParam("dst.iban", getParameter(map, "transfer.iban"));
				job.setParam("dst.kiname", getParameter(map, "transfer.bankName"));
				job.setParam("dst.name", getParameter(map, "transfer.remoteName"));
			}
			long val = Long.decode(getParameter(map, "transfer.value"));
			job.setParam("btg", new Value(val, getParameter(map, "transfer.currency")));
			
			String purpose = getParameter(map, "transfer.purpose1");
			if(purpose != null) job.setParam("usage", purpose);
			purpose = map.getProperty("transfer.purpose2");
			if(purpose != null) job.setParam("usage_2", purpose);
			purpose = map.getProperty("transfer.purpose3");
			if(purpose != null) job.setParam("usage_3", purpose);
			purpose = map.getProperty("transfer.purpose4");
			if(purpose != null) job.setParam("usage_4", purpose);

			if(transferType.equals("dated")) {
				Date date = HBCIUtils.string2DateISO(getParameter(map, "transfer.valutaDate"));
				job.setParam("date", date);
			}
			
			job.addToQueue();
			ArrayList<Properties> jobs = (ArrayList<Properties>)orders.get(handler);
			if(jobs == null) {
				jobs = new ArrayList<Properties>();
				orders.put(handler, jobs);
			}
			Properties jobParam = new Properties();
			jobParam.put("job", job);
			jobParam.put("id", map.getProperty("transfer.transferId"));
			jobParam.put("type", transferType);
			jobs.add(jobParam);
		}
		
		// now iterate through orders
		for(Enumeration e = orders.keys(); e.hasMoreElements(); ) {
			HBCIHandler handler = (HBCIHandler)e.nextElement();
			ArrayList<Properties> jobs = (ArrayList<Properties>)orders.get(handler);
			
			HBCIExecStatus stat = handler.execute();
			
			for(Properties jobParam: jobs) {
				HBCIJob job = (HBCIJob)jobParam.get("job");
				HBCIJobResult res = job.getJobResult();
		    	xmlBuf.append("<object type=\"TransferResult\">");
		    	tag("transferId", jobParam.getProperty("id"));
		    	booleTag("isOk", res.isOK());
				xmlBuf.append("</object>");
			}
		}

		out.write("<result command=\"sendTransfers\">");
		out.write("<list>");
		out.write(xmlBuf.toString());
		out.write("</list>");
		out.write("</result>.");
		out.flush();
	}
	
	private static void handleStandingOrder(String jobName, String cmd) throws IOException {
		String bankCode = getParameter(map, "bankCode");
		String userId = getParameter(map, "userId");
		String accountNumber = getParameter(map, "accountNumber");
		String orderId = null;
		
		HBCIHandler handler = hbciHandler(bankCode, userId);
		if(handler == null) {
			error(ERR_MISS_USER, cmd, userId);
			return;
		}
		
		Konto account = (Konto)accounts.get(bankCode+accountNumber);
		if(account == null) {
			account = handler.getPassport().getAccount(accountNumber);
			if(account == null) {
				error(ERR_MISS_ACCOUNT, cmd,accountNumber);
				return;
			}
		}
		
		HBCIJob job = handler.newJob(jobName);
		job.setParam("src", account);
		
		Konto dest = new Konto(	getParameter(map, "remoteCountry"),
		getParameter(map, "remoteBankCode"),
		getParameter(map, "remoteAccount"));
		job.setParam("dst", dest);

		// RemoteName
		String remoteName = getParameter(map, "remoteName");
		if(remoteName.length() > 27) {
			job.setParam("name", remoteName.substring(0, 27));
			job.setParam("name2", remoteName.substring(27));
		} else job.setParam("name", remoteName);
				
		long val = Long.decode(getParameter(map, "value"));
		job.setParam("btg", new Value(val, getParameter(map, "currency")));
		
		String purpose = getParameter(map, "purpose1");
		if(purpose != null) job.setParam("usage", purpose);
		purpose = map.getProperty("purpose2");
		if(purpose != null) job.setParam("usage_2", purpose);
		purpose = map.getProperty("purpose3");
		if(purpose != null) job.setParam("usage_3", purpose);
		purpose = map.getProperty("purpose4");
		if(purpose != null) job.setParam("usage_4", purpose);
		
		Date date = HBCIUtils.string2DateISO(getParameter(map, "firstExecDate"));
		job.setParam("firstdate", date);
		String lastExecDate = map.getProperty("lastExecDate");
		if(lastExecDate != null) {
			date = HBCIUtils.string2DateISO(lastExecDate);
			job.setParam("lastdate", date);
		}
		job.setParam("timeunit", getParameter(map,"timeUnit"));
		job.setParam("turnus", Integer.parseInt(getParameter(map,"turnus")));
		job.setParam("execday", Integer.parseInt(getParameter(map,"executionDay")));

		if(jobName.compareTo("DauerEdit") == 0) {
			orderId = getParameter(map, "orderId");
			job.setParam("orderid", orderId);
		}
		if(jobName.compareTo("DauerDel") == 0) {
			orderId = map.getProperty("orderId");
			if(orderId != null) job.setParam("orderid", orderId);
		}
		
		job.addToQueue();
		HBCIExecStatus stat = handler.execute();
		
		boolean isOk = false;
		if(jobName.compareTo("DauerNew") == 0) {
			GVRDauerNew res = null;
			if(stat.isOK()) {
				res = (GVRDauerNew)job.getJobResult();
				if(res.isOK()) isOk = true;
			}
			xmlBuf.append("<result command=\"addStandingOrder\"><dictionary>");
			booleTag("isOk", isOk);
			if(res != null && isOk) tag("orderId", res.getOrderId());
			xmlBuf.append("</dictionary></result>.");
		} else {
			HBCIJobResult res = null;
			if(stat.isOK()) {
				res = (HBCIJobResult)job.getJobResult();
				if(res.isOK()) isOk = true;
			}
			xmlBuf.append("<result command=\""+cmd+"\">");
			booleTag("isOk", isOk);
			xmlBuf.append("</result>.");
		}
		out.write(xmlBuf.toString());
		out.flush();
	}
	
	private static void addStandingOrder() throws IOException {
		handleStandingOrder("DauerNew", "addStandingOrder");
	}
	
	private static void changeStandingOrder() throws IOException {
		handleStandingOrder("DauerEdit", "changeStandingOrder");
	}
	
	private static void deleteStandingOrder() throws IOException {
		handleStandingOrder("DauerDel", "deleteStandingOrder");		
	}
	
	private static void init() throws IOException {
		// global inits
		initHBCI();
		hbciHandlers = new Properties();
//		ArrayList<HBCIPassport> result = new ArrayList<HBCIPassport>();
		ArrayList<User> result = new ArrayList<User>();

		passportPath = getParameter(map, "path");

		// load all available passports
		if(passportPath == null) {
			error(ERR_MISS_PARAM,"init", "Pfad");
			return;
		}
		File dir = new File(passportPath);
		String [] files = dir.list();
		if(files != null) {
			
			for(int i=0; i<files.length; i++) {
				String fname = files[i];
				if(!fname.endsWith(".ser")) continue;
				fname = passportPath + "/" + fname;

				FileInputStream userFile = new FileInputStream( fname );
			    ObjectInputStream o = new ObjectInputStream( userFile );
			    try {
				    User user = (User)o.readObject();
				    
				    // check if passport file exists as well
				    String filename = passportKey(user.bankCode, user.userId);
				    String ppPath = passportPath + "/" + filename + ".dat";
				    File ppFile = new File(ppPath);
				    if(ppFile.exists() == true) {
				    	result.add(user);
				    	users.put(filename, user);
				    }
			    } 
			    catch (ClassNotFoundException e) {
			    	System.err.println( e );
			    }
			}
			
			// Passport so spät wie möglich instanziieren
/*			
			for(int i=0; i<files.length; i++) {
				String fname = files[i];
				if(!fname.endsWith(".dat")) continue;
				fname = passportPath + "/" + fname;
		        HBCIUtils.setParam("client.passport.PinTan.filename",fname);
		        HBCIPassport passport=AbstractHBCIPassport.getInstance();
		        HBCIHandler hbciHandle=new HBCIHandler(null, passport);
		        // we currently support only one User per BLZ
		        hbciHandlers.put(passportKey(passport.getBLZ(), passport.getUserId()), hbciHandle);
		        result.add(passport);
		        if(password == null && currentPassword != null) password = currentPassword;
				currentPassword = null;

				//		        System.out.println(hbciHandle.getLowlevelJobRestrictions("Ueb").toString());
//		        System.out.println(((HBCIPassportPinTan)passport).getCurrentSecMechInfo().toString());
			}
*/			
		}
/*		
		// Read user descriptions
		try {
			FileInputStream istream = new FileInputStream(passportPath+"/UserInfos.conf");
			userInfos.load(istream);
			istream.close();
		}
		catch (IOException e) {
			// do nothing
		}
*/		
		password = null;
		// return list of registered users
		xmlBuf.append("<result command=\"init\">");
		xmlBuf.append("<list>");
		for(int i=0; i<result.size(); i++) {
			userToXml(result.get(i));
//			passportToXml((HBCIPassportPinTan)result.get(i));
		}
		xmlBuf.append("</list>");
		xmlBuf.append("</result>.");
		out.write(xmlBuf.toString());
		out.flush();
	}
	
	private static void getAccounts() throws IOException {
		ArrayList<Konto> accounts = new ArrayList<Konto>();
		String bankCode = getParameter(map, "bankCode");
		String userId = getParameter(map, "userId");

		xmlBuf.append("<result command=\"getAccounts\">");
		xmlBuf.append("<list>");
		if(bankCode.compareTo("*") == 0) {				// not used up to now
			Enumeration keys = hbciHandlers.keys();
			if(keys != null) {
				while(keys.hasMoreElements()) {
					String key = (String)keys.nextElement();
					// todo
					HBCIHandler handler = (HBCIHandler)hbciHandlers.get(key);
					if(handler != null) {
						HBCIPassport pp = handler.getPassport();
						Konto [] accs = pp.getAccounts();
						for(Konto k: accs) accountToXml(k, pp);
					}
				} 
			}
		} else {
			HBCIHandler handler = hbciHandler(bankCode, userId);
			if(handler != null) {
				HBCIPassport pp = handler.getPassport();
				Konto [] accs = pp.getAccounts();
				for(Konto k: accs) accountToXml(k, pp);
			} else {
				error(ERR_MISS_USER, "getAccounts", userId);
				return;
			}
		}
		
		xmlBuf.append("</list>");
		xmlBuf.append("</result>.");
		out.write(xmlBuf.toString());
		out.flush();
	}
	
	private static void getBankInfo() throws IOException {
		String bankCode = getParameter(map, "bankCode");
		String data = HBCIUtilsInternal.getBLZData(bankCode);
        String[] parts=data.split("\\|");
		xmlBuf.append("<result command=\"getBankInfo\">");
    	xmlBuf.append("<object type=\"BankInfo\">");
		tag("bankCode", bankCode);
		if(parts.length > 0) tag("name", parts[0]);
		if(parts.length > 2) tag("bic", parts[2]);
		if(parts.length > 4)tag("host", parts[4]);
		if(parts.length > 5) tag("pinTanURL", parts[5]);
		if(parts.length > 7) tag("pinTanVersion", parts[7]);
		xmlBuf.append("</object>");
		xmlBuf.append("</result>.");
		out.write(xmlBuf.toString());
		out.flush();
	}
	
	private static void checkAccount() throws IOException {
		boolean result = true;
		String bankCode = map.getProperty("bankCode");
		if(bankCode != null) {
			String accountNumber = map.getProperty("accountNumber");
			if(HBCIUtils.checkAccountCRC(bankCode, accountNumber) == false) result = false;
		}
		String iban = map.getProperty("iban");
		if(iban != null) {
			if(HBCIUtils.checkIBANCRC(iban) == false) result = false;
		}

		xmlBuf.append("<result command=\"checkAccount\">");
		booleTag("checkResult", result);
		xmlBuf.append("</result>.");
		out.write(xmlBuf.toString());
		out.flush();
	}
	
	private static void setAccount() throws IOException {
		String bankCode = getParameter(map, "bankCode");
		String userId = getParameter(map, "userId");
		String accountNumber = getParameter(map, "accountNumber");
		
		// first check if there is a valid user
		String key = passportKey(bankCode, userId);
		User user = (User)users.get(key);
		if(user != null) {
			Konto acc = (Konto)accounts.get(bankCode+accountNumber);
			if(acc == null) {
				acc = new Konto(getParameter(map, "country"), bankCode, accountNumber);
				acc.curr = map.getProperty("currency");
				if (acc.curr == null) acc.curr = "EUR";
				acc.bic = map.getProperty("bic");
				acc.customerid = map.getProperty("customerId");
				acc.iban = map.getProperty("iban");
				acc.name = map.getProperty("ownerName");
				acc.type = map.getProperty("name");
				accounts.put(bankCode+accountNumber, acc);
			}
		}
		
		xmlBuf.append("<result command=\"setAccount\">");
		booleTag("checkResult", true);
		xmlBuf.append("</result>.");
		out.write(xmlBuf.toString());
		out.flush();
	}
	
	private static void changeAccount() throws IOException {
		String bankCode = getParameter(map, "bankCode");
		String userId = getParameter(map, "userId");
		String accountNumber = getParameter(map, "accountNumber");
		
		// first check if there is a valid passport
		String key = passportKey(bankCode, userId);
		User user = (User)users.get(key);
		if(user != null) {
			Konto acc = (Konto)accounts.get(bankCode+accountNumber);
			if(acc != null) {
				acc.bic = map.getProperty("bic");
				acc.iban = map.getProperty("iban");
				acc.name = getParameter(map, "ownerName");
				acc.type = map.getProperty("name");
			}
		}
		
		xmlBuf.append("<result command=\"changeAccount\">");
		booleTag("checkResult", true);
		xmlBuf.append("</result>.");
		out.write(xmlBuf.toString());
		out.flush();
	}
	
	private static void getJobRestrictions() throws IOException {
		String bankCode = getParameter(map, "bankCode");
		String userId = getParameter(map, "userId");
		String jobName = getParameter(map, "jobName");

		HBCIHandler handler = hbciHandler(bankCode, userId);
		if(handler != null) {
			HBCIJob job = handler.newJob(jobName);
			Properties props = job.getJobRestrictions();
			ArrayList<String> textKeys = new ArrayList<String>();
			ArrayList<String> countryRestrictions = new ArrayList<String>();
			for(Enumeration e = props.keys(); e.hasMoreElements(); ) {
				String key = (String)e.nextElement();
				if(key.startsWith("key")) textKeys.add(props.getProperty(key)); else
				if(key.startsWith("countryinfo")) {
					String s = props.getProperty(key);
					int i = s.indexOf(";");
					String countryNum = s.substring(0, i);
					String [] cInfos = (String[])countryInfos.get(countryNum);
					if(cInfos == null) {
						System.err.println("Not supported country: " + countryNum);
						continue;
					}
					String countryId = cInfos[2];
					countryRestrictions.add(countryId+";"+s);
				} else
					tag(key, props.getProperty(key));
			}
			xmlBuf.append("<textKeys type=\"list\">");
			for(String k: textKeys) tag("key", k);
			xmlBuf.append("</textKeys>");
			xmlBuf.append("<countryInfos type=\"list\">");
			for(String k: countryRestrictions) tag("info", k);
			xmlBuf.append("</countryInfos>");
			
		}
		out.write("<result command=\"getJobRestrictions\"><dictionary>");
		out.write(xmlBuf.toString());
		out.write("</dictionary></result>.");
		out.flush();
	}
	
	private static void getBankParameter() throws IOException {
		String bankCode = getParameter(map, "bankCode");
		String userId = getParameter(map, "userId");
		HBCIHandler handler = hbciHandler(bankCode, userId);
		if(handler == null) {
			error(ERR_MISS_USER, "getBankParameter", userId);
			return;
		}
		HBCIPassport passport = handler.getPassport();
		xmlBuf.append("<result command=\"getBankParameter\"><object type=\"BankParameter\">");
		Properties bpd = passport.getBPD();
		xmlBuf.append("<bpd type=\"dictionary\">");
		for(Enumeration e = bpd.keys(); e.hasMoreElements(); ) {
			String key = (String)e.nextElement();
			tag(key, bpd.getProperty(key));
		}
		xmlBuf.append("</bpd>");
		xmlBuf.append("<upd type=\"dictionary\">");
		Properties upd = passport.getUPD();
		for(Enumeration e = upd.keys(); e.hasMoreElements(); ) {
			String key = (String)e.nextElement();
			tag(key, upd.getProperty(key));
		}
		xmlBuf.append("</upd>");
		xmlBuf.append("</object></result>.");
		out.write(xmlBuf.toString());
		out.flush();
	}
	
	private static void isJobSupported() throws IOException {
		String bankCode = getParameter(map, "bankCode");
		String accountNumber = getParameter(map, "accountNumber");
		String userId = getParameter(map, "userId");
		String jobName = getParameter(map, "jobName");
		boolean supp = false;

		HBCIHandler handler = hbciHandler(bankCode, userId);
		if(handler != null) {
			HBCIPassport passport = handler.getPassport();
			
			// general purpose: get supported GVs for each account - should be separated later
			Properties upd = passport.getUPD();
			Properties gvs = new Properties();
			Properties accNums = new Properties();
			for(Enumeration e = upd.keys(); e.hasMoreElements(); ) {
				String key = (String)e.nextElement();
				if(key.matches("KInfo\\w*.AllowedGV\\w*.code")) {
					String accKey = key.substring(0, key.indexOf('.'));
					ArrayList<String> gvcodes= (ArrayList<String>)gvs.get(accKey);
					if(gvcodes == null) {
						gvcodes = new ArrayList<String>();
						gvs.put(accKey, gvcodes);
					}
					gvcodes.add((String)upd.get(key));
				} else if(key.matches("KInfo\\w*.KTV.number")) {
					String accKey = key.substring(0, key.indexOf('.'));
					accNums.put(accKey, upd.get(key));
				}
				
			}
			// now merge it
			for(Enumeration e = accNums.keys(); e.hasMoreElements(); ) {
				String key = (String)e.nextElement();
				ArrayList<String> gvcodes= (ArrayList<String>)gvs.get(key);
				if(gvcodes != null) gvs.put(accNums.get(key), gvcodes);
				gvs.remove(key);
			}

			ArrayList<String> gvcodes = (ArrayList<String>)gvs.get(accountNumber);
			if(gvcodes != null) {
				if(jobName.equals("Ueb")) supp = gvcodes.contains("HKUEB");
				else if(jobName.equals("TermUeb")) supp = gvcodes.contains("HKTUE");
				else if(jobName.equals("UebForeign")) supp = gvcodes.contains("HKAOM");
				else if(jobName.equals("Umb")) supp = gvcodes.contains("HKUMB");
				else if(jobName.equals("DauerNew")) supp = gvcodes.contains("HKDAE");
				else if(jobName.equals("DauerEdit")) supp = gvcodes.contains("HKDAN");
				else if(jobName.equals("DauerDel")) supp = gvcodes.contains("HKDAL");
			} else supp = handler.isSupported(jobName);
		}
		
		xmlBuf.append("<result command=\"isSupported\">");
		booleTag("isSupported", supp);
		xmlBuf.append("</result>.");
		out.write(xmlBuf.toString());
		out.flush();
	}
	
	private static void updateBankData() throws IOException {
		String bankCode = getParameter(map, "bankCode");
		String userId = getParameter(map, "userId");
		
		HBCIHandler handler = hbciHandler(bankCode, userId);
		
		HBCIDialogStatus status = handler.refreshXPD(HBCIHandler.REFRESH_BPD | HBCIHandler.REFRESH_UPD); 
		HBCIPassportPinTan passport = (HBCIPassportPinTan)handler.getPassport();
	   
		xmlBuf.append("<result command=\"updateBankData\">");
		if(status.isOK() == false) {
			error(ERR_GENERIC, "updateBankData", status.getErrorString());
			return;
		}
		passportToXml(passport);
		xmlBuf.append("</result>.");
		out.write(xmlBuf.toString());
		out.flush();
	}
	
	private static void error(int code, String command, String msg) throws IOException {
		xmlBuf = new StringBuffer();
		xmlBuf.append("<result command=\""+command+"\">");
		xmlBuf.append("<error code=\""+Integer.toString(code)+"\">");
		tag("msg", msg);
		xmlBuf.append("</error>");
		xmlBuf.append("</result>.");
		out.write(xmlBuf.toString());
		out.flush();
	}
	
	private static void resetPinTanMethod() throws IOException {
		String bankCode = getParameter(map, "bankCode");
		String userId = getParameter(map, "userId");
		
		HBCIHandler handler = hbciHandler(bankCode, userId);
		HBCIPassportPinTan passport = (HBCIPassportPinTan)handler.getPassport();
		passport.resetSecMechs();
		passport.getCurrentTANMethod(true);
		User user = (User)users.get(passportKey(bankCode, userId));
		if(user == null) {
			error(ERR_MISS_USER, "resetPinTanMethod", userId);
			return;
		}
		user.updatePinTanMethod(passport);
		user.save();
		xmlBuf.append("<result command=\"resetPinTanMethod\">");
		passportToXml(passport);
		xmlBuf.append("</result>.");
		out.write(xmlBuf.toString());
		out.flush();
	}
	
	private static void setLogLevel() throws IOException {
		String level = getParameter(map, "logLevel");
		Integer logLevel = Integer.valueOf(level);
		logLevel += 1;
		if(logLevel > 5) logLevel = 5;
        HBCIUtils.setParam("log.loglevel.default", logLevel.toString());
        out.write("<result command=\"setLogLevel\"></result>.");
        out.flush();
	}
	
	private static void getAccInfo() throws IOException {
		String bankCode = getParameter(map, "bankCode");
		String userId = getParameter(map, "userId");
		String accountNumber = getParameter(map, "accountNumber");	
		
		HBCIHandler handler = hbciHandler(bankCode, userId);
		if(handler == null) {
			error(ERR_MISS_USER, "getAccInfo", userId);
			return;			
		}
		HBCIPassportPinTan passport = (HBCIPassportPinTan)handler.getPassport();
		
		Konto account = (Konto)accounts.get(bankCode+accountNumber);
		if(account == null) {
			account = handler.getPassport().getAccount(accountNumber);
			if(account == null) {
				error(ERR_MISS_ACCOUNT, "getAccInfo",accountNumber);
				return;
			}
		}
		
		HBCIJob job = handler.newJob("AccInfo");
		job.setParam("my", account);
		job.setParam("all", "J");
		job.addToQueue();
		HBCIExecStatus stat = handler.execute();

		boolean isOk = false;
		GVRAccInfo res = null;
		if(stat.isOK()) {
			res = (GVRAccInfo)job.getJobResult();
			if(res.isOK()) isOk = true;
		}
		System.out.println(res.toString());

	}
	
	
	private static void dispatch(String command) throws IOException {

//		Method cmd = HBCIServer.class.getMethod(command, new Class[0]);
		xmlBuf = new StringBuffer();
		try {
			if(command.compareTo("addUser") ==0 ) { addPassport(); return; }
			if(command.compareTo("init") == 0) { init(); return; }
			if(command.compareTo("getAllStatements") == 0) { getAllStatements(); return; }
			if(command.compareTo("getAccounts") == 0) { getAccounts(); return; }
			if(command.compareTo("getBankInfo") == 0) { getBankInfo(); return; }
			if(command.compareTo("checkAccount") == 0) { checkAccount(); return; }
			if(command.compareTo("deletePassport") == 0) { deletePassport(); return; }
			if(command.compareTo("setAccount") == 0) { setAccount(); return; }
			if(command.compareTo("sendTransfers") == 0) { sendTransfers(); return; }
			if(command.compareTo("getJobRestrictions") == 0) { getJobRestrictions(); return; }
			if(command.compareTo("isJobSupported") == 0) { isJobSupported(); return; }
			if(command.compareTo("updateBankData") == 0) { updateBankData(); return; }
			if(command.compareTo("resetPinTanMethod") == 0) { resetPinTanMethod(); return; }
			if(command.compareTo("changeAccount") == 0) { changeAccount(); return; }
			if(command.compareTo("addStandingOrder") == 0) { addStandingOrder(); return; }
			if(command.compareTo("changeStandingOrder") == 0) { changeStandingOrder(); return; }
			if(command.compareTo("deleteStandingOrder") == 0) { deleteStandingOrder(); return; }
			if(command.compareTo("getAllStandingOrders") == 0) { getAllStandingOrders(); return; }
			if(command.compareTo("getBankParameter") == 0) { getBankParameter(); return; }
			if(command.compareTo("setLogLevel") == 0) { setLogLevel(); return; }
			if(command.compareTo("getAccInfo") == 0) { getAccInfo(); return; }
			
			System.err.println("HBCIServer: unknown command");
		}
		catch(HBCI_Exception e) {
		    Throwable e2=e;
		    String msg=null;
		    while (e2!=null) {
		        if ((msg=e2.getMessage())!=null) {
		        	System.err.println(msg);
		        	log(msg,1,new Date());
		        }
		        if(e2 instanceof InvalidPassphraseException) {
		        	error(ERR_WRONG_PASSWD, command, "Ungültiges Passwort");
		        	return; }
		        if(e2 instanceof AbortedException) {
		        	error(ERR_ABORTED, command, "Abbruch durch Benutzer");
		        	return;
		        }
		        e2=e2.getCause();
		    }
		    error(ERR_GENERIC, command, msg);
		    e.printStackTrace();
			return;
		}
		catch(HBCIParamException e) {
			error(ERR_MISS_PARAM,command, e.parameter());
			return;
			
		}
		catch (Exception e) {
		    error(ERR_GENERIC, command, e.getMessage());
			e.printStackTrace();
			return;
		}
	}

/*	
 <command name="addUser"> 
 	<bankCode>76010085</bankCode>
 	<userId>718610851</userId>
 	<customerId></customerId>
 	<host>hbci.postbank.de/banking/hbci.do</host>
 	<port>443</port>
 	<version>plus</version>
 	<filter>Base64</filter>
 </command>.
 
 <command name="addUser">
    <name>HBCI4Java</name>
 	<bankCode>80007777</bankCode>
 	<userId>femminghaus</userId>
 	<customerId></customerId>
 	<host>www.hora-obscura.de/pintan/PinTanServlet</host>
 	<port>443</port>
 	<version>plus</version>
 	<filter>Base64</filter>
 </command>.
 
 <command name="resetPinTanProcess">
 	<bankCode>76010085</bankCode>
 	<userId>718610851</userId>
 	<customerId>718610851</customerId>
</command>.   
 
<command name="updateBankData">
 	<bankCode>76010085</bankCode>
 	<userId>718610851</userId>
 	<customerId>718610851</customerId>
</command>.   

 
 <command name="init">
 	<path>/users/emmi/Library/Application Support/Pecunia/Passports</path>
 </command>.
 
 <command name="checkAccount">
 	<bankCode>BLZ</bankCode>
 	<accountNumber>xxx</accountNumber>
 </command>.
 
 <command name="getJobRestrictions">
 	<bankCode>BLZ</bankCode>
 	<userId>xxx</userId>
 	<jobName>UebForeign</jobName>
 </command>.

 <command name="checkAccount">
 	<iban>(null)</iban>
 </command>.
 
 <command name="getAccounts">
 	<bankCode>*</bankCode>
 </command>. 	
 
 <command name="getBankInfo">
 	<bankCode>76010085</bankCode>
 </command>.
 
 <command name="getBankParameter">
	<bankCode>60090800</bankCode>
	<userId>3551722</userId>
 </command>.

 <command name="getAllStatements">
 	<accinfolist type="list">
 		<accinfo>
 			<bankCode>76010085</bankCode>
 			<accountNumber>718610851</accountNumber>
 			<userId>718610851</userId>
 			<fromDate>2011-08-01</fromDate>
 		</accinfo>
 	</accinfolist>
 </command>.
 
 <command name="sendTransfers">
 	<transfers type="list">
 		<transfer>
 			<type>standard</type>
 			<bankCode>80007777</bankCode>
 			<userId>femminghaus</userId>
 			<accountNumber>2806090740</accountNumber>
 			<customerId>femminghaus</customerId>
 			<remoteAccount>2806090741</remoteAccount>
 			<remoteBankCode>80007777</remoteBankCode>
 			<remoteName>Frank Emminghaus</remoteName>
 			<remoteCountry>DE</remoteCountry>
 			<purpose1>Test</purpose1>
 			<currency>EUR</currency>
 			<value>1000</value>
 			<transferId>1</transferId>
 		</transfer>
 	</transfers>
 </command>.

 <command name="isJobSupported">
	<bankCode>60090800</bankCode>
 	<userId>3551722</userId>
 	<accountNumber>3551722</accountNumber>
 	<jobName>DauerNew</jobName>
 </command>.

 <command name="setAccount">
 	<bankCode>60090800</bankCode>
 	<accountNumber>3551722</accountNumber>
 	<customerId>3551722</customerId>
 	<ownerName>Frank Emminghaus</ownerName>
 	<name>Girokonto</name>
 </command>.
  
 <command name="getAccInfo">
 	<bankCode>67292200</bankCode>
 	<accountNumber>36917300</accountNumber>
 	<userId>206844341</userId>
 </command>.
	
*/	
	private static void acceptArray(XmlPullParser xpp, Properties map, String tag) throws XmlPullParserException, IOException {
		int eventType;
		ArrayList list = new ArrayList();
		
		eventType = xpp.next();
		while(eventType != XmlPullParser.END_TAG) {
			if(eventType == XmlPullParser.START_TAG) {
				Properties tmap = new Properties();
				acceptTag(xpp, tmap, null);
				list.add(tmap);
			}
			eventType = xpp.next();
		}
		map.put(tag, list);
	}
	
	
	private static void acceptTag(XmlPullParser xpp, Properties map, String tag) throws XmlPullParserException, IOException {
		int eventType;
		String currTag = null;
		
		String name = xpp.getName();
		String type = xpp.getAttributeValue(null, "type");
		if(type != null && type.equals("list")) acceptArray(xpp, map, name);
		else {
			if(tag != null)	currTag = tag+"."+name; else currTag = name;
			eventType = xpp.next();
			while(eventType != XmlPullParser.END_TAG) {
				if(eventType == XmlPullParser.START_TAG) {
					acceptTag(xpp, map, currTag);
				} else if(eventType == XmlPullParser.TEXT) {
	                if(!xpp.isWhitespace()) {
	               	 if(currTag != null) map.put(currTag, xpp.getText());
	                }
				}
				eventType = xpp.next();
			}
		}
	}
	
	
	public static void main(String[] args) {
		// TODO Auto-generated method stub
			String command = null;
			map = new Properties();
			countryInfos = new Properties();
			hbciHandlers = new Properties();
			accounts = new Properties();
			users = new Properties();
			XmlPullParserFactory factory;
			System.err.println("HBCI Server up and running...");
		
			try {
				String s;
				String cmd = "";
				
				factory = XmlPullParserFactory.newInstance();
	            factory.setNamespaceAware(true);
	            XmlPullParser xpp = factory.newPullParser();
				in = new BufferedReader(new InputStreamReader(System.in, "UTF-8"));
				out = new BufferedWriter(new OutputStreamWriter(System.out, "UTF-8"));
  
				while ((s = in.readLine()) != null && s.length() != 0) {
//					cmd += s;
					if(s.endsWith(".")) {
						s = s.substring(0, s.length()-1);
						cmd += s;
						xpp.setInput(new StringReader(cmd));
						cmd = "";

			            int eventType = xpp.getEventType();
			            while (eventType != XmlPullParser.END_DOCUMENT) {
			             if(eventType == XmlPullParser.START_DOCUMENT) {
			             } else if(eventType == XmlPullParser.END_DOCUMENT) {
			             } else if(eventType == XmlPullParser.START_TAG) {
			            	 String tag = xpp.getName();
			            	 if(tag.compareTo("command") == 0) {
			            		 command = xpp.getAttributeValue(null, "name");
			            		 map.clear();
			            	 } else acceptTag(xpp, map, null);
			             } else if(eventType == XmlPullParser.END_TAG) {
			            	 String tag = xpp.getName();
			            	 if(tag.compareTo("command") == 0) {
			            		 dispatch(command);
			            	 }
			             } else if(eventType == XmlPullParser.TEXT) {
			             }
			             eventType = xpp.next();
			            }
					
					} else cmd += s;
				 }
 			} catch (XmlPullParserException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
	}
}
