class dBanker
{

}

/**
 * Pays back loan if possible, but tries to have at least the loan interval (10,000 pounds)
 * @return True if the action succeeded.
 */
function dBanker::PayLoan()
{
	local balance = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
	// overflow protection by krinn
	if (balance + 1 < balance) {
		if (AICompany.SetMinimumLoanAmount(0)) return true;
		else return false;
	}
	local money = 0 - (balance - AICompany.GetLoanAmount()) + 100000; // + dBanker.GetMinimumCashNeeded();
	if (money > 0) {
		if (AICompany.SetMinimumLoanAmount(money)) return true;
		else return false;
	} else {
		if (AICompany.SetMinimumLoanAmount(0)) return true;
		else return false;
	}
}