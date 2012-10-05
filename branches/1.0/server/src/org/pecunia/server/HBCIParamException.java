package org.pecunia.server;

public class HBCIParamException extends RuntimeException {
	
	private String parameter;
	HBCIParamException(String param) {
		parameter = param;
	}
	
	String parameter() {
		return parameter;
	}
}
