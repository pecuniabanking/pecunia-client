

public class HBCIParamException extends RuntimeException {

	private static final long serialVersionUID = 1L;
	private String parameter;
	HBCIParamException(String param) {
		parameter = param;
	}
	
	String parameter() {
		return parameter;
	}
}
