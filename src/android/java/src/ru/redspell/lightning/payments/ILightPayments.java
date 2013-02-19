package ru.redspell.lightning.payments;

public interface ILightPayments {	
	void init();
	void purchase(String sku);
	void comsumePurchase(String purchaseToken);
	void restorePurchases();
}