public with sharing class tmException extends Exception { 

	public List<String> errors {
		get {
			if (errors == null) {
				errors = new List<String>();
			}
			return errors;
		}
		set;
	}

	public string errorString{
		get {
			return String.join(errors,',');
		}
		private set;
	}
}