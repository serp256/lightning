package ru.redspell.lightning.payments;

public interface ILightPayments {	
	void init(String[] skus);
	void purchase(String sku);
	void comsumePurchase(String purchaseToken);
	void restorePurchases();
}